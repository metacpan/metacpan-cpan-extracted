use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use YAML::XS qw( Load );

use App::karr::Git;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        my $stdin_fh,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    if ( defined $stdin ) {
        print {$stdin_fh} $stdin;
    }
    close $stdin_fh;

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

subtest 'backup exports refs/karr snapshot as YAML' => sub {
    my $repo = _init_repo();
    is( _run_karr( $repo, undef, 'init', '--name', 'Backup Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, undef, 'create', 'First task' )->{exit}, 0, 'task created' );

    my $rv = _run_karr( $repo, undef, 'backup' );
    is( $rv->{exit}, 0, 'backup exits successfully' );

    my $snapshot = Load( $rv->{stdout} );
    is( $snapshot->{version}, 1, 'snapshot version recorded' );
    ok( exists $snapshot->{refs}{'refs/karr/config'}, 'config ref included in snapshot' );
    ok( exists $snapshot->{refs}{'refs/karr/meta/next-id'}, 'next-id ref included in snapshot' );
    ok( exists $snapshot->{refs}{'refs/karr/tasks/1/data'}, 'task ref included in snapshot' );
};

subtest 'restore requires --yes and replaces current refs/karr state' => sub {
    my $repo = _init_repo();
    is( _run_karr( $repo, undef, 'init', '--name', 'Restore Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, undef, 'create', 'First task' )->{exit}, 0, 'first task created' );

    my $backup = _run_karr( $repo, undef, 'backup' );
    is( $backup->{exit}, 0, 'backup succeeds' );

    is( _run_karr( $repo, undef, 'create', 'Second task' )->{exit}, 0, 'second task created after backup' );
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/log/transient', qq({"action":"temp"}) );

    my $without_yes = _run_karr( $repo, $backup->{stdout}, 'restore' );
    isnt( $without_yes->{exit}, 0, 'restore without --yes fails' );
    like( $without_yes->{stderr}, qr/destructive/i, 'stderr warns about destructive restore' );

    my $with_yes = _run_karr( $repo, $backup->{stdout}, 'restore', '--yes' );
    is( $with_yes->{exit}, 0, 'restore with --yes succeeds' );
    like( $with_yes->{stderr}, qr/Restored refs\/karr/i, 'restore reports success on stderr' );

    is_deeply( [ $git->list_task_refs ], [1], 'task refs are replaced by snapshot contents' );
    ok( !$git->ref_exists('refs/karr/log/transient'), 'refs absent from snapshot are removed' );
    is( $git->read_next_id_ref, 2, 'next-id metadata is restored from the snapshot' );
};

done_testing;
