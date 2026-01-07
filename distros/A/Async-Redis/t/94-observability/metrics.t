# t/94-observability/metrics.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;

# Mock OpenTelemetry meter
package MockCounter {
    sub new {
        my ($class, %args) = @_;
        return bless {
            name  => $args{name},
            value => 0,
            calls => [],
        }, $class;
    }

    sub add {
        my ($self, $value, $labels) = @_;
        $self->{value} += $value;
        push @{$self->{calls}}, { value => $value, labels => $labels };
    }

    sub value { shift->{value} }
    sub calls { @{shift->{calls}} }
}

package MockHistogram {
    sub new {
        my ($class, %args) = @_;
        return bless {
            name   => $args{name},
            values => [],
        }, $class;
    }

    sub record {
        my ($self, $value, $labels) = @_;
        push @{$self->{values}}, { value => $value, labels => $labels };
    }

    sub values { @{shift->{values}} }
    sub count  { scalar @{shift->{values}} }
}

package MockMeter {
    sub new {
        my ($class) = @_;
        return bless {
            counters   => {},
            histograms => {},
        }, $class;
    }

    sub create_counter {
        my ($self, %args) = @_;
        my $counter = MockCounter->new(%args);
        $self->{counters}{$args{name}} = $counter;
        return $counter;
    }

    sub create_histogram {
        my ($self, %args) = @_;
        my $histogram = MockHistogram->new(%args);
        $self->{histograms}{$args{name}} = $histogram;
        return $histogram;
    }

    sub create_up_down_counter {
        my ($self, %args) = @_;
        return $self->create_counter(%args);
    }

    sub counter    { shift->{counters}{shift()} }
    sub histogram  { shift->{histograms}{shift()} }
}

package main;

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

    subtest 'meter records command counts' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };

        # Execute some commands
        for (1..5) {
            run { $redis->set("metrics:key:$_", "value$_") };
        }
        for (1..3) {
            run { $redis->get("metrics:key:$_") };
        }

        $redis->disconnect;

        my $commands_counter = $meter->counter('redis.commands.total');
        ok($commands_counter, 'commands counter created');
        ok($commands_counter->value >= 8, 'commands counted');

        my @calls = $commands_counter->calls;
        my @set_calls = grep { $_->{labels}{command} eq 'SET' } @calls;
        my @get_calls = grep { $_->{labels}{command} eq 'GET' } @calls;

        is(scalar @set_calls, 5, '5 SET commands recorded');
        is(scalar @get_calls, 3, '3 GET commands recorded');

        # Cleanup
        run { $test_redis->del(map { "metrics:key:$_" } 1..5) };
    };

    subtest 'meter records command latency' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };
        run { $redis->ping };
        $redis->disconnect;

        my $histogram = $meter->histogram('redis.commands.duration');
        ok($histogram, 'duration histogram created');
        ok($histogram->count >= 1, 'latency recorded');

        my @values = $histogram->values;
        for my $v (@values) {
            ok($v->{value} >= 0, "latency >= 0 ($v->{value}ms)");
            ok($v->{value} < 1000, "latency < 1s ($v->{value}ms)");
        }
    };

    subtest 'meter records connection count' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };

        my $connections = $meter->counter('redis.connections.active');
        ok($connections, 'connections counter created');
        is($connections->value, 1, 'connection recorded');

        $redis->disconnect;

        is($connections->value, 0, 'disconnection recorded');
    };

    subtest 'meter records errors' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };

        # Cause an error
        run { $redis->set('metrics:error', 'string') };
        eval { run { $redis->incr('metrics:error') } };

        $redis->disconnect;

        my $errors = $meter->counter('redis.errors.total');
        ok($errors, 'errors counter created');
        ok($errors->value >= 1, 'error recorded');

        run { $test_redis->del('metrics:error') };
    };

    subtest 'meter records pipeline size' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };

        my $pipe = $redis->pipeline;
        $pipe->set('metrics:pipe:1', '1');
        $pipe->set('metrics:pipe:2', '2');
        $pipe->set('metrics:pipe:3', '3');
        run { $pipe->execute };

        $redis->disconnect;

        my $pipeline_hist = $meter->histogram('redis.pipeline.size');
        ok($pipeline_hist, 'pipeline histogram created');

        my @values = $pipeline_hist->values;
        ok(@values >= 1, 'pipeline size recorded');
        is($values[0]{value}, 3, 'pipeline size is 3');

        run { $test_redis->del('metrics:pipe:1', 'metrics:pipe:2', 'metrics:pipe:3') };
    };

    subtest 'latency has command label' => sub {
        my $meter = MockMeter->new;

        my $redis = Async::Redis->new(
            host       => $ENV{REDIS_HOST} // 'localhost',
            otel_meter => $meter,
        );
        run { $redis->connect };
        run { $redis->ping };
        run { $redis->set('metrics:label', 'test') };
        $redis->disconnect;

        my $histogram = $meter->histogram('redis.commands.duration');
        my @values = $histogram->values;

        my @ping_latencies = grep {
            $_->{labels} && $_->{labels}{command} eq 'PING'
        } @values;
        ok(@ping_latencies >= 1, 'PING latency has command label');

        my @set_latencies = grep {
            $_->{labels} && $_->{labels}{command} eq 'SET'
        } @values;
        ok(@set_latencies >= 1, 'SET latency has command label');

        run { $test_redis->del('metrics:label') };
    };

    $test_redis->disconnect;
}

done_testing;
