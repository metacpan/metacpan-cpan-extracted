# $Id$

use strict;


# Test CGI::Simple support in CGI::Session
use Test::More;

if ( eval {  require CGI::Simple }  ) {
    plan qw/no_plan/;
}
else {
    plan skip_all => 'CGI::Simple not installed, so skipping related tests.';
}

use CGI::Session;
my $q = CGI::Simple->new('sid=bob');
my $s;
eval { $s = CGI::Session->new($q); };
is($@,'', "survives eval");

ok( $s->id(), 'CGI::Simple object is accepted when passed to new()' );

like( $s->cookie(), qr/CGISES/i, "cookie() method works with CGI::Simple");
like( $s->http_header(), qr/Content-Type/i, "http_header() method works with CGI::Simple");

$s->delete();
