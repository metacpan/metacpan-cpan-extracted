use strict;
use warnings;
use Test::More tests => 9;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'Test::WWW::Mechanize::Catalyst', 'MyApp' }

my $base = 'http://localhost';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->{catalyst_debug} = 1;

# test setting the cookie
$mech->get_ok("$base/this/is/not/public/someuser");
$mech->content_contains('Cookie set');

my $debug_header = get_debug_header();
is($debug_header, 0, "debug is turned off initially");

my $cookie_header = get_cookie_header(); 
like($cookie_header, qr/debug_cookie/, "found cookie_debug cookie in header");

# set an invalid username and make sure debug is still off
$mech->get_ok("$base/?is_debug=someuser2");

$debug_header = get_debug_header();
is($debug_header, 0, "debug is still off");

# set the valid username and make sure debug is turned on
$mech->get_ok("$base/?is_debug=someuser");

$debug_header = get_debug_header();
is($debug_header, 1, "debug is turned on");



sub get_debug_header {
	my $response = $mech->response;
	return $response->header('X-Catalyst-Debug');
}

sub get_cookie_header {
	my $response = $mech->response;
	return $response->header('Set-Cookie');
}




1;
