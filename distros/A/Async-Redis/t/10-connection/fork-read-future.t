# t/10-connection/fork-read-future.t
#
# Test that _check_fork properly clears _current_read_future
#
# The bug: When a fork occurs while a blocking read is in progress,
# the child process inherits a stale _current_read_future reference.
# If the child then calls disconnect(), it tries to cancel a future
# that belongs to the parent's event loop context.

use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(skip_without_redis run);
use Test2::V0;

subtest '_check_fork clears _current_read_future' => sub {
    my $redis = skip_without_redis();

    # Simulate what happens during a blocking read:
    # 1. _current_read_future gets set
    # 2. Fork happens
    # 3. _check_fork is called in child

    # Create a fake "current read future" to simulate being mid-read
    $redis->{_current_read_future} = Future->new;
    ok(defined $redis->{_current_read_future}, '_current_read_future is set');

    # Simulate fork by changing PID
    my $original_pid = $redis->{_pid};
    $redis->{_pid} = $$ + 99999;  # Fake a different PID

    # Now trigger fork detection
    my $fork_detected = $redis->_check_fork;
    ok($fork_detected, '_check_fork detected the fork');

    # BUG: _current_read_future should be cleared but isn't
    # This test will FAIL before the fix, demonstrating the bug
    is($redis->{_current_read_future}, undef,
       '_current_read_future should be cleared after fork detection');

    # Also verify the other state was cleared properly
    is($redis->{connected}, 0, 'connected is false after fork');
    is($redis->{socket}, undef, 'socket is undef after fork');
    is($redis->{inflight}, [], 'inflight is empty after fork');
};

subtest 'disconnect after fork with stale read future' => sub {
    my $redis = skip_without_redis();

    # Set up state as if we were mid-read when fork happened
    $redis->{_current_read_future} = Future->new;
    my $stale_future = $redis->{_current_read_future};

    # Simulate fork
    $redis->{_pid} = $$ + 99999;
    $redis->_check_fork;

    # Now disconnect - this should work cleanly
    # Before the fix, this might try to cancel the stale future
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    eval { $redis->disconnect };
    my $error = $@;

    is($error, '', 'disconnect after fork should not die');

    # The stale future should NOT have been cancelled by disconnect
    # because _check_fork should have cleared the reference
    # (Before the fix, disconnect might try to cancel it)

    # Filter for relevant warnings
    my @relevant = grep { /future|cancel|stale/i } @warnings;
    is(\@relevant, [], 'no warnings about stale futures');
};

subtest 'stale future not cancelled after fork' => sub {
    my $redis = skip_without_redis();

    # Create a fake read future
    my $stale_future = Future->new;
    $redis->{_current_read_future} = $stale_future;

    # Simulate fork detection
    $redis->{_pid} = $$ + 99999;
    $redis->_check_fork;

    # The stale future should NOT be cancelled by _check_fork
    # (it belongs to the parent's context - we just want to clear the reference)
    # But the reference should be cleared so disconnect doesn't try to use it

    # Verify the reference was cleared (this is what we're testing)
    is($redis->{_current_read_future}, undef,
       'reference to stale future should be cleared');

    # The original future object should still exist and not be cancelled
    # (parent process owns it)
    ok(!$stale_future->is_cancelled,
       'stale future itself should not be cancelled (belongs to parent)');
};

done_testing;
