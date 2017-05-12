package t::Plack::Middleware::APISchema::RequestValidator;
use t::test;
use t::test::fixtures;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Status qw(:constants);
use JSON::XS qw(encode_json);

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'Plack::Middleware::APISchema::RequestValidator';
}

sub instantiate : Tests {
    my $schema = APISchema::Schema->new;
    my $middleware = Plack::Middleware::APISchema::RequestValidator->new(schema => $schema);
    isa_ok $middleware, 'Plack::Middleware::APISchema::RequestValidator';

    is $middleware->schema, $schema;

    isa_ok $middleware->router, 'Router::Simple';
}

sub request_validator : Tests {
    my $schema = t::test::fixtures::prepare_bmi;
    $schema->register_route(
        method => 'POST',
        route => '/bmi_strict',
        request_resource => {
            encoding => { 'application/json' => 'json' },
            body => 'figure',
        },
    );
    $schema->register_route(
        method => 'POST',
        route => '/bmi_force_json',
        request_resource => {
            encoding => 'json',
            body => 'figure',
        },
    );
    $schema->register_route(
        method => 'POST',
        route => '/bmi_by_parameter',
        request_resource => {
            parameter => 'figure',
        },
    );
    $schema->register_resource(figure_header => {
        type => 'object',
        properties => {
            'x_weight' => { type => 'number' },
            'x_height' => { type => 'number' },
        },
        required => ['x_weight', 'x_height'],
    });
    $schema->register_route(
        method => 'POST',
        route => '/bmi_by_header',
        request_resource => {
            header => 'figure_header',
        },
    );

    my $middleware = Plack::Middleware::APISchema::RequestValidator->new(schema => $schema);
    $middleware->wrap(sub {
        [200, [ 'Content-Type' => 'text/plain' ], [ 'dummy' ]  ]
    });

    subtest 'when valid request' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi',
                Content_Type => 'application/json',
                Content => encode_json({weight => 50, height => 1.6}),
            );
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when valid utf8 request' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi',
                Content_Type => 'application/json; charset=UTF-8',
                Content => encode_json({weight => 50, height => 1.6}),
            );
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when invalid request' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi',
                Content_Type => 'application/json',
                Content => encode_json({}),
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                body => {
                    attribute => 'Valiemon::Attributes::Required',
                    position => '/$ref/required',
                    message => "Contents do not match resource 'figure'",
                    encoding => 'json',
                    actual => {},
                    expected => $schema->get_resource_by_name('figure')->definition,
                },
            });
            done_testing;
        }
    };

    subtest 'other endpoints are not affected' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(GET '/other/');
            is $res->code, 200;
        }
    };

    subtest 'when request is not a JSON' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi',
                Content_Type => 'application/json',
                Content => 'aaa',
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                body => {
                    message => "Failed to parse json",
                    encoding => 'json',
                },
            });
            done_testing;
        }
    };

    subtest 'when content-type is incorrect' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $content_type = 'application/x-www-form-urlencoded';
            my $res = $server->(
                POST '/bmi',
                Content_Type => $content_type,
                Content => encode_json({weight => 50, height => 1.6}),
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                body => {
                    attribute => 'Valiemon::Attributes::Required',
                    position => '/$ref/required',
                    message => "Contents do not match resource 'figure'",
                    encoding => 'url_parameter',
                    actual => isa('HASH'),
                    # XXX: Hash order randomization
                    # actual => { "{\"weight\":50,\"height\":1.6}" => undef }
                    expected => $schema->get_resource_by_name('figure')->definition,
                },
            });
            done_testing;
        }
    };

    subtest 'when content-type is incorrect with forced encoding' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $content_type = 'application/x-www-form-urlencoded';
            my $res = $server->(
                POST '/bmi_force_json',
                Content_Type => $content_type,
                Content => encode_json({weight => 50, height => 1.6}),
            );
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when content-type is incorrect with strict content-type check' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $content_type = 'application/x-www-form-urlencoded';
            my $res = $server->(
                POST '/bmi_strict',
                Content_Type => $content_type,
                Content => encode_json({weight => 50, height => 1.6}),
            );
            is $res->code, HTTP_UNSUPPORTED_MEDIA_TYPE;
            cmp_deeply $res->content, json({
                body => { message => "Wrong content-type: $content_type" },
            });
            done_testing;
        }
    };

    subtest 'when valid request by parameter' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi_by_parameter?weight=50&height=1.6',
            );
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when invalid request by parameter' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi_by_parameter?weight=50',
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                parameter => {
                    attribute => 'Valiemon::Attributes::Required',
                    position => '/$ref/required',
                    message => "Contents do not match resource 'figure'",
                    encoding => 'url_parameter',
                    actual => {
                        weight => 50,
                    },
                    expected => $schema->get_resource_by_name('figure')->definition,
                },
            });
            done_testing;
        }
    };

    subtest 'when valid request by header' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi_by_header',
                X_Weight => 50,
                X_Height => 1.6,
            );
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when invalid request by header' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/bmi_by_header',
                X_Weight => 50,
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                header => {
                    attribute => 'Valiemon::Attributes::Required',
                    position => '/$ref/required',
                    message => "Contents do not match resource 'figure_header'",
                    encoding => 'perl',
                    actual => {
                        content_length => 0,
                        x_weight       => 50,
                        content_type   => "application/x-www-form-urlencoded",
                        host           => "localhost",
                    },
                    expected => $schema->get_resource_by_name('figure_header')->definition,
                },
            });
            done_testing;
        }
    };
}

sub request_validator_with_utf8 : Tests {
    my $schema = t::test::fixtures::prepare_user;
    $schema->register_route(
        method => 'POST',
        route => '/user',
        request_resource => {
            body => 'user',
        },
    );

    my $middleware = Plack::Middleware::APISchema::RequestValidator->new(schema => $schema);
    $middleware->wrap(sub {
        [200, [ 'Content-Type' => 'text/plain' ], [ 'dummy' ]  ]
    });

    subtest 'when invalid request' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(
                POST '/user',
                Content_Type => 'application/json',
                Content => encode_json({
                    first_name => 'Bill',
                    last_name => [],
                }),
            );
            is $res->code, HTTP_UNPROCESSABLE_ENTITY;
            cmp_deeply $res->content, json({
                body  => {
                    actual    => [],
                    attribute => 'Valiemon::Attributes::Type',
                    position  => '/$ref/properties/last_name/type',
                    expected  => $schema->get_resource_by_name('user')->definition->{properties}->{last_name},
                    encoding  => 'json',
                    message   => "Contents do not match resource 'user'",
                },
            });
            done_testing;
        };
    };
}
