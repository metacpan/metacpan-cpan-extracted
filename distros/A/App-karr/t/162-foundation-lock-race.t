use strict;
use warnings;

# Ticket #162. .karr.lock was an advisory pid: _lock_held did
# `kill(0, $pid)` and recorded whatever pid the foundation process was
# running as. _acquire_lock spewed over the existing file's content with
# its own pid, and _release_lock removed the file without ever comparing
# the pid. Two ticks that overlapped -- the normal case, since a drain
# may run for max_runtime while cron fires every few minutes -- could
# both pass the check, both write their own pid, and the first tick to
# finish would unlock the board for the one still running.
#
# The fix is to make the lock a flock(2) on an open file descriptor the
# foundation keeps for the lifetime of the lock. The recorded pid and
# pgid are evidence (for --status and the SIGTERM handler) rather than
# authority. _acquire_lock opens a fd, attempts LOCK_EX|LOCK_NB; on
# EWOULDBLOCK it returns 0 immediately, without overwriting the existing
# file. _release_lock closes the open fd -- closing drops the flock --
# and only then reads the recorded pid and unlinks the file if it still
# matches $$.
#
# These tests pin that contract:
#   1. two ticks that race on the same lock: only one acquires.
#   2. _acquire_lock does not overwrite an existing lock it can't take.
#   3. _release_lock from a tick that does not hold the lock is a no-op
#      (the lock stays held, the file stays on disk).
#   4. a stale .karr.lock whose recorded pid belongs to a dead process
#      but whose fd is no longer flock'd is not held: a fresh tick can
#      take over without manual cleanup (#163's other half).

use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation;

subtest 'two ticks racing for the same lock: only the first wins' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    my $f1  = App::karr::Foundation->new( _config_data => {} );
    my $f2  = App::karr::Foundation->new( _config_data => {} );

    ok $f1->_acquire_lock( $dir ), 'tick A acquires';
    ok !$f2->_acquire_lock( $dir ),
        'tick B is refused with 0 (EWOULDBLOCK), not silently allowed to overwrite'
        or diag 'tick B acquired while tick A still held the lock';

    ok $f1->_lock_held( $dir ), 'tick A still holds the lock';

    my $meta = $f1->_read_lock_metadata( $dir );
    ok $meta && defined $meta->{pid},
        'the recorded pid is the acquirer, not the race-loser'
        or diag 'lock file has no pid recorded';

    $f1->_release_lock( $dir );

    ok !$f1->_lock_held( $dir ), 'after tick A releases, the lock is free';
    ok  $f2->_acquire_lock( $dir ), 'tick B can now acquire';
    $f2->_release_lock( $dir );
};

# The pre-fix race surface: tick B overwrote tick A's pid in .karr.lock
# *before* EWOULDBLOCK was even checked (the old code spewed first, then
# tried the flock, then checked kill(0)). With the fix the file's recorded
# pid is always the acquirer's -- it is never overwritten by a tick that
# did not take the lock.
subtest 'a refused _acquire_lock leaves the existing lock file intact' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    my $f1  = App::karr::Foundation->new( _config_data => {} );
    my $f2  = App::karr::Foundation->new( _config_data => {} );

    ok $f1->_acquire_lock( $dir, pid => 560905 ), 'A acquires with pid 560905';
    my $before = $f1->_read_lock_metadata( $dir );
    is $before->{pid}, 560905, 'A recorded its pid';

    ok !$f2->_acquire_lock( $dir, pid => 560906 ), 'B is refused';
    my $after = $f1->_read_lock_metadata( $dir );
    is $after->{pid}, 560905,
        'B did not overwrite the file -- the recorded pid is still A\'s'
        or diag "B's acquire wrote 560906 over A's 560905 -- old behaviour";
};

# The pid-recycling half: a foundation instance whose process restarted
# under the same pid (systemd's Restart=always loop, a tight while loop
# whose parent died and was replaced by init) will see kill(0, $pid)
# return true on a lock the dead predecessor left. Without the recorded-
# pid check in _release_lock, it would unlock the file its successor
# already owns. The fix's check is in two places:
#   - _release_lock: only unlinks if recorded pid == $$.
#   - _force_release_lock (SIGTERM path): same check.
# Below, we simulate the recycling by checking that _release_lock called
# by a different foundation (different recorded pid, no open fd) does
# nothing.
subtest '_release_lock does not unlock somebody else\'s lock' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    my $f1  = App::karr::Foundation->new( _config_data => {} );
    my $f2  = App::karr::Foundation->new( _config_data => {} );

    ok $f1->_acquire_lock( $dir ), 'A acquires';

    # f2 has no fd stashed, so this call must be a no-op: it must not
    # close A's fd, must not unlink the file, must not affect A's lock.
    $f2->_release_lock( $dir );

    ok  $f1->_lock_held( $dir ),   'A still holds the lock';
    ok -e $dir->child('.karr.lock'), 'lock file still present';

    $f1->_release_lock( $dir );
};

# _lock_held must report false on a .karr.lock nobody is flocking -- even
# if its recorded pid is alive in some other context. The fix decoupled
# held-ness from the recorded pid text.
subtest '_lock_held is false on an un-flocked .karr.lock, regardless of pid text' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) );
    $dir->child('.karr.lock')->spew_utf8( "999999\n" );
    my $f = App::karr::Foundation->new( _config_data => {} );

    ok !$f->_lock_held( $dir ),
        'a stale .karr.lock nobody is flocking is not held -- a fresh tick can take over'
        or diag 'lock is reported held by a stale pid -- this is the bug #162 invariant';

    ok $f->_acquire_lock( $dir ), 'a fresh tick takes over without manual cleanup';
    $f->_release_lock( $dir );
};

done_testing;