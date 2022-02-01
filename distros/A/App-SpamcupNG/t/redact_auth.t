use warnings;
use strict;
use Test::More tests=> 2;
use HTTP::Request;

use App::SpamcupNG;

can_ok( 'App::SpamcupNG', qw(_redact_auth_req) );

my $req = HTTP::Request->new( GET => 'http://members.spamcop.net/' );
$req->authorization_basic( 'foobar', '12345678910' );
my $expected = 'GET http://members.spamcop.net/' . "\n"
    . 'Authorization: Basic ************************';
is( App::SpamcupNG::_redact_auth_req($req),
    $expected, '_redact_auth_req works' );

# vim: filetype=perl

