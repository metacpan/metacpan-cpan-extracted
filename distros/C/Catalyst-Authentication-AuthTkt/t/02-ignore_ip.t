#!/usr/bin/env/perl
use strict;
use Test::More tests => 21;

BEGIN {
    $ENV{MYAPP_CONFIG} = 't/MyApp/myapp_ignore_ip.conf';
}

use lib 't/MyApp/lib';
use Catalyst::Test 'MyApp';
use HTTP::Request::Common;
use Data::Dump qw( dump );
use Config::General;
use Apache::AuthTkt;
use HTTP::Request::AsCGI;
use HTTP::Cookies;

my $class = 'MyApp';

# based on Catalyst::Test local_request() but
# hack in session cookie support.
my $scookie;

sub my_request {
    my $uri = shift or die "uri required";
    my $request = Catalyst::Utils::request($uri);
    if ($scookie) {
        $request->header( 'Cookie', $scookie );
    }
    my $response = request($request);
    if ( !$scookie && $response->header('Set-Cookie') ) {
        $scookie = $response->header('Set-Cookie');
        $scookie =~ s/;.*//;
    }
    return $response;
}

# cribbed from Test::HTTP::Response
sub extract_cookies {
    my $response = shift;
    my %cookies;
    my $cookie_jar = HTTP::Cookies->new();
    $cookie_jar->extract_cookies($response);
    $cookie_jar->scan(
        sub {
            my %cookie = ();
            @cookie{
                qw(version key value path domain port path domain port path_spec secure expires discard hash)
            } = @_;
            $cookies{ $cookie{key} } = \%cookie;
        }
    );

    return \%cookies;
}

ok( my $conf = Config::General->new("t/MyApp/myapp.conf"),
    "get config via file" );
ok( my %config = $conf->getall, "parse config file" );

#dump \%config;

my $store  = $config{'Plugin::Authentication'}->{realms}->{authtkt}->{store};
my $secret = $store->{secret};
my $cookie_name = $store->{cookie_name};

my $res;
ok( $res = my_request('/'), "get /" );
is( $res->headers->{status}, 302, "req redirects without auth tkt" );
is( $res->headers->{location},
    $config{'Controller::Root'}->{auth_url},
    "auth url"
);

#diag( dump $res );

ok( my $AAT = Apache::AuthTkt->new( secret => $secret, ), "new AAT" );
ok( my $auth_ticket = $AAT->ticket(
        uid     => 'catalyst-tester',
        ip_addr => '0.0.0.0',
        tokens  => 'group1,group2',
        data    => 'foo bar baz'
    ),
    "new auth_tkt"
);

ok( $res = my_request("/?$cookie_name=$auth_ticket"), "get / with auth_tkt" );
is( $res->content,
    'Logged in as user catalyst-tester with roles ("group1", "group2")',
    "logged in" );

# request again with no cookie or tkt set
# to test session persistence
ok( $res = my_request( '/', $scookie ), "get / with no auth_tkt" );
is( $res->headers->{status}, 302, "req redirects without auth tkt" );
is( $res->headers->{location},
    $config{'Controller::Root'}->{auth_url},
    "auth url"
);

#dump $res;

# test renewal
ok( my $stale_tkt = $AAT->ticket(
        uid     => 'catalyst-tester',
        ts      => time() - 7201,      # in the past beyond the timeout period
        ip_addr => '0.0.0.0',
    ),
    "create stale ticket"
);
ok( $res = my_request("/?$cookie_name=$stale_tkt"), "get / with stale_tkt" );

#diag( dump $res );
is( $res->headers->{status}, 302, "stale ticket redirects" );
ok( my $used_tkt = $AAT->ticket(
        uid     => 'catalyst-tester',
        ts      => time() - 7000,       # in the past but before timeout
        ip_addr => '0.0.0.0',
    ),
    "create used ticket"
);
ok( $res = my_request("/?$cookie_name=$used_tkt"), "get / with used_tkt" );
like $res->content, qr/Logged in as user catalyst-tester with roles/;

#diag( dump $res );
ok( my $cookies = extract_cookies($res), "extract cookies" );

#diag( dump $cookies );
ok( $cookies->{$cookie_name}, "$cookie_name in response" );
isnt( $used_tkt, $cookies->{$cookie_name}, "$cookie_name value changed" );
