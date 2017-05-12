
use warnings;
use strict;

use lib qw( t );
use Test::More;

$ENV{CGI_APP_RETURN_ONLY} = 1;

## only run tests on newer CGI:Session versions
plan tests => 2;

## need for the tests
use CGI;
use TestAppSessionCookieName;

{
    my $t1_obj = TestAppSessionCookieName->new( QUERY => CGI->new );
    my $t1_out = $t1_obj->run;

    like $t1_out, qr/session:/, 'session in output';
    like $t1_out, qr/Set-Cookie: foobar=[a-zA-Z0-9]+/, 'session cookie with custom name';
}
