use strict;
use warnings;
use Test::More 0.96 import => ['!pass']; # subtests

use YAML;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use lib 't/lib';
use TestApp;

my $secret_key = "handbag imitation doublet sickout"; # Crypt::Diceware :-)

my $engine = "Cookie";

my @configs = (
    {
        label  => "default",
        config => { secret_key => $secret_key, },
    },
    {
        label  => "with default_duration",
        config => {
            secret_key       => $secret_key,
            default_duration => 86400 * 7,
        },
    },
    {
        label  => "with cookie_duration",
        config => {
            secret_key      => $secret_key,
            cookie_duration => 3600,
        },
    },
    {
        label  => "forced_expire",
        config => {
            secret_key       => $secret_key,
            default_duration => -100,
        },
    },
);

for my $c (@configs) {
    my ( $label, $config ) = @{$c}{qw/label config/};

    {
        package TestAppConfig;
        use Dancer2 appname => 'TestApp';

        setting( engines => { session => { $engine => $config } } );
        setting( session => $engine );

    }

    subtest $label => sub {

        my $url  = 'http://localhost';
        my $jar  = HTTP::Cookies->new();
        my $test = Plack::Test->create( TestApp->to_app );
        my ( $req, $res );

        # no session cookie set if session not referenced
        $res = $test->request( GET "$url/no_session_data" );
        ok $res->is_success, "/no_session_data"
          or diag explain $res;
        $jar->extract_cookies($res);
        is $jar->as_string, "", "no cookie set"
          or diag explain $jar;

        # recent Dancer: no session created until session is written
        $res = $test->request( GET "$url/read_session" );
        ok $res->is_success, "/read_session";
        $jar->extract_cookies($res);
        is $jar->as_string, "", "no cookie set"
          or diag explain $jar;

        # set value into session
        $res = $test->request( GET "$url/set_session/larry" );
        ok $res->is_success, "/set_session/larry";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;
        my $sid1;
        $jar->scan( sub { $sid1 = $_[2] } );
        ok( $sid1, "Got SID from cookie: $sid1" );

        # read value back
        $req = GET "$url/read_session";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/read_session";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;

        if ( $c->{label} eq 'forced_expire' ) {
            like $res->content, qr/name=''/, "session value reset";
        }
        else {
            like $res->content, qr/name='larry'/, "session value looks good";
        }

        # session cookie should persist even if we don't touch sessions
        $req = GET "$url/no_session_data";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/no_session_data";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;

        # change_session_id is a noop with this session engine but test
        # all the same
        {
            my ( $sid1, $sid2 );
            $req = GET "$url/no_session_data";
            $jar->add_cookie_header($req);
            $res = $test->request($req);
            ok $res->is_success, "/no_session_data";
            $jar->extract_cookies($res);
            $jar->scan( sub { $sid1 = $_[2] } );
            ok( $sid1, "Got SID from cookie: $sid1" );

            $req = GET "$url/change_session_id";
            $jar->add_cookie_header($req);
            $res = $test->request($req);
            ok $res->is_success, "/change_session_id";
            $jar->extract_cookies($res);
            $jar->scan( sub { $sid2 = $_[2] } );
            ok( $sid2, "Got SID from cookie: $sid2" );

            isnt $sid1, $sid2, "session id has changed";
            diag $res->content;
        }

        # destroy session and check that cookies expiration is set
        $req = GET "$url/destroy_session";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/destroy_session";
        $jar->extract_cookies($res);
        is $jar->as_string, "", "session cookie is expired"
          or diag explain $jar;

        # shouldn't be sent session cookie after session destruction
        $req = GET "$url/no_session_data";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/no_session_data";
        $jar->extract_cookies($res);
        is $jar->as_string, "", "no cookie set"
          or diag explain $jar;

        # set value into session again
        $req = GET "$url/set_session/curly";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/set_session/curly";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;
        my $sid2;
        $jar->scan( sub { $sid2 = $_[2] } );
        ok( $sid2, "Got SID from cookie: $sid2" );
        isnt( $sid2, $sid1, "changing data changes session ID" )
          or diag explain $jar;

        # destroy and create a session in one request
        $req = GET "$url/churn_session";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/churn_session";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;

        # read value back
        $req = GET "$url/read_session";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/read_session";
        $jar->extract_cookies($res);
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;
        if ( $c->{label} eq 'forced_expire' ) {
            like $res->content, qr/name=''/, "session value reset";
        }
        else {
            like $res->content, qr/name='damian'/, "session value looks good";
        }

        # try to manipulate cookie
        my @cookie;
        $jar->scan( sub { @cookie = @_ } );
        $cookie[2] =~ s/~\d*~/"~" . (time + 100) . "~"/e;
        ok($jar->set_cookie(@cookie), "Set bad cookie value");
        $req = GET "$url/read_session";
        $jar->add_cookie_header($req);
        $res = $test->request($req);
        ok $res->is_success, "/read_session";
        isnt $jar->as_string, "", "session cookie set"
          or diag explain $jar;
        like $res->content, qr/name=''/, "session reset after bad MAC";
    };
}

done_testing;
