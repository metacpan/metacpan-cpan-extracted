#!perl
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::Deep;
use Test::Exception;

use Class::Load qw/try_load_class/;
use File::Spec;
use HTTP::Request::Common;
use JSON qw//;
use Plack::Builder;
use Plack::Test;

sub BEGIN {
    try_load_class('Dancer')
      or plan skip_all => "Dancer required to run these tests";
}

sub from_json {
    return JSON::from_json(shift);
}

{
    my ( $data, $expected, $req, $res );

    my $app = sub {
        use Dancer;
        use Dancer::Plugin::DataTransposeValidator;

        set appdir => File::Spec->catdir( 't', 'appdir' );

        get '/' => sub {
            return "home";
        };

        post '/default' => sub {
            my $params = params;
            my $data = validator( $params, 'rules1' );
            content_type('application/json');
            return to_json($data);
        };

        post '/joined' => sub {
            set plugins => {
                DataTransposeValidator => {
                    errors_hash => "joined"
                }
            };
            my $params = params;
            my $data = validator( $params, 'rules1' );
            content_type('application/json');
            return to_json($data);
        };

        post '/arrayref' => sub {
            set plugins => {
                DataTransposeValidator => {
                    errors_hash => "arrayref"
                }
            };
            my $params = params;
            my $data = validator( $params, 'rules1' );
            content_type('application/json');
            return to_json($data);
        };

        post '/css-foo' => sub {
            set plugins => {
                DataTransposeValidator => {
                    css_error_class => "foo"
                }
            };
            my $params = params;
            my $data = validator( $params, 'rules1' );
            content_type('application/json');
            return to_json($data);
        };

        post '/bad_rules_dir' => sub {
            set plugins => {
                DataTransposeValidator => {
                    rules_dir => "foo"
                }
            };
            my $params = params;
            my $data = validator( $params, 'rules1' );
            content_type('application/json');
            return to_json($data);
        };

        post '/good_rules_dir' => sub {
            set plugins => {
                DataTransposeValidator => {
                    rules_dir => "validation"
                }
            };
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

        my $env = shift;
        my $request = Dancer::Request->new( env => $env );
        Dancer->dance($request);
    };

    my $test = Plack::Test->create($app);
    my $uri  = "http://localhost";

    # simple test to make sure nothing scary is happening
    $req = GET "$uri/";
    $res = $test->request($req);
    ok( $res->is_success, "get / OK" );
    like( $res->content, qr/home/, "Content contains home" );

    # errors_hash is false
    $req = POST "$uri/default", [ foo => "bar" ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" );

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;
    $data = $data->{errors}->{password};
    cmp_ok( ref($data), 'eq', 'ARRAY', "error value is an array reference" );

    # rules_dir is foo
    $req = POST "$uri/bad_rules_dir", [ foo => "bar" ];
    $res = $test->request($req);
    cmp_ok( $res->code, 'eq', '500', "testing rules_dir => foo" );

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

    # all valid
    $req = POST "$uri/default",
      [
        foo      => "bar",
        email    => 'user@example.com',
        password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
      ];
    $res = $test->request($req);
    ok( $res->is_success, "post good foo" ) or diag $res->content;

    $expected = {
        valid  => 1,
        values => {
            foo      => "bar",
            email    => 'user@example.com',
            password => 'cA$(!n6K)Y.zoKoqayL}$O6EY}Q+g',
        }
    };
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" ) or diag explain $data;

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
    $data = from_json( $res->content );
    cmp_deeply( $data, $expected, "good result" );
};

done_testing;
