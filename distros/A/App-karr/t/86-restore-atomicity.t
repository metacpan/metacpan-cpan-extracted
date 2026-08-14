use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Encoding qw( yaml_dump yaml_load );

# Ticket #47: `karr restore` deleted refs/karr/* first and wrote the snapshot
# back afterwards, so a snapshot karr could not write destroyed the board on the
# way through -- locally, and then on the remote too, because the push insurance
# faithfully mirrored the half-executed destruction. The disaster-recovery tool
# was the thing that caused the disaster.
#
# Every subtest here therefore asserts the state of the board *after a failed
# restore*, on both sides, and reads a task back rather than only counting refs.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( undef, my $stdout_fh, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _refs {
    my (@cmd) = @_;
    open my $fh, '-|', @cmd or die "cannot run @cmd: $!";
    my @refs = <$fh>;
    close $fh;
    chomp @refs;
    return sort @refs;
}

sub _local_karr_refs {
    my ($work) = @_;
    return _refs( 'git', '-C', $work, 'for-each-ref', '--format=%(refname)', 'refs/karr/' );
}

sub _origin_karr_refs {
    my ($origin) = @_;
    return _refs( 'git', "--git-dir=$origin", 'for-each-ref', '--format=%(refname)', 'refs/karr/' );
}

# A working clone with a bare origin, a board, and three tasks -- pushed, so the
# remote side of the destruction is observable.
sub _board_with_origin {
    my $root   = tempdir( CLEANUP => 1 );
    my $origin = "$root/origin.git";
    my $work   = "$root/work";

    _git_ok( 'git', 'init', '-q', '--bare', $origin );
    _git_ok( 'git', 'init', '-q', $work );
    _git_ok( 'git', '-C', $work, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $work, 'config', 'user.name',  'Test User' );
    _git_ok( 'git', '-C', $work, 'remote', 'add', 'origin', $origin );

    is( _run_karr( $work, 'init', '--name', 'Restore Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $work, 'create', "task $_" )->{exit}, 0, "task $_ created" ) for 1 .. 3;

    return ( $root, $work, $origin );
}

sub _snapshot_of {
    my ( $work, $root ) = @_;
    my $file = "$root/good.yml";
    is( _run_karr( $work, 'backup', '--output', $file )->{exit}, 0, 'backup written' );
    return ( $file, yaml_load( path($file)->slurp_utf8 ) );
}

subtest 'a ref name karr cannot write leaves the board untouched, here and on the remote' => sub {
    my ( $root, $work, $origin ) = _board_with_origin();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    my @before_local  = _local_karr_refs($work);
    my @before_origin = _origin_karr_refs($origin);
    ok( scalar(@before_local),  'board has refs before the restore' );
    is_deeply( \@before_origin, \@before_local, 'and the remote is in step with it' );

    # Sorts before refs/karr/config, so pre-fix it was the very first write
    # attempted after the namespace had already been deleted.
    $snapshot->{refs}{'refs/karr/bad name'} = "x\n";
    my $bad = "$root/bad.yml";
    path($bad)->spew_utf8( yaml_dump($snapshot) );

    my $rv = _run_karr( $work, 'restore', '--yes', '--input', $bad );
    isnt( $rv->{exit}, 0, 'restore refuses the snapshot' );
    like( $rv->{stderr}, qr{\Qrefs/karr/bad name\E}, 'and names the ref it cannot write' );

    is_deeply( [ _local_karr_refs($work) ], \@before_local,
        'the local board is exactly as it was' );
    is_deeply( [ _origin_karr_refs($origin) ], \@before_origin,
        'and so is the remote -- no half-executed destruction was pushed' );

    my $list = _run_karr( $work, 'list' );
    is( $list->{exit}, 0, 'the board still reads' );
    like( $list->{stdout}, qr/task 1/, 'task 1 survived' );
    like( $list->{stdout}, qr/task 3/, 'task 3 survived' );
};

subtest 'a snapshot cannot reach outside refs/karr/' => sub {
    my ( $root, $work, $origin ) = _board_with_origin();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    my $head = `git -C $work rev-parse HEAD 2>/dev/null`;

    $snapshot->{refs}{'refs/heads/smuggled'} = "payload\n";
    my $bad = "$root/outside.yml";
    path($bad)->spew_utf8( yaml_dump($snapshot) );

    my @before = _local_karr_refs($work);
    my $rv = _run_karr( $work, 'restore', '--yes', '--input', $bad );
    isnt( $rv->{exit}, 0, 'restore refuses a ref outside the board namespace' );
    like( $rv->{stderr}, qr/outside the board namespace/, 'and says why' );

    is_deeply( [ _local_karr_refs($work) ], \@before, 'the board is untouched' );
    is_deeply(
        [ _refs( 'git', '-C', $work, 'for-each-ref', '--format=%(refname)', 'refs/heads/smuggled' ) ],
        [], 'and no branch was created from the snapshot' );
};

subtest 'a snapshot karr can write still replaces the board exactly' => sub {
    my ( $root, $work, $origin ) = _board_with_origin();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    # A fourth task exists only in the live board, so the restore has to remove
    # it: restore is destructive on purpose and must stay that way.
    is( _run_karr( $work, 'create', 'task 4' )->{exit}, 0, 'a fourth task is added after the backup' );
    like( _run_karr( $work, 'list' )->{stdout}, qr/task 4/, 'and shows up on the board' );

    my $rv = _run_karr( $work, 'restore', '--yes', '--input', $file );
    is( $rv->{exit}, 0, 'restore succeeds' ) or diag $rv->{stderr};

    is_deeply( [ _local_karr_refs($work) ], [ sort keys %{ $snapshot->{refs} } ],
        'the board holds exactly the refs the snapshot carried' );

    my $list = _run_karr( $work, 'list' );
    like( $list->{stdout}, qr/task 1/, 'the snapshot tasks are back' );
    unlike( $list->{stdout}, qr/task 4/, 'and the task the snapshot did not have is gone' );

    is_deeply( [ _origin_karr_refs($origin) ], [ sort keys %{ $snapshot->{refs} } ],
        'the remote followed the successful restore' );
};

done_testing;
