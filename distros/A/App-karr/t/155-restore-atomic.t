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
use Try::Tiny;

use App::karr::Encoding qw( yaml_dump yaml_load );
use App::karr::Git;

# Ticket #155: `karr restore` (replace_board_refs) validates every ref and
# builds every commit in phase one, then writes the refs in place in phase
# two. Before the fix, a ref write that failed in phase two (a lock
# contention exhaustion that survived retry_contended, a real libgit2 error,
# anything that produced a die out of _write_ref_oid) left the board with
# the first N-1 snapshot refs and the last one still pointing at its
# pre-restore content -- the catastrophic half-apply the test below
# reproduces. The fix snapshots the original refs/karr/* state before phase
# two and restores it on any failure, so the board ends up exactly as it
# was before the failed restore rather than as a mixture.

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

sub _board {
    my $root = tempdir( CLEANUP => 1 );
    my $work = "$root/work";

    _git_ok( 'git', 'init', '-q', $work );
    _git_ok( 'git', '-C', $work, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $work, 'config', 'user.name',  'Test User' );

    is( _run_karr( $work, 'init', '--name', 'Atomic Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $work, 'create', "task $_" )->{exit}, 0, "task $_ created" ) for 1 .. 3;

    return ( $root, $work );
}

sub _snapshot_of {
    my ( $work, $root ) = @_;
    my $file = "$root/good.yml";
    is( _run_karr( $work, 'backup', '--output', $file )->{exit}, 0, 'backup written' );
    return ( $file, yaml_load( path($file)->slurp_utf8 ) );
}

subtest 'a write failure in phase two leaves the board untouched' => sub {
    my ( $root, $work ) = _board();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    # Mutate the snapshot so its contents differ from the live board on
    # EVERY ref. Without this change a "the refs read back the same"
    # assertion would still pass on the pre-fix code, because the snapshot
    # and the live board would be identical and the half-applied state
    # would be indistinguishable from the original state. The phase-two
    # write order is sorted, so the very first ref to land is
    # refs/karr/config -- the snapshot's config has a different `name`,
    # so the half-applied state would leave the live board with the
    # snapshot's config and the live board's tasks, which is the bug.
    $snapshot->{refs}{'refs/karr/config'} =~ s/name: \K.*/From Snapshot/m;
    for my $id ( 1 .. 3 ) {
        my $key = "refs/karr/tasks/$id/data";
        my $fm  = $snapshot->{refs}{$key};
        $fm =~ s/^title: .*$/title: "snapshot-of-task-$id"/m;
        $snapshot->{refs}{$key} = $fm;
    }
    my $mutated = "$root/mutated.yml";
    path($mutated)->spew_utf8( yaml_dump($snapshot) );

    my @before = _local_karr_refs($work);
    ok( scalar @before, 'the board has refs before the restore' );

    # Snapshot the content of every board ref so the test can compare
    # contents, not just ref names. The ref-set is the same before and
    # after a half-applied phase two; the bug is in what each ref points
    # at, which is exactly what a "compare the names" assertion misses.
    my $git = App::karr::Git->new( dir => $work );
    my %before_content = map { $_ => $git->read_ref($_) } sort keys %{ $snapshot->{refs} };

    # Phase two writes the refs in sorted order. Inject a failure on the
    # second write so ref 1 lands at the snapshot value, ref 2 fails, and
    # everything past it stays at the pre-restore value. The pre-fix
    # `replace_board_refs` returned 1 because the die happened after some
    # writes had already landed, so the half-applied state was the success
    # path, not the error path.
    my $fail_at = 2;
    my $calls   = 0;
    no warnings 'redefine';
    local *App::karr::Git::_write_ref_oid = sub {
        my ( $self, $ref, $oid ) = @_;
        $calls++;
        die "karr: could not write $ref: injected failure for ticket #155\n"
            if $calls == $fail_at;
        return $self->retry_contended( "ref $ref", sub {
            my $repo = $self->_repo;
            $repo->reference_create( $ref, $oid, force => 1 );
            $App::karr::Git::WRITES++;
            1;
        } );
    };

    my $err = try {
        $git->replace_board_refs( $snapshot->{refs} );
        undef;
    } catch {
        my $msg = "$_";
        chomp $msg;
        return $msg;
    };
    isnt( $err, undef, 'replace_board_refs dies on phase-two failure' );
    like( $err, qr/injected failure for ticket #155/,
        '...and the die is the one we injected, not a half-applied-success' );

    is_deeply( [ _local_karr_refs($work) ], \@before,
        'the board has the same refs as before the failed restore' );

    # The actual proof the bug is fixed: every ref reads back at its
    # original content. A pre-fix code path would have ref 1 carrying the
    # snapshot value and the rest still at the live value, which is the
    # half-applied state the ticket is named after.
    my %after_content = map { $_ => $git->read_ref($_) } sort keys %{ $snapshot->{refs} };
    my $contents_ok = is_deeply( \%after_content, \%before_content,
        'every ref reads back at its pre-restore content -- no half-applied snapshot' );
    if ( !$contents_ok ) {
        diag join "\n", map {
            "  $_: before=["
                . substr( ( $before_content{$_} // '' ), 0, 40 )
                . "] after=["
                . substr( ( $after_content{$_} // '' ), 0, 40 ) . "]"
        } sort keys %before_content;
    }

    # The user-facing surface for the same bug: karr list reads through the
    # same path. Pre-fix the half-applied state would surface a snapshot
    # title for the ref that landed, which is the data corruption that
    # makes a disaster recovery tool worse than the disaster.
    my $list = _run_karr( $work, 'list' );
    is( $list->{exit}, 0, 'the board still reads' );
    unlike( $list->{stdout}, qr/snapshot-of-task-/,
        'no task on the board carries the snapshot title'
    ) or diag "list output:\n$list->{stdout}";
    unlike( $list->{stdout}, qr/From Snapshot/,
        'and the board name is the live one, not the snapshot name'
    ) or diag "list output:\n$list->{stdout}";

    # A second restore with the same snapshot, with the failure removed,
    # has to succeed -- the failed restore must not leave the board in a
    # state the next restore cannot recover from.
    is( _run_karr( $work, 'restore', '--yes', '--input', $mutated )->{exit}, 0,
        'a clean restore after the failed one succeeds'
    ) or diag _run_karr( $work, 'restore', '--yes', '--input', $mutated );
};

subtest 'a write failure on the first ref also leaves the board untouched' => sub {
    # Edge case: the very first write fails. Pre-fix, the first write could
    # not have failed because the namespace was empty, so this case had no
    # precedent; the fix has to handle it too, just because the failure
    # point is "wherever libgit2 decides to fail".
    my ( $root, $work ) = _board();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    my @before = _local_karr_refs($work);

    my $git = App::karr::Git->new( dir => $work );
    no warnings 'redefine';
    local *App::karr::Git::_write_ref_oid = sub {
        die "karr: could not write: injected first-write failure for ticket #155\n";
    };

    my $err = try {
        $git->replace_board_refs( $snapshot->{refs} );
        undef;
    } catch {
        my $msg = "$_";
        chomp $msg;
        return $msg;
    };
    isnt( $err, undef, 'replace_board_refs dies on the first write' );

    is_deeply( [ _local_karr_refs($work) ], \@before,
        'the board is exactly as it was, even when nothing landed yet' );
};

subtest 'a write failure on the last ref also leaves the board untouched' => sub {
    # The other edge: the last write fails. Pre-fix this was the case where
    # the most damage was done, because every prior ref had already been
    # moved to the snapshot value while the last one still pointed at the
    # live board.
    my ( $root, $work ) = _board();
    my ( $file, $snapshot ) = _snapshot_of( $work, $root );

    my @before = _local_karr_refs($work);

    my $git       = App::karr::Git->new( dir => $work );
    my @wanted    = sort keys %{ $snapshot->{refs} };
    my $last_wref = $wanted[-1];
    no warnings 'redefine';
    local *App::karr::Git::_write_ref_oid = sub {
        my ( $self, $ref, $oid ) = @_;
        die "karr: could not write $ref: injected last-write failure for ticket #155\n"
            if $ref eq $last_wref;
        return $self->retry_contended( "ref $ref", sub {
            my $repo = $self->_repo;
            $repo->reference_create( $ref, $oid, force => 1 );
            $App::karr::Git::WRITES++;
            1;
        } );
    };

    my $err = try {
        $git->replace_board_refs( $snapshot->{refs} );
        undef;
    } catch {
        my $msg = "$_";
        chomp $msg;
        return $msg;
    };
    isnt( $err, undef, 'replace_board_refs dies on the last write' );

    is_deeply( [ _local_karr_refs($work) ], \@before,
        'the board is exactly as it was even when only the last write failed' );
};

done_testing;
