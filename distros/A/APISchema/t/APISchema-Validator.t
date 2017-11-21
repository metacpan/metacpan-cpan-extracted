package t::Plack::Middleware::APISchema::ResponseValidator;
use lib '.';
use t::test;
use t::test::fixtures;
use JSON::XS qw(encode_json);

sub _require : Test(startup => 1) {
    use_ok 'APISchema::Validator';
}

sub instantiate : Tests {
    subtest 'For request' => sub {
        my $validator = APISchema::Validator->for_request;
        isa_ok $validator, 'APISchema::Validator';
        is $validator->validator_class, 'Valiemon';
        is $validator->fetch_resource_method, 'canonical_request_resource';
    };

    subtest 'For response' => sub {
        my $validator = APISchema::Validator->for_response;
        isa_ok $validator, 'APISchema::Validator';
        is $validator->validator_class, 'Valiemon';
        is $validator->fetch_resource_method, 'canonical_response_resource';
    };

    subtest 'Result' => sub {
        my $r = APISchema::Validator::Result->new;
        isa_ok $r, 'APISchema::Validator::Result';

        my $valid = APISchema::Validator::Result->new_valid;
        isa_ok $valid, 'APISchema::Validator::Result';

        my $error = APISchema::Validator::Result->new_valid;
        isa_ok $error, 'APISchema::Validator::Result';
    };
}

sub result : Tests {
    subtest 'empty' => sub {
        my $r = APISchema::Validator::Result->new;
        ok $r->is_valid;
        is_deeply $r->errors, {};
    };

    subtest 'valid without target' => sub {
        my $r = APISchema::Validator::Result->new_valid;
        ok $r->is_valid;
        is_deeply $r->errors, {};
    };

    subtest 'valid with targets' => sub {
        my $r = APISchema::Validator::Result->new_valid(qw(foo));
        ok $r->is_valid;
        is_deeply $r->errors, {};
    };

    subtest 'error without target' => sub {
        my $r = APISchema::Validator::Result->new_error;
        ok !$r->is_valid;
    };

    subtest 'error without target' => sub {
        my $r = APISchema::Validator::Result->new_error(foo => 'bar');
        ok !$r->is_valid;
        is_deeply $r->errors, { foo => 'bar' };
    };

    subtest 'merge' => sub {
        my $r = APISchema::Validator::Result->new;

        $r->merge(APISchema::Validator::Result->new_valid());
        ok $r->is_valid;
        is_deeply $r->errors, {};

        $r->merge(APISchema::Validator::Result->new_valid(qw(foo)));
        ok $r->is_valid;
        is_deeply $r->errors, {};

        $r->merge(APISchema::Validator::Result->new_error(bar => 1));
        ok !$r->is_valid;
        is_deeply $r->errors, { bar => 1 };

        $r->merge(APISchema::Validator::Result->new_error(foo => 3));
        ok !$r->is_valid;
        is_deeply $r->errors, { foo => 3, bar => 1 };
    };
}

sub _simple_route ($$) {
    my ($schema, $keys)  =  @_;
    $keys = [qw(header parameter body)] unless defined $keys;
    $schema->register_route(
        route => '/endpoint',
        request_resource => {
            map { $_ => 'figure' } @$keys
        },
        response_resource => {
            map { $_ => 'bmi' } @$keys
        },
    );
    return $schema;
}

sub _forced_route ($$) {
    my ($schema, $keys)  =  @_;
    $keys = [qw(header parameter body)] unless defined $keys;
    $schema->register_route(
        route => '/endpoint',
        request_resource => {
            encoding => 'json',
            map { $_ => 'figure' } @$keys
        },
        response_resource => {
            encoding => 'json',
            map { $_ => 'bmi' } @$keys
        },
    );
    return $schema;
}

sub _invalid_encoding_route ($$) {
    my ($schema, $keys)  =  @_;
    $keys = [qw(header parameter body)] unless defined $keys;
    $schema->register_route(
        route => '/endpoint',
        request_resource => {
            encoding => 'hoge',
            map { $_ => 'figure' } @$keys
        },
        response_resource => {
            encoding => 'hoge',
            map { $_ => 'bmi' } @$keys
        },
    );
    return $schema;
}

sub _strict_route ($$) {
    my ($schema, $keys)  =  @_;
    $keys = [qw(header parameter body)] unless defined $keys;
    $schema->register_route(
        route => '/endpoint',
        request_resource => {
            encoding => { 'application/json' => 'json' },
            map { $_ => 'figure' } @$keys
        },
        response_resource => {
            encoding => { 'application/json' => 'json' },
            map { $_ => 'bmi' } @$keys
        },
    );
    return $schema;
}

sub validate_request : Tests {
    subtest 'valid with emtpy schema' => sub {
        my $schema = APISchema::Schema->new;
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            header => { foo => 'bar' },
            parameter => 'foo&bar',
            body => '{"foo":"bar"}',
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with empty target' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, [];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {}, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with some target and schema' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid with missing property' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('json') ];
    };

    subtest 'invalid without body' => sub {
        for my $value ({}, '', undef) {
            my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
            my $validator = APISchema::Validator->for_request;
            my $result = $validator->validate('/endpoint' => {
                body => $value,
            }, $schema);
            ok ! $result->is_valid;
            is_deeply [ keys %{$result->errors} ], [ 'body' ];
        }
    };

    subtest 'invalid without parameter' => sub {
        for my $value ({}, '', undef) {
            my $schema = _simple_route t::test::fixtures::prepare_bmi, ['parameter'];
            my $validator = APISchema::Validator->for_request;
            my $result = $validator->validate('/endpoint' => {
                parameter => $value,
            }, $schema);
            ok ! $result->is_valid;
            is_deeply [ keys %{$result->errors} ], [ 'parameter' ];
        }
    };


    subtest 'invalid with wrong encoding' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/x-www-form-urlencoded',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('url_parameter') ];
    };

    subtest 'invalid with invalid encoding' => sub {
        my $schema = _invalid_encoding_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{message} } values %{$result->errors} ],
            [ ('Unknown decoding method: hoge') ];
    };

    subtest 'valid with forced encoding' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/x-www-form-urlencoded',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with strict content-type check' => sub {
        my $schema = _strict_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid with wrong content type' => sub {
        my $schema = _strict_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $content_type = 'application/x-www-form-urlencoded';
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({weight => 50, height => 1.6}),
            content_type => $content_type,
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{message} } values %{$result->errors} ],
            [ ("Wrong content-type: $content_type") ];
    };

    subtest 'valid parameter' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['parameter'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            parameter => 'weight=50&height=1.6',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid parameter' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['parameter'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            parameter => 'weight=50',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('url_parameter') ];
    };

    subtest 'valid header' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['header'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            header => { weight => 50, height => 1.6 },
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid header' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['header'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            header => { weight => 50 },
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'header' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('perl') ];
    };

    subtest 'all valid' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body', 'parameter', 'header'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            header => { weight => 50, height => 1.6 },
            parameter => 'weight=50&height=1.6',
            body => encode_json({weight => 50, height => 1.6}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'many invalid' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body', 'parameter', 'header'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('/endpoint' => {
            header => { weight => 50 },
            parameter => 'weight=50',
            body => encode_json({weight => 50}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is scalar keys %{$result->errors}, 3;
        is_deeply [ sort keys %{$result->errors} ],
            [ qw(body header parameter) ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') x 3 ];
        is_deeply [ sort map { $_->{encoding} } values %{$result->errors} ],
            [ ('json', 'perl', 'url_parameter') ];
    };
}

sub validate_response : Tests {
    subtest 'valid with emtpy schema' => sub {
        my $schema = APISchema::Schema->new;
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            header => { foo => 'bar' },
            body => '{"foo":"bar"}',
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with empty target' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, [];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {}, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with some target and schema' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid with missing property' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({hoge => 'foo'}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('json') ];
    };

    subtest 'invalid with wrong encoding' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => 'application/x-www-form-urlencoded',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('url_parameter') ];
    };

    subtest 'invalid with invalid encoding' => sub {
        my $schema = _invalid_encoding_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{message} } values %{$result->errors} ],
            [ ('Unknown decoding method: hoge') ];
    };

    subtest 'valid with forced encoding' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => 'application/x-www-form-urlencoded',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'valid with strict content-type check' => sub {
        my $schema = _strict_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid with wrong content type' => sub {
        my $schema = _strict_route t::test::fixtures::prepare_bmi, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $content_type = 'application/x-www-form-urlencoded';
        my $result = $validator->validate('/endpoint' => {
            body => encode_json({value => 19.5}),
            content_type => $content_type,
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'body' ];
        is_deeply [ map { $_->{message} } values %{$result->errors} ],
            [ ("Wrong content-type: $content_type") ];
    };

    subtest 'valid header' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['header'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            header => { value => 19.5 },
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid header' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['header'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            header => {},
        }, $schema);
        ok !$result->is_valid;
        is_deeply [ keys %{$result->errors} ], [ 'header' ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') ];
        is_deeply [ map { $_->{encoding} } values %{$result->errors} ],
            [ ('perl') ];
    };

    subtest 'all valid' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body', 'header'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            header => { value => 19.5 },
            body => encode_json({value => 19.5}),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'many invalid' => sub {
        my $schema = _simple_route t::test::fixtures::prepare_bmi, ['body', 'header'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('/endpoint' => {
            header => {},
            body => encode_json({}),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
        is scalar keys %{$result->errors}, 2;
        is_deeply [ sort keys %{$result->errors} ],
            [ qw(body header) ];
        is_deeply [ map { $_->{attribute} } values %{$result->errors} ],
            [ ('Valiemon::Attributes::Required') x 2 ];
        is_deeply [ sort map { $_->{encoding} } values %{$result->errors} ],
            [ ('json', 'perl') ];
    };

    subtest 'valid referenced resource' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_family, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('Children GET API' => {
            body => encode_json([ {
                name => 'Alice',
                age  => 16,
            }, {
                name => 'Charlie',
                age  => 14,
            } ]),
            content_type => 'application/json',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid referenced resource' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_family, ['body'];
        my $validator = APISchema::Validator->for_response;
        my $result = $validator->validate('Children GET API' => {
            body => encode_json([ {
                name => 'Alice',
                age  => 16,
            }, {
                age  => 14,
            } ]),
            content_type => 'application/json',
        }, $schema);
        ok !$result->is_valid;
    };

 SKIP: {
    skip 'Recursive dereference is not implemented in Valiemon', 2;
    subtest 'valid recursively referenced resource' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_family, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('Children GET API' => {
            parameter => 'name=Bob',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'invalid recursively referenced resource' => sub {
        my $schema = _forced_route t::test::fixtures::prepare_family, ['body'];
        my $validator = APISchema::Validator->for_request;
        my $result = $validator->validate('Children GET API' => {
            parameter => 'person=Bob',
        }, $schema);
        ok !$result->is_valid;
    };

    };
}

sub status : Tests {
    my $schema = t::test::fixtures::prepare_status;
    my $validator = APISchema::Validator->for_response;

    subtest 'Status 200 with valid body' => sub {
        my $result = $validator->validate('Get API' => {
            status_code => 200,
            body => '200 OK',
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'Status 200 with invalid body' => sub {
        my $result = $validator->validate('Get API' => {
            status_code => 200,
            body => { status => 200, message => 'OK' },
        }, $schema);
        ok !$result->is_valid;
    };

    subtest 'Status 400 with valid body' => sub {
        my $result = $validator->validate('Get API' => {
            status_code => 400,
            body => encode_json({ status => 400, message => 'Bad Request' }),
        }, $schema);
        ok $result->is_valid;
    };

    subtest 'Status 400 with invalid body' => sub {
        my $result = $validator->validate('Get API' => {
            status_code => 400,
            body => '400 Bad Request',
        }, $schema);
        ok !$result->is_valid;
    };

    subtest 'Undefined status' => sub {
        my $result = $validator->validate('Get API' => {
            status_code => 599,
            body => { foo => 'bar' },
        }, $schema);
        ok $result->is_valid;
    };
}
