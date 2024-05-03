#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;
use HTTP::Request::Common;
use Plack::Test;

use OpenTelemetry -all;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Trace::Tracer;

use experimental 'signatures';

my $span;
my $mock = mock 'OpenTelemetry::Trace::Tracer' => override => [
    create_span => sub {
        shift;
        $span = mock { otel => { @_ } } => track => 1 => add => [
            record_exception => sub { $_[0] },
            set_attribute    => sub { $_[0] },
            set_status       => sub { $_[0] },
        ];
    },
];

sub span_calls ( $tests, $message = undef ) {
    my @calls;
    while ( my $name = shift @$tests ) {
        push @calls => {
            sub_name => $name,
            args     => [ D, @{ shift @$tests } ],
            sub_ref  => E,
        };
    }

    is  [ mocked($span) ]->[0]->call_tracking, \@calls,
        $message // 'Called expected methods on span';
}

use Object::Pad;
class Local::Provider :isa(OpenTelemetry::Trace::TracerProvider) { }

OpenTelemetry->tracer_provider = Local::Provider->new;

package Local::App {
    use Dancer2;
    use Dancer2::Plugin::OpenTelemetry;

    set logger => 'null';

    get '/static/url' => sub { 'OK' };

    get '/url/with/pass' => sub { pass };

    get '/url/with/:placeholder' => sub { 'OK' };

    get '/forward' => sub { forward '/static/url' };

    get '/async' => sub {
        delayed {
            flush;
            content 'O';

            require IO::Async::Loop;
            require IO::Async::Timer::Countdown;

            my $loop = IO::Async::Loop->new;

            $loop->add(
                IO::Async::Timer::Countdown->new(
                   delay => 0.1,
                   on_expire => delayed {
                      content 'K';
                      $loop->stop;
                      done;
                   },
                )->start
            );

            $loop->run;
        }
    };

    get '/status/:code' => sub {
        status params->{code};
        'OK';
    };

    get '/error' => sub { die 'oops' };
}

my $test = Plack::Test->create( Local::App->to_app );

subtest 'Static URL' => sub {
    is $test->request( GET '/static/url?query=parameter' ), object {
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/static/url',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/static/url',
            'url.query'                => 'query=parameter',
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /static/url',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest 'Forward' => sub {
    is $test->request( GET '/forward' ), object {
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/forward',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/forward',
            'url.query'                => DNE,
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /forward',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest 'Pass' => sub {
    is $test->request( GET '/url/with/pass' ), object {
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/url/with/pass',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/url/with/pass',
            'url.query'                => DNE,
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /url/with/pass',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest 'Async' => sub {
    require Test2::Require::Module;
    Test2::Require::Module->import('IO::Async');

    is $test->request( GET '/async', user_agent => 'Test' ), object {
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/async',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/async',
            'url.scheme'               => 'http',
            'user_agent.original'      => 'Test',
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /async',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest 'With placeholder' => sub {
    is $test->request( GET '/url/with/value' ), object {
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/url/with/:placeholder',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/url/with/value',
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /url/with/:placeholder',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_status    => [ SPAN_STATUS_OK ],
        set_attribute => [ 'http.response.status_code', 200 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest 'Response code' => sub {
    is $test->request( GET '/status/400' ), object {
        call code            => 400;
        call decoded_content => 'OK';
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/status/:code',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/status/400',
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /status/:code',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        set_attribute => [ 'http.response.status_code', 400 ],
        end           => [],
    ], 'Expected calls on span';
};

subtest Error => sub {
    is $test->request( GET '/error' ), object {
        call code => 500;
    }, 'Request OK';

    is $span->{otel}, {
        attributes => {
            'client.address'           => '127.0.0.1',
            'client.port'              => DNE,
            'http.request.method'      => 'GET',
            'http.route'               => '/error',
            'network.protocol.version' => '1.1',
            'server.address'           => 'localhost',
            'server.port'              => DNE,
            'url.path'                 => '/error',
            'url.scheme'               => 'http',
            'user_agent.original'      => DNE,
        },
        kind => SPAN_KIND_SERVER,
        name => 'GET /error',
        parent => D, # FIXME: can't use object check in 5.32
      # parent => object {
      #     prop isa => 'OpenTelemetry::Context';
      # },
    }, 'Span created as expected';

    span_calls [
        record_exception => [ match qr/oops at \S+ line [0-9]+\.$/ ],
        set_status       => [ SPAN_STATUS_ERROR, 'oops' ],
        set_attribute    => [
            'error.type' => 'string',
            'http.response.status_code' => 500,
        ],
        end => [],
    ], 'Expected calls on span';
};

describe 'Host / port parsing' => sub {
    my $port;

    case 'With port'    => sub { $port = '1234' };
    case 'Without port' => sub { undef $port    };

    tests Host => sub {
        is $test->request(
            GET '/static/url',
                host => join ':', 'some.doma.in', $port // (),
        ), object {
            call code => 200;
        }, 'Request OK';

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'X-Forwarded-Proto wins over Host' => sub {
        is $test->request(
            GET '/static/url',
                Host => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => join ':', 'some.doma.in', $port // (),
        ), object {
            call code => 200;
        }, 'Request OK';

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'Forwarded wins over X-Forwarded-Proto' => sub {
        is $test->request(
            GET '/static/url',
                Host      => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => 'another.wrong.doma.in:8888',
                Forwarded => 'host=' . join ':', 'some.doma.in', $port // (),
        ), object {
            call code => 200;
        }, 'Request OK';

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };

    tests 'Forwarded with multiple values' => sub {
        is $test->request(
            GET '/static/url',
                Host      => 'wrong.doma.in:9999',
                'X-Forwarded-Proto' => 'another.wrong.doma.in:8888',
                Forwarded => 'host=' . join( ':', 'some.doma.in', $port // () )
                    . ', host=wrong.doma.in:777',
        ), object {
            call code => 200;
        }, 'Request OK';

        like $span->{otel}, {
            attributes => {
                'server.address' => 'some.doma.in',
                'server.port'    => $port ? $port : DNE,
            },
        };
    };
};

done_testing;
