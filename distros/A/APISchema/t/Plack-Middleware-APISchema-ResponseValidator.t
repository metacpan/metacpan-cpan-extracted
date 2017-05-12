package t::Plack::Middleware::APISchema::ResponseValidator;
use t::test;
use t::test::fixtures;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;
use JSON::XS qw(encode_json);

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'Plack::Middleware::APISchema::ResponseValidator';
}

sub instantiate : Tests {
    my $schema = APISchema::Schema->new;
    my $middleware = Plack::Middleware::APISchema::ResponseValidator->new(schema => $schema);
    isa_ok $middleware, 'Plack::Middleware::APISchema::ResponseValidator';

    is $middleware->schema, $schema;

    isa_ok $middleware->router, 'Router::Simple';
}

sub response_validator : Tests {
    my $schema = t::test::fixtures::prepare_bmi;
    $schema->register_route(
        method => 'POST',
        route => '/bmi_strict',
        response_resource => {
            encoding => { 'application/json' => 'json' },
            body => 'bmi',
        },
    );
    $schema->register_route(
        method => 'POST',
        route => '/bmi_force_json',
        response_resource => {
            encoding => 'json',
            body => 'bmi',
        },
    );
    $schema->register_resource(bmi_header => {
        type => 'object',
        properties => {
            'x_value' => { type => 'number' },
        },
        required => ['x_value'],
    });
    $schema->register_route(
        method => 'POST',
        route => '/bmi_by_header',
        response_resource => {
            header => 'bmi_header',
        },
    );

    my $content_type;
    my $json;
    my $middleware = Plack::Middleware::APISchema::ResponseValidator->new(schema => $schema);
    my $header = [];
    $middleware->wrap(sub {
        [200, [ 'Content-Type' => $content_type, @$header ], [ $json ]  ]
    });

    subtest 'when valid response' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/json';
            $json = encode_json({value => 19.5});
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi');
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when invalid response' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/json';
            $json = encode_json({value => 'aaa'});
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({
                body => {
                    attribute => "Valiemon::Attributes::Type",
                    position => '/$ref/properties/value/type',
                    expected => $schema->get_resource_by_name('bmi')->definition->{properties}->{value},
                    actual => 'aaa',
                    message => "Contents do not match resource 'bmi'",
                    encoding => 'json',
                },
            });
            done_testing;
        }
    };

    subtest 'when wrong content-type' => sub {
        test_psgi $middleware => sub {
            $content_type = 'text/plain';
            $json = encode_json({value => 19.5});
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({
                body => { message => "Wrong content-type: text/plain" },
            });
            done_testing;
        }
    };

    subtest 'when response is not a JSON' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/json';
            $json = 'aaa';
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
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
            $content_type = 'application/x-www-form-urlencoded';
            $json = encode_json({value => 19.5});
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({
                body => {
                    attribute => 'Valiemon::Attributes::Required',
                    position => '/$ref/required',
                    message => "Contents do not match resource 'bmi'",
                    encoding => 'url_parameter',
                    actual => {
                        '{"value":19.5}' => undef,
                    },
                    expected => $schema->get_resource_by_name('bmi')->definition,
                },
            });
            done_testing;
        }
    };

    subtest 'when content-type is incorrect with forced encoding' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/x-www-form-urlencoded';
            $json = encode_json({value => 19.5});
            $header = [];
            my $server = shift;
            my $res = $server->(POST '/bmi_force_json');
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when content-type is incorrect with strict content-type check' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/x-www-form-urlencoded';
            $json = encode_json({value => 19.5});
            my $server = shift;
            my $res = $server->(POST '/bmi_strict');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({
                body => { message => "Wrong content-type: $content_type" },
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

    subtest 'when valid response by header' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/json';
            $json = encode_json({});
            $header = [ 'X-Value' => 19.5 ];
            my $server = shift;
            my $res = $server->(POST '/bmi_by_header');
            is $res->code, 200;
            done_testing;
        }
    };

    subtest 'when invalid response by header' => sub {
        test_psgi $middleware => sub {
            $content_type = 'application/json';
            $json = encode_json({});
            $header = [ 'X-Foo' => 1 ];
            my $server = shift;
            my $res = $server->(POST '/bmi_by_header');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({
                header => {
                    attribute => "Valiemon::Attributes::Required",
                    position => '/$ref/required',
                    message => "Contents do not match resource 'bmi_header'",
                    encoding => 'perl',
                    expected => $schema->get_resource_by_name('bmi_header')->definition,
                    actual => {
                        content_type => "application/json",
                        "x_foo" => 1,
                    },
                },
            });
            done_testing;
        }
    };
}
sub status : Tests {
    my $schema = t::test::fixtures::prepare_status;

    my $middleware_ok = Plack::Middleware::APISchema::ResponseValidator->new(schema => $schema);
    $middleware_ok->wrap(sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        if ($req->parameters->{success}) {
            return [ 200, [ 'Content-Type' => 'text/plain', ], [ 'OK' ]  ];
        } elsif ($req->parameters->{undefined}) {
            return [ 599, [ 'Content-Type' => 'application/json', ], [
                encode_json({ status => 599, message => 'Something wrong' }),
            ]  ];
        } else {
            return [ 400, [ 'Content-Type' => 'application/json', ], [
                encode_json({ status => 400, message => 'Bad Request' }),
            ]  ];
        }
    });

    subtest 'Status 200 with valid body' => sub {
        test_psgi $middleware_ok => sub {
            my $server = shift;
            my $res = $server->(GET '/get?success=1');
            is $res->code, 200;
            done_testing;
        };
    };

    subtest 'Status 400 with valid body' => sub {
        test_psgi $middleware_ok => sub {
            my $server = shift;
            my $res = $server->(GET '/get');
            is $res->code, 400;
            done_testing;
        };
    };

    subtest 'Undefined status' => sub {
        test_psgi $middleware_ok => sub {
            my $server = shift;
            my $res = $server->(GET '/get?undefined=1');
            is $res->code, 599;
            done_testing;
        };
    };

    my $middleware_ng = Plack::Middleware::APISchema::ResponseValidator->new(schema => $schema);
    $middleware_ng->wrap(sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        return [ 400, [ 'Content-Type' => 'text/plain', ], [ 'OK' ] ];
    });

    subtest 'Status 400 with invalid body' => sub {
        test_psgi $middleware_ng => sub {
            my $server = shift;
            my $res = $server->(GET '/get');
            is $res->code, 500;
            is $res->header('X-Error-Cause'), 'Plack::Middleware::APISchema::ResponseValidator+Valiemon';
            cmp_deeply $res->content, json({ body => {
                message => 'Failed to parse json',
                encoding => 'json',
            } });
            done_testing;
        };
    };
}

sub response_validator_with_utf8 : Tests {
    my $schema = t::test::fixtures::prepare_user;
    $schema->register_route(
        method => 'GET',
        route => '/user',
        response_resource => {
            body => 'user',
        },
    );
    my $middleware = Plack::Middleware::APISchema::ResponseValidator->new(schema => $schema);
    $middleware->wrap(sub {
        [200, [ 'Content-Type' => 'application/json; charset=utf-8' ], [ encode_json({ first_name => 'Bill', last_name => []}) ]  ]
    });

    subtest 'invalid response with utf8' => sub {
        test_psgi $middleware => sub {
            my $server = shift;
            my $res = $server->(GET '/user');
            is $res->code, 500;
            cmp_deeply $res->content, json({
                body => {
                    attribute => "Valiemon::Attributes::Type",
                    position => '/$ref/properties/last_name/type',
                    expected => $schema->get_resource_by_name('user')->definition->{properties}->{last_name},
                    actual => [],
                    message => "Contents do not match resource 'user'",
                    encoding => 'json',
                },
            });
            done_testing;
        };
    };
}
