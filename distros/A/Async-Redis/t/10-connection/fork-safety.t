# t/10-connection/fork-safety.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use POSIX qw(_exit);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
            reconnect => 1,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'connection tracks PID' => sub {
        ok($redis->{_pid}, 'PID tracked');
        is($redis->{_pid}, $$, 'PID matches current process');
    };

    subtest 'connection detects fork and reconnects' => sub {
        plan skip_all => 'fork() not supported on this platform'
            if $^O eq 'MSWin32';

        # Store a value
        run { $redis->set('fork:test', 'parent_value') };

        my $pipe_to_child;
        my $pipe_from_child;
        pipe($pipe_from_child, $pipe_to_child) or die "pipe: $!";

        my $pid = fork();
        die "fork failed: $!" unless defined $pid;

        if ($pid == 0) {
            # Child process
            close $pipe_from_child;

            # Create a new loop for the child
            my $child_loop = IO::Async::Loop->new;

            # The redis connection should detect PID change and reconnect
            my $result;
            eval {
                $child_loop->await($redis->get('fork:test'))->then(sub {
                    $result = shift;
                    Future->done;
                })->get;
            };

            if ($@) {
                print $pipe_to_child "ERROR: $@\n";
            }
            elsif (defined $result && $result eq 'parent_value') {
                print $pipe_to_child "SUCCESS\n";
            }
            else {
                print $pipe_to_child "WRONG: " . ($result // 'undef') . "\n";
            }

            close $pipe_to_child;
            _exit(0);
        }

        # Parent process
        close $pipe_to_child;

        # Wait for child
        waitpid($pid, 0);

        my $child_output = do { local $/; <$pipe_from_child> };
        close $pipe_from_child;

        like($child_output, qr/SUCCESS/, "child got correct value after fork: $child_output");
    };

    subtest 'pool detects fork and clears connections' => sub {
        plan skip_all => 'fork() not supported on this platform'
            if $^O eq 'MSWin32';

        require Async::Redis::Pool;

        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 1,
            max  => 3,
        );

        # Get a connection in parent
        my $conn1 = run { $pool->acquire };
        run { $conn1->set('fork:pool', 'pool_value') };
        $pool->release($conn1);

        # Check pool stats before fork
        my $stats_before = $pool->stats;
        ok($stats_before->{idle} >= 1, 'pool has idle connections before fork');

        my $pipe_to_child;
        my $pipe_from_child;
        pipe($pipe_from_child, $pipe_to_child) or die "pipe: $!";

        my $pid = fork();
        die "fork failed: $!" unless defined $pid;

        if ($pid == 0) {
            # Child process
            close $pipe_from_child;

            # After fork, pool should detect fork and clear connections
            # Check that _check_fork is called on acquire
            my $stats_after = $pool->stats;

            # Force fork check by accessing pool state
            $pool->_check_fork;

            # After fork check, pool should be empty
            my $stats_cleared = $pool->stats;

            if ($stats_cleared->{idle} == 0 && $stats_cleared->{active} == 0) {
                print $pipe_to_child "SUCCESS\n";
            }
            else {
                print $pipe_to_child "WRONG: idle=$stats_cleared->{idle} active=$stats_cleared->{active}\n";
            }

            close $pipe_to_child;
            _exit(0);
        }

        # Parent
        close $pipe_to_child;
        waitpid($pid, 0);

        my $child_output = do { local $/; <$pipe_from_child> };
        close $pipe_from_child;

        like($child_output, qr/SUCCESS/, "pool cleared after fork in child: $child_output");

        # Parent pool should still work
        my $conn2 = run { $pool->acquire };
        my $val = run { $conn2->get('fork:pool') };
        is($val, 'pool_value', 'parent pool still works after child fork');
        $pool->release($conn2);

        # Cleanup
        run { $redis->del('fork:pool') };
    };

    subtest 'parent connection still works after fork' => sub {
        plan skip_all => 'fork() not supported on this platform'
            if $^O eq 'MSWin32';

        my $pid = fork();
        die "fork failed: $!" unless defined $pid;

        if ($pid == 0) {
            # Child just exits
            _exit(0);
        }

        waitpid($pid, 0);

        # Parent connection should still work
        my $result = run { $redis->ping };
        is($result, 'PONG', 'parent connection works after fork');
    };

    # Cleanup
    run { $redis->del('fork:test') };
    $redis->disconnect;
}

done_testing;
