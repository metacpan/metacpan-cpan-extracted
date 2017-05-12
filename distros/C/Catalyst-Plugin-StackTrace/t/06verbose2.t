#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

plan tests => 3;
use Catalyst::Test 'TestApp';

# configure verbose level 2
TestApp->config->{stacktrace}->{verbose} = 2;

open STDERR, '>/dev/null';

# test that a crashed action prints the appropriate debug screen
{
    ok( my $res = request('http://localhost/foo/not_ok'), 'request ok' );
    like( $res->content, qr{Test.pm}, 'verbose ok' );
    like( $res->content, qr{NEXT}, 'verbose level 2 ok' );
}

