use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );

use App::karr::Git;
use App::karr::Lock;

# Ticket #51: delete_ref swallowed the exception, always returned 1, and bumped
# $App::karr::Git::WRITES either way -- so a delete that removed nothing looked
# exactly like one that worked, and it told SyncGuard there were local refs
# waiting to be pushed when there were none.

sub _repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or die "git config failed";
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die "git config failed";
    return App::karr::Git->new( dir => $repo );
}

# The write counter is what SyncGuard consults, so every assertion below reads
# it as a delta around one call.
sub _writes_during {
    my ($code) = @_;
    my $before = App::karr::Git->pending_writes;
    my $rv     = $code->();
    return ( $rv, App::karr::Git->pending_writes - $before );
}

subtest 'a delete that removed nothing reports nothing' => sub {
    my $git = _repo();

    my ( $rv, $delta ) =
        _writes_during( sub { $git->delete_ref('refs/karr/tasks/999/data') } );
    ok( !$rv, 'deleting a ref that is not there is not a success' );
    is( $delta, 0, 'and is not counted as a write' );

    ( $rv, $delta ) = _writes_during( sub { $git->delete_ref('refs/karr/bad name') } );
    ok( !$rv, 'deleting an unusable ref name is not a success' );
    is( $delta, 0, 'and is not counted as a write either' );
};

subtest 'a delete that removed something still reports it' => sub {
    my $git = _repo();
    ok( $git->write_ref( 'refs/karr/tasks/1/data', "hello\n" ), 'a ref is written' );
    ok( $git->ref_exists('refs/karr/tasks/1/data'), 'and is there' );

    my ( $rv, $delta ) =
        _writes_during( sub { $git->delete_ref('refs/karr/tasks/1/data') } );
    ok( $rv, 'deleting it succeeds' );
    is( $delta, 1, 'and counts as exactly one write' );
    ok( !$git->ref_exists('refs/karr/tasks/1/data'), 'the ref is gone' );

    # A second attempt has nothing left to do and must say so.
    ( $rv, $delta ) = _writes_during( sub { $git->delete_ref('refs/karr/tasks/1/data') } );
    ok( !$rv,      'deleting it again reports nothing done' );
    is( $delta, 0, 'and adds nothing to the write count' );
};

subtest 'releasing a lock nobody holds is not a write' => sub {
    # The concrete path the ticket calls out: SyncGuard would have seen unpushed
    # work after a command whose only ref operation was a no-op lock release.
    my $git  = _repo();
    my $lock = App::karr::Lock->new( git => $git, task_id => 7 );

    my ( $rv, $delta ) =
        _writes_during( sub { [ $lock->release( 7, 'nobody@example.com' ) ] } );
    is( $rv->[0], 1, 'release still answers that the lock is not held' );
    is( $delta,   0, 'but releasing nothing does not count as a write' );
};

subtest 'delete_refs refuses to report a namespace it did not clear' => sub {
    my $git = _repo();
    $git->write_ref( "refs/karr/tasks/$_/data", "task $_\n" ) for 1 .. 3;
    $git->write_ref( 'refs/karr/config', "version: 1\n" );

    ok( $git->delete_refs('refs/karr/'), 'clearing the namespace succeeds' );
    is_deeply( [ $git->list_refs('refs/karr/') ], [], 'and really cleared it' );

    # Nothing there at all is a cleared namespace too, not a failure.
    ok( $git->delete_refs('refs/karr/'), 'clearing an already empty namespace succeeds' );
};

done_testing;
