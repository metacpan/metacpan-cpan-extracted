# t/94-observability/tracing.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;

# Mock OpenTelemetry tracer
package MockSpan {
    sub new {
        my ($class, %args) = @_;
        return bless {
            name       => $args{name},
            kind       => $args{kind},
            attributes => $args{attributes},
            status     => undef,
            exception  => undef,
            ended      => 0,
        }, $class;
    }

    sub set_status {
        my ($self, $status, $msg) = @_;
        $self->{status} = { code => $status, message => $msg };
    }

    sub record_exception {
        my ($self, $error) = @_;
        $self->{exception} = $error;
    }

    sub end {
        my ($self) = @_;
        $self->{ended} = 1;
    }
}

package MockTracer {
    sub new {
        my ($class) = @_;
        return bless { spans => [] }, $class;
    }

    sub create_span {
        my ($self, %args) = @_;
        my $span = MockSpan->new(%args);
        push @{$self->{spans}}, $span;
        return $span;
    }

    sub spans { @{shift->{spans}} }
    sub clear { shift->{spans} = [] }
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

    subtest 'tracer creates spans for commands' => sub {
        my $tracer = MockTracer->new;

        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            otel_tracer => $tracer,
        );
        run { $redis->connect };
        run { $redis->set('trace:key', 'value') };
        run { $redis->get('trace:key') };
        $redis->disconnect;

        my @spans = $tracer->spans;
        ok(@spans >= 2, 'spans created for commands');

        # Find SET span
        my ($set_span) = grep { $_->{name} eq 'redis.SET' } @spans;
        ok($set_span, 'SET span created');
        is($set_span->{attributes}{'db.system'}, 'redis', 'db.system attribute');
        is($set_span->{attributes}{'db.operation'}, 'SET', 'db.operation attribute');
        like($set_span->{attributes}{'db.statement'}, qr/SET trace:key/, 'db.statement attribute');
        is($set_span->{attributes}{'net.peer.name'}, $ENV{REDIS_HOST} // 'localhost', 'net.peer.name attribute');
        ok($set_span->{ended}, 'span ended');

        # Find GET span
        my ($get_span) = grep { $_->{name} eq 'redis.GET' } @spans;
        ok($get_span, 'GET span created');
        like($get_span->{attributes}{'db.statement'}, qr/GET trace:key/, 'GET statement');

        # Cleanup
        run { $test_redis->del('trace:key') };
    };

    subtest 'span records error on command failure' => sub {
        my $tracer = MockTracer->new;

        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            otel_tracer => $tracer,
        );
        run { $redis->connect };

        # Cause an error - INCR on string
        run { $redis->set('trace:error', 'notanumber') };
        eval {
            run { $redis->incr('trace:error') };
        };

        my @spans = $tracer->spans;
        my ($incr_span) = grep { $_->{name} eq 'redis.INCR' } @spans;
        ok($incr_span, 'INCR span created');
        is($incr_span->{status}{code}, 'error', 'span status is error');
        ok($incr_span->{exception}, 'exception recorded');

        $redis->disconnect;
        run { $test_redis->del('trace:error') };
    };

    subtest 'AUTH password redacted in span' => sub {
        # Test the redaction directly via Telemetry module
        my $formatted = Async::Redis::Telemetry::format_command_for_span(
            1, 1, 'AUTH', 'secret123'
        );
        unlike($formatted, qr/secret123/, 'password not in span');
        like($formatted, qr/\[REDACTED\]/, 'password redacted in span');
    };

    subtest 'span includes database index' => sub {
        my $tracer = MockTracer->new;

        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            otel_tracer => $tracer,
            database    => 2,
        );
        run { $redis->connect };
        run { $redis->ping };
        $redis->disconnect;

        my @spans = $tracer->spans;
        my ($ping_span) = grep { $_->{name} eq 'redis.PING' } @spans;
        ok($ping_span, 'PING span created');
        is($ping_span->{attributes}{'db.redis.database_index'}, 2, 'database index in span');
    };

    subtest 'otel_include_args => 0 hides args' => sub {
        my $tracer = MockTracer->new;

        my $redis = Async::Redis->new(
            host              => $ENV{REDIS_HOST} // 'localhost',
            otel_tracer       => $tracer,
            otel_include_args => 0,
        );
        run { $redis->connect };
        run { $redis->set('trace:noargs', 'secretvalue') };
        $redis->disconnect;

        my @spans = $tracer->spans;
        my ($set_span) = grep { $_->{name} eq 'redis.SET' } @spans;
        is($set_span->{attributes}{'db.statement'}, 'SET', 'only command name, no args');

        run { $test_redis->del('trace:noargs') };
    };

    subtest 'span kind is client' => sub {
        my $tracer = MockTracer->new;

        my $redis = Async::Redis->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            otel_tracer => $tracer,
        );
        run { $redis->connect };
        run { $redis->ping };
        $redis->disconnect;

        my @spans = $tracer->spans;
        my ($span) = grep { $_->{name} eq 'redis.PING' } @spans;
        is($span->{kind}, 'client', 'span kind is client');
    };

    $test_redis->disconnect;
}

done_testing;
