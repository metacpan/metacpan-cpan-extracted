package t::APISchema::Generator::Router::Simple;
use lib '.';
use t::test;
use Encode qw(decode_utf8);

sub _require : Test(startup => 1) {
    my ($self) = @_;

    BEGIN{ use_ok 'APISchema::DSL'; }
}

sub no_global : Tests {
    dies_ok {
        filter {};
    };

    dies_ok {
        title 'test';
    };

    dies_ok {
        description 'test';
    };

    dies_ok {
        resource 'test' => ();
    };

    dies_ok {
        GET '/' => ();
    };

    dies_ok {
        POST '/' => ();
    };

}

sub process : Tests {
    lives_ok {
        my $schema = APISchema::DSL::process {};
        isa_ok $schema, 'APISchema::Schema';
    };

    dies_ok {
        GET '/' => ();
    };

    subtest 'title, description' => sub {
        lives_ok {
            my $schema = APISchema::DSL::process {
                title 'BMI API';
                description 'The API to calculate BMI';
            };
            isa_ok $schema, 'APISchema::Schema';
            is $schema->title, 'BMI API';
            is $schema->description, 'The API to calculate BMI';
        };
    };

    subtest 'Simple GET' => sub {
        lives_ok {
            my $schema = APISchema::DSL::process {
                GET '/' => {
                    title       => 'Simple GET',
                    destination => { some => 'property' },
                };
            };
            isa_ok $schema, 'APISchema::Schema';

            my $routes = $schema->get_routes;
            is scalar @$routes, 1;

            is $routes->[0]->route, '/';
            is $routes->[0]->title, 'Simple GET';
            is_deeply $routes->[0]->destination, { some => 'property' };
        };
    };

    subtest 'Support PATCH' => sub {
        lives_ok {
            my $schema = APISchema::DSL::process {
                PATCH '/my' => {
                    title       => 'Update My BMI',
                    destination => {
                        controller => 'BMI',
                        action     => 'update',
                    },
                };
            };
            isa_ok $schema, 'APISchema::Schema';

            my $routes = $schema->get_routes;
            is scalar @$routes, 1;

            is $routes->[0]->route, '/my';
            is $routes->[0]->title, 'Update My BMI';
            is $routes->[0]->method, 'PATCH';
            is_deeply $routes->[0]->destination, {
                controller => 'BMI',
                action     => 'update',
            };
        };
    };

    subtest 'Validation should be returned' => sub {
        lives_ok {
            my $schema = APISchema::DSL::process {
                title 'BMI API';
                description 'The API to calculate BMI';

                resource figure => {
                    type => 'object',
                    description => 'Figure, which includes weight and height',
                    properties => {
                        weight  => {
                            type => 'number',
                            description => 'Weight(kg)',
                            example => 50,
                        },
                        height  => {
                            type => 'number',
                            description => 'Height(m)',
                            example => 1.6,
                        },
                    },
                    required => ['weight', 'height'],
                };

                resource bmi => {
                    type => 'object',
                    description => 'Body mass index',
                    properties => {
                        value  => {
                            type => 'number',
                            description => 'bmi value',
                            example => 19.5,
                        },
                    },
                    required => ['value'],
                };

                POST '/bmi' => {
                    title           => 'BMI API',
                    description     => 'This API calculates your BMI.',
                    destination     => {
                        controller  => 'BMI',
                        action      => 'calculate',
                    },
                    request         => 'figure',
                    response        => 'bmi',
                }, {
                    on_match => sub { 1 },
                };
            };
            isa_ok $schema, 'APISchema::Schema';

            is_deeply [ sort {
                $a->title cmp $b->title;
            } @{$schema->get_resources} ], [ {
                title => 'bmi',
                definition => {
                    type => 'object',
                    description => 'Body mass index',
                    properties => {
                        value  => {
                            type => 'number',
                            description => 'bmi value',
                            example => 19.5,
                        },
                    },
                    required => ['value'],
                },
            }, {
                title => 'figure',
                definition => {
                    type => 'object',
                    description => 'Figure, which includes weight and height',
                    properties => {
                        weight  => {
                            type => 'number',
                            description => 'Weight(kg)',
                            example => 50,
                        },
                        height  => {
                            type => 'number',
                            description => 'Height(m)',
                            example => 1.6,
                        },
                    },
                    required => ['weight', 'height'],
                },
            } ];

            is $schema->title, 'BMI API';
            is $schema->description, 'The API to calculate BMI';

            my $routes = $schema->get_routes;
            is scalar @$routes, 1;

            is $routes->[0]->route, '/bmi';
            is $routes->[0]->title, 'BMI API';
            is $routes->[0]->description, 'This API calculates your BMI.';
            is_deeply $routes->[0]->destination, {
                controller => 'BMI',
                action     => 'calculate',
            };
            cmp_deeply $routes->[0]->option, { on_match => code(sub { 1 }) };
            is $routes->[0]->request_resource, 'figure';
            is $routes->[0]->response_resource, 'bmi';
        };
    };
}

sub from_file : Tests {
    lives_ok {
        my $schema = APISchema::DSL::process {
            include 't/fixtures/bmi.def';
        };

        isa_ok $schema, 'APISchema::Schema';

        is $schema->title, 'BMI API';
        is $schema->description, 'The API to calculate BMI';

        is_deeply [ sort {
            $a->title cmp $b->title;
        } @{$schema->get_resources} ], [ {
            title => 'bmi',
            definition => {
                type => 'object',
                description => 'Body mass index',
                properties => {
                    value  => {
                        type => 'number',
                        description => 'bmi value',
                        example => 19.5,
                    },
                },
                required => ['value'],
            },
        }, {
            title => 'figure',
            definition => {
                type => 'object',
                description => 'Figure, which includes weight and height',
                properties => {
                    weight  => {
                        type => 'number',
                        description => 'Weight(kg)',
                        example => 50,
                    },
                    height  => {
                        type => 'number',
                        description => 'Height(m)',
                        example => 1.6,
                    },
                },
                required => ['weight', 'height'],
            },
        } ];

        my $routes = $schema->get_routes;
        is scalar @$routes, 1;

        is $routes->[0]->route, '/bmi';
        is $routes->[0]->title, 'BMI API';
        is $routes->[0]->description, 'This API calculates your BMI.';
        is_deeply $routes->[0]->destination, {
            controller => 'BMI',
            action     => 'calculate',
        };
        cmp_deeply $routes->[0]->option, { on_match => code(sub { 1 }) };
        is $routes->[0]->request_resource, 'figure';
        is $routes->[0]->response_resource, 'bmi';
    };

    dies_ok {
        my $schema = APISchema::DSL::process {
            include 'not-such-file';
        };
    };

    dies_ok {
        my $schema = APISchema::DSL::process {
            include 't/fixtures/syntax-error.def';
        };
    };

    dies_ok {
        my $schema = APISchema::DSL::process {
            include 't/fixtures/runtime-error.def';
        };
    };
}

sub with_unicode : Tests {
    my $schema = APISchema::DSL::process {
        include 't/fixtures/user.def';
    };

    isa_ok $schema, 'APISchema::Schema';

    is $schema->title, decode_utf8('ユーザー');
    is $schema->description, decode_utf8('ユーザーの定義');

    cmp_deeply $schema->get_resource_by_name('user')->{definition}, {
        type => 'object',
        description => decode_utf8('ユーザー'),
        properties => {
            first_name  => {
                type => 'string',
                description => decode_utf8('姓'),
                example => decode_utf8('小飼'),
            },
            last_name  => {
                type => 'string',
                description => decode_utf8('名'),
                example => decode_utf8('弾'),
            },
        },
        required => ['first_name', 'last_name'],
    };
}
