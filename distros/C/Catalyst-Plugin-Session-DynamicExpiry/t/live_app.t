#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 16;
}

use lib "t/lib";

use Test::WWW::Mechanize::Catalyst qw/DynamicExpiryApp/;

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok("http://localhost/foo/counter");
$m->content_is( 1, "counter worked" );

$m->get_ok("http://localhost/foo/counter");
$m->content_is( 2, "counter worked" );

my $num_cookies = 0;
my $cookie_expires;

$m->cookie_jar->scan( sub {
    $num_cookies++;
    my ( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash ) = @_;
    $cookie_expires = $expires;
});

is( $num_cookies, 1, "one cookie" );
ok( defined($cookie_expires), "expiry time defined" );

$m->get_ok("http://localhost/foo/remember_me");
$m->content_is( 3, "counter worked" );

$num_cookies = 0;
my $long_cookie_expires;

$m->cookie_jar->scan( sub {
    $num_cookies++;
    my ( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash ) = @_;
    $long_cookie_expires = $expires;
});

is( $num_cookies, 1, "one cookie" );
ok( defined($long_cookie_expires), "expiry time defined" );

cmp_ok(
    ($long_cookie_expires - $cookie_expires),
    ">",
    60 * 60 * 24 * 360,
    "the difference between the expiry times is big",
);

$m->get_ok("http://localhost/foo/counter");
$m->content_is( 4, "counter worked" );

$num_cookies = 0;

$m->cookie_jar->scan( sub {
    $num_cookies++;
    my ( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash ) = @_;
    $long_cookie_expires = $expires;
});

is( $num_cookies, 1, "one cookie" );
ok( defined($long_cookie_expires), "expiry time defined" );

cmp_ok(
    ($long_cookie_expires - $cookie_expires),
    ">",
    60 * 60 * 24 * 360,
    "the difference between the expiry times is still big",
);

