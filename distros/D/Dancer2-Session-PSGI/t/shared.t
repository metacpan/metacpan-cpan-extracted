use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];    # subtests

use Plack::Builder;
use Plack::Test;

use HTTP::Request::Common;
use HTTP::Cookies;

##
## Sharing with another app with non-default session key.

## A simple Dancer2 app
{
    # Force PSGI server for Dancer2
    BEGIN { $ENV{DANCER_APPHANDLER} = 'PSGI' }
    use Dancer2;

    setting(
        engines => {
            session => {
                PSGI => {
                    cookie_name => 'some.thing',
                }
            }
        }
    );
    setting( session => 'PSGI' );

    get '/' => sub {
        my $count = session("counter");
        session "counter" => ++$count;
        return "This is my ${count}th dance";
    };
}

my $app = make_test_app( dance() );

## Another (simple) PSGI app
my $app1 = make_test_app(
    sub {
        my $session = (shift)->{'psgix.session'};
        return [
            200,
            [ 'Content-Type' => 'text/plain' ],
            [
                "Hello, you've been here for ",
                ++$session->{counter},
                "th time!"
            ],
        ];
    }
);

## Tests

# GET / to each app a few times
my $counter = 1;
for my $i ( 1 .. 3 ) {
    my $res = make_request($app);
    like $res->content, qr/${counter}th dance/, "request " . $counter++;

    my $res1 = make_request($app1);
    like $res1->content, qr/${counter}th time/, "request " . $counter++;
}

done_testing;

## Helper subs

# Helper to generate test apps wrapped apps with Middleware::Session
sub make_test_app {
    my $app = shift;
    return Plack::Test->create(
        builder {
            enable "Session::Cookie",
                secret => 'only.for.testing',
                session_key => "some.thing";
            $app;
        }
    );
}

my $jar;

sub make_request {
    my $app = shift;
    $jar ||= HTTP::Cookies->new;
    my $req = GET "http://localhost/";
    $jar->add_cookie_header($req);
    my $res = $app->request($req);
    $jar->extract_cookies($res);
    return $res;
}
