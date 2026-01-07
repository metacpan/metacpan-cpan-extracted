# t/94-observability/debug.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $test_redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $test_redis;

    subtest 'debug => 1 logs to STDERR' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, shift };

        my $redis = Async::Redis->new(
            host  => $ENV{REDIS_HOST} // 'localhost',
            debug => 1,
        );
        run { $redis->connect };
        run { $redis->ping };
        $redis->disconnect;

        ok(@warnings > 0, 'warnings captured');
        ok((grep { /REDIS/ } @warnings), 'logs contain REDIS prefix');
        ok((grep { /PING/ } @warnings), 'logs contain PING command');
    };

    subtest 'debug => sub logs to custom logger' => sub {
        my @logs;

        my $redis = Async::Redis->new(
            host  => $ENV{REDIS_HOST} // 'localhost',
            debug => sub {
                my ($direction, $data) = @_;
                push @logs, { direction => $direction, data => $data };
            },
        );
        run { $redis->connect };
        run { $redis->set('debug:key', 'value') };
        run { $redis->get('debug:key') };
        $redis->disconnect;

        ok(@logs > 0, 'custom logger called');

        my @sends = grep { $_->{direction} eq 'send' } @logs;
        my @recvs = grep { $_->{direction} eq 'recv' } @logs;

        ok(@sends > 0, 'send logs captured');
        ok(@recvs > 0, 'recv logs captured');

        ok((grep { $_->{data} =~ /SET debug:key/ } @sends), 'SET logged');
        ok((grep { $_->{data} =~ /GET debug:key/ } @sends), 'GET logged');

        # Cleanup
        run { $test_redis->del('debug:key') };
    };

    subtest 'debug logs redact AUTH' => sub {
        my @logs;

        my $redis = Async::Redis->new(
            host     => $ENV{REDIS_HOST} // 'localhost',
            password => 'testpass',  # Will send AUTH
            debug    => sub {
                my ($direction, $data) = @_;
                push @logs, $data;
            },
        );

        # Connect will try AUTH - AUTH command happens during handshake
        # The telemetry only logs via command() not during handshake
        # So we test the redaction function directly instead
        my $formatted = Async::Redis::Telemetry::format_command_for_log(
            'AUTH', 'testpass'
        );
        unlike($formatted, qr/testpass/, 'password not in formatted command');
        like($formatted, qr/\[REDACTED\]/, 'password redacted in formatted command');
    };

    subtest 'debug disabled by default' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, shift };

        my $redis = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $redis->connect };
        run { $redis->ping };
        $redis->disconnect;

        my @redis_warnings = grep { /REDIS/ } @warnings;
        is(scalar @redis_warnings, 0, 'no Redis debug logs by default');
    };

    subtest 'recv log summarizes values' => sub {
        my @logs;

        my $redis = Async::Redis->new(
            host  => $ENV{REDIS_HOST} // 'localhost',
            debug => sub { push @logs, $_[1] },
        );
        run { $redis->connect };
        run { $redis->set('debug:secret', 'supersecretvalue') };
        my $value = run { $redis->get('debug:secret') };
        $redis->disconnect;

        # Actual value was returned
        is($value, 'supersecretvalue', 'got correct value');

        # RECV logs should not contain the actual value (summarized)
        my @recv_logs = grep { /RECV/ } @logs;
        for my $log (@recv_logs) {
            unlike($log, qr/supersecretvalue/, 'secret value not in recv log');
        }

        # Cleanup
        run { $test_redis->del('debug:secret') };
    };

    $test_redis->disconnect;
}

done_testing;
