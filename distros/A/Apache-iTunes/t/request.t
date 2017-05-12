use strict;

BEGIN {
    $ENV{APACHE_ITUNES_HTML} ||= 'html/iTunes.html';
    $ENV{APACHE_ITUNES_URL}  ||= '/iTunes/';
    $ENV{APACHE_ITUNES}        = 1;
	}

use Test::More tests => 2;

use Apache::Constants qw(:common);
use Apache::FakeRequest;
use Apache::iTunes;

my $request = Apache::FakeRequest->new();
isa_ok( $request, 'Apache::FakeRequest' );

my $status = Apache::iTunes::handler( $request ); 
is( $status, OK, "Returns OK status" );
