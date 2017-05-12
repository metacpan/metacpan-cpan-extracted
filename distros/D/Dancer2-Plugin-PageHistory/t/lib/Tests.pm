package Tests;

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Dancer2::Plugin::PageHistory::PageSet;
use File::Path;
use HTTP::Cookies;
use HTTP::Request::Common;
use JSON::MaybeXS;
use Plack::Builder;
use Plack::Test;
use TestApp;

my ( $app, $jar, $test );

sub get_history {
    my $uri = shift;
    my $req = GET "http://localhost$uri";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    ok( $res->is_success, "get $uri OK" );
    $jar->extract_cookies($res);
    return Dancer2::Plugin::PageHistory::PageSet->new(
        pages => decode_json( $res->content ) );
}

sub run_tests {
    my ( $req, $res, $history );

    my $settings = shift;
    {
        use Dancer2 appname => 'TestApp';
        foreach my $key ( keys %$settings ) {
            set $key => $settings->{$key};
        }
    }

    $app = TestApp->to_app;
    ok ref($app) eq 'CODE', "Got an app";

    $jar  = HTTP::Cookies->new;

    if ( $settings->{session} && $settings->{session} eq 'PSGI' ) {
        $test = Plack::Test->create(
            builder {
                enable "Session::Cookie", secret => 'only.for.testing';
                $app
            }
        );
    }
    else {
        $test = Plack::Test->create($app);
    }

    $jar->clear;

    my $uri = "http://localhost";

    $req = GET "$uri/session/class", "X-Requested-With" => "XMLHttpRequest";
    $res = $test->request($req);
    ok( $res->is_success, "get /session/class OK" );
    $jar->extract_cookies($res);
    is $res->content, 'Dancer2::Core::Session', "class is good";

    $history = get_history('/one');
    cmp_ok( keys %{ $history->pages },  '==', 1,      "1 key in pages" );
    cmp_ok( @{ $history->default },     '==', 1,      "1 page type default" );
    cmp_ok( $history->latest_page->uri, "eq", "/one", "latest_page OK" );
    ok( !defined $history->previous_page, "previous_page undef" );

    $history = get_history('/two');
    cmp_ok( keys %{ $history->pages },  '==', 1,      "1 key in pages" );
    cmp_ok( @{ $history->default },     '==', 2,      "2 pages type default" );
    cmp_ok( $history->latest_page->uri, "eq", "/two", "latest_page OK" );
    cmp_ok( $history->previous_page->uri, "eq", "/one", "previous_page OK" );

    $history = get_history('/product/three');
    cmp_ok( keys %{ $history->pages }, '==', 2, "2 key in pages" );
    cmp_ok( @{ $history->default },    '==', 3, "3 pages type default" );
    cmp_ok( @{ $history->product },    '==', 1, "1 page type product" );
    cmp_ok( $history->latest_page->uri,
        "eq", "/product/three", "latest_page OK" );
    cmp_ok( $history->previous_page->uri, "eq", "/two", "previous_page OK" );

    $history = get_history('/four');
    cmp_ok( keys %{ $history->pages },  '==', 2,       "2 keys in pages" );
    cmp_ok( @{ $history->default },     '==', 3,       "3 pages type default" );
    cmp_ok( @{ $history->product },     '==', 1,       "1 page type product" );
    cmp_ok( $history->latest_page->uri, "eq", "/four", "latest_page OK" );
    cmp_ok( $history->previous_page->uri,
        "eq", "/product/three", "previous_page OK" );

    $req = GET "$uri/session/destroy", "X-Requested-With" => "XMLHttpRequest";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok( $res->is_success, "get /session/destroy OK" );

    $history = get_history('/one');
    cmp_ok( $history->latest_page->uri, "eq", "/one", "latest_page OK" );

    File::Path::rmtree('sessions');
}

1;
