#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 2;
use Catalyst::Test 'TestApp';

SKIP:
{
    unless ( TestApp->isa('Catalyst::Plugin::SubRequest') ) {
        skip "Install Catalyst::Plugin::SubRequest >= 0.15 for these tests", 2;
    }
    unless ( $Catalyst::Plugin::SubRequest::VERSION >= 0.15 ) {
        skip "Need Catalyst::Plugin::SubRequest >= 0.15 for these tests", 2;
    }

    ok( my $res = request('http://localhost/subtest'), 'Request' );
    is( $res->content, 'subtest2 ok', 'SubRequest ok' );
}

