#!perl
use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
}

use Test::More import => ['!pass'];
use Test::Deep;
use Test::Fatal;
use lib 't/lib';

use HTTP::Request::Common;
use JSON::MaybeXS;
use Plack::Builder;
use Plack::Test;

{

    package TestAppNoConfig;

    use Dancer2;
    use Dancer2::Plugin::DataTransposeValidator;

    get '/' => sub {
        return "home";
    };

    post '/default' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };

    post '/coderef1' => sub {
        my $params = params;
        my $data = validator( $params, 'coderef1', 'String' );
        content_type('application/json');
        return to_json($data);
    };

    post '/coderef2' => sub {
        my $params = params;
        my $data = validator( $params, 'coderef1', 'EmailValid' );
        content_type('application/json');
        return to_json($data);
    };

}

{
    package TestAppClass;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                rules_class => 'TestRules',
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    get '/rules/:name' => sub {
        my $name = route_parameters->get('name');
        # pass foo vaildator to avoid unitialized warnings
        validator( {}, $name, 'String' );
        # this time we pass Foo just so we see it working
        my $rules =
          app->with_plugin('DataTransposeValidator')->rules->{$name}->('Foo');
        send_as JSON => $rules;
    };

    post '/foo_as_string' => sub {
        my $params = params;
        my $data = validator( $params, 'login', 'String' );
        content_type('application/json');
        return to_json($data);
    };

    post '/foo_as_email_valid' => sub {
        my $params = params;
        my $data = validator( $params, 'login', 'EmailValid' );
        content_type('application/json');
        return to_json($data);
    };

    my $hashref = +{
        options => {
            stripwhite          => 1,
            collapse_whitespace => 1,
            requireall          => 1,
            unknown             => "fail",
        },
        prepare => {
            email => {
                validator => "String",
            },
            foo => {
                validator => "EmailValid",
            },
            password => {
                validator => {
                    class   => "PasswordPolicy",
                    options => {
                        disabled => {
                            username => 1,
                        },
                    },
                },
            },
        }
    };

    my $coderef = sub {
        +{
            options => {
                stripwhite          => 1,
                collapse_whitespace => 1,
                requireall          => 1,
                unknown             => "fail",
            },
            prepare => {
                email => {
                    validator => "String",
                },
                foo => {
                    validator => "EmailValid",
                },
                password => {
                    validator => {
                        class   => "PasswordPolicy",
                        options => {
                            disabled => {
                                username => 1,
                            },
                        },
                    },
                },
            }
          }

    };

    post '/hashref' => sub {
        my $params = params;
        my $data = validator( $params, $hashref );
        content_type('application/json');
        return to_json($data);
    };

    post '/coderef' => sub {
        my $params = params;
        my $data = validator( $params, $coderef );
        content_type('application/json');
        return to_json($data);
    };

    post '/arrayref' => sub {
        my $params = params;
        my $data = validator( $params, [] );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppNoErrorsJoined;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                errors_hash => "joined"
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    post '/joined' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppNoErrorsArrayRef;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                errors_hash => "arrayref"
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    post '/arrayref' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppCssErrorClass;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                css_error_class => "foo"
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    post '/css-foo' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppBadRulesDir;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                rules_dir => "foo"
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    post '/bad_rules_dir' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

{

    package TestAppGoodRulesDir;

    use Dancer2;
    BEGIN {
        set plugins => {
            DataTransposeValidator => {
                rules_dir => "validation"
            }
        };
    }
    use Dancer2::Plugin::DataTransposeValidator;

    post '/good_rules_dir' => sub {
        my $params = params;
        my $data = validator( $params, 'rules1' );
        content_type('application/json');
        return to_json($data);
    };
}

my ( $data, $expected, $req, $res );
my $uri = "http://localhost";

my $test = Plack::Test->create( TestAppNoConfig->to_app );

subtest 'TestAppNoConfig /' => sub {

    # simple test to make sure nothing scary is happening
    $req = GET "$uri/";
    $res = $test->request($req);
    ok( $res->is_success, "get / OK" );
    like( $res->content, qr/home/, "Content contains home" );
};

subtest 'TestAppNoConfig /default missing email & password' => sub {

    # errors_hash is false
    $req = POST "$uri/default", [ foo => "bar" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" ) or diag $res->content;

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => "Missing required field password"
        },
        valid  => 0,
        values => {
            foo => "bar",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /default missing email' => sub {

    # errors_hash is false
    $req = POST "$uri/default", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/\w/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /default all valid' => sub {

    $req = POST "$uri/default",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" );

    $expected = {
        valid  => 1,
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /coderef1' => sub {

    # coderef with foo validated as String
    $req = POST "$uri/coderef1",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "coderef rules foo String" );

    $expected = {
        valid  => 1,
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'TestAppNoConfig /coderef2' => sub {

    # coderef with foo validated as String
    $req = POST "$uri/coderef2",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "coderef rules foo EmailValid" );

    $expected = {
        css => {
            foo => "has-error"
        },
        errors => {
            foo => "rfc822"
        },
        valid  => 0,
        values => {
            email    => "user\@example.com",
            foo      => "bar",
            password => "cA\$(!n6K)Y.zoKoqayL}\$O6EY}Q+g"
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

subtest 'Testing rules via rules_class setting' => sub {

    my $test = Plack::Test->create( TestAppClass->to_app );
    my $trap = TestAppClass->dancer_app->logger_engine->trapper;

    $req = GET "$uri/rules/login";
    $res = $test->request($req);
    ok $res->is_success, "GET /rules/login is success";

    cmp_deeply decode_json($res->content),
      {
        options => {
            stripwhite          => 1,
            collapse_whitespace => 1,
            requireall          => 1,
            unknown             => "fail",
        },
        prepare => {
            email => {
                validator => "String",
            },
            foo => {
                validator => "Foo",
            },
            password => {
                validator => {
                    class   => "PasswordPolicy",
                    options => {
                        disabled => {
                            username => 1,
                        },
                    },
                },
            },
        }
      },
      "... and the returned rules are as expected"
          or diag explain $res->content;

    $req = POST "$uri/foo_as_string",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "Validate some good data with foo as String" );

    cmp_deeply decode_json( $res->content ),
      {
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        },
        valid => 1
      },
      "... and validation passed with all data returned as expected";

    $req = POST "$uri/foo_as_email_valid",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success,
        "Validate some bad data with simple string foo as EmailValid" );

    cmp_deeply decode_json( $res->content ),
      {
        css    => { foo => ignore() },
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        },
        valid  => 0,
        errors => { foo => ignore() },
      },
      "... and validation failed with all data returned as expected";

    $req = POST "$uri/hashref",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "Validate some bad data against hash-based rules" );

    cmp_deeply decode_json( $res->content ),
      {
        css    => { foo => ignore() },
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        },
        valid  => 0,
        errors => { foo => ignore() },
      },
      "... and validation failed with all data returned as expected";

    $req = POST "$uri/coderef",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success,
        "Validate some bad data against coderef-based rules" );

    cmp_deeply decode_json( $res->content ),
      {
        css    => { foo => ignore() },
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        },
        valid  => 0,
        errors => { foo => ignore() },
      },
      "... and validation failed with all data returned as expected";

    $trap->read;
    $req = POST "$uri/arrayref",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( !$res->is_success,
        "Validate some bad data against arrayref-based rules FAILS" );
    is $res->code, 500, "... with a 500 response code";

    cmp_deeply $trap->read,
      [
        superhashof(
            {
                level   => "error",
                message => re(qr/rules option reference type ARRAY not allowed/)
            }
        )
      ],
      "... and we got error message showing bad ARRAY."
};

$test = Plack::Test->create( TestAppNoErrorsJoined->to_app );

subtest 'TestAppNoErrorsJoined /joined' => sub {

    # errors_hash is joined
    $req = POST "$uri/joined", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/.+\..+\..+/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

$test = Plack::Test->create( TestAppNoErrorsArrayRef->to_app );

subtest 'TestAppNoErrorsArrayRef /arrayref' => sub {

    # errors_hash is arrayref
    $req = POST "$uri/arrayref", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => bag("Missing required field email"),
            password => supersetof( re(qr/\w/), re(qr/\w/) ),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
    $data = $data->{errors}->{password};
    cmp_ok( ref($data), 'eq', 'ARRAY', "error value is an array reference" );
};

$test = Plack::Test->create( TestAppCssErrorClass->to_app );

subtest 'TestAppCssErrorClass /css-foo' => sub {

    # css_error_class is 'foo'
    $req = POST "$uri/css-foo", [ foo => " bar ", password => "bad  pwd" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo and bad password" );

    $expected = {
        css => {
            email    => "foo",
            password => "foo"
        },
        errors => {
            email    => "Missing required field email",
            password => re(qr/\w/),
        },
        valid  => 0,
        values => {
            foo      => "bar",
            password => "bad pwd",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

$test = Plack::Test->create( TestAppBadRulesDir->to_app );

subtest 'TestAppBadRulesDir /bad_rules_dir' => sub {

    # rules_dir is foo
    $req = POST "$uri/bad_rules_dir", [ foo => "bar" ];
    $res = $test->request($req);
    cmp_ok( $res->code, 'eq', '500', "testing rules_dir => foo" );
};

$test = Plack::Test->create( TestAppGoodRulesDir->to_app );

subtest 'TestAppGoodRulesDir /good_rules_dir' => sub {

    # rules_dir is validation
    $req = POST "$uri/good_rules_dir", [ foo => "bar" ];
    $res = $test->request($req);
    ok( $res->is_success, "rules_dir is good" );

    $expected = {
        css => {
            email    => "has-error",
            password => "has-error"
        },
        errors => {
            email    => "Missing required field email",
            password => "Missing required field password"
        },
        valid  => 0,
        values => {
            foo => "bar",
        }
    };
    $data = decode_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

done_testing;
