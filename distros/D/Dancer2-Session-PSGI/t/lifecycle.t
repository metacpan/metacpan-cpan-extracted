use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];    # subtests

use Plack::Builder;
use Plack::Test;
use Plack::Middleware::Session;
use Plack::Session::Store;

use HTTP::Request::Common;
use HTTP::Cookies;

## Dancer2 app
{
    # Force PSGI server for Dancer2
    BEGIN { $ENV{DANCER_APPHANDLER} = 'PSGI' }
    use Dancer2;

    setting( session => 'PSGI' );

    get '/set/*' => sub {
        my ($thing) = splat;
        session thing => $thing;
    };

    get '/get' => sub {
        return session('thing');
    };

    get '/change_session_id' => sub {
        if ( app->can('change_session_id') ) {
            # Dancer2 > 0.200003
            app->change_session_id;
        }
        else {
            return "unsupported";
        }
    };

    get '/delete' => sub {
        app->destroy_session;
        return 'destroyed';
    };

    get '/expires' => sub {
        session->expires(10);
        return session->expires;
    };
}

## Fixtures: A cookie jar and the Plack::Test wrapped app.
my $jar = HTTP::Cookies->new;
my $app ||= Plack::Test->create(
    builder {
        #enable "Session::Cookie", secret => 'only.for.testing';
        enable 'Session';
        dance();
    }
);

## Tests

my $sid1;
subtest 'Basic session set then retrieve' => sub {
    my $string = "boooorrrring";
    get_request("/set/$string");
    my $res = get_request('/get');
    is $res->content, $string, "Retrieved content back from session";

    # extract SID
    $jar->scan( sub { $sid1 = $_[2] } );
    ok( $sid1, "Got SID from cookie: $sid1" );
};

my $sid2;
subtest "Change session ID" => sub {
    my $res = get_request("/change_session_id");

    SKIP: {
        # Dancer2 > 0.200003
        skip "This Dancer2 version does not support change_session_id", 2
          if $res->content eq "unsupported";

        # extract SID
        $jar->scan( sub { $sid2 = $_[2] } );
        ok( $sid2, "Got SID from cookie: $sid2" );

        isnt $sid2, $sid1, "New session has different ID";
    }
};

subtest 'session destruction' => sub {
    my $res = get_request('/delete');
    is $jar->as_string, '', "destroying session expired cookie";
};

subtest 'modify cookie expiry' => sub {
    get_request("/set/expires");
    my $res = get_request('/get');
    unlike $jar->as_string, qr/expires/, "session cookie";
    $res = get_request('/expires');
    like $jar->as_string, qr/expires/, "cookie now has expiry";
};

done_testing();

## Helper subs

sub get_request {
    my $path = shift;

    my $req = HTTP::Request->new( 'GET' => "http://localhost$path" );
    $jar->add_cookie_header($req);
    my $res = $app->request($req);
    $jar->clear;
    $jar->extract_cookies($res);

    return $res;
}

__END__

# GET /no_session and verify no session was created

$req = GET "http://localhost/delete";
$jar->add_cookie_header($req);
$res = $app->request($req);
$jar->extract_cookies($res);

is $jar->as_string, '';

$req = GET "http://localhost/churn/bar";
$jar->add_cookie_header($req);
$res = $app->request($req);
$jar->extract_cookies($res);

diag $jar->as_string;

$req = GET "http://localhost/churn/baz";
$jar->add_cookie_header($req);
$res = $app->request($req);
$jar->extract_cookies($res);

diag $jar->as_string;

