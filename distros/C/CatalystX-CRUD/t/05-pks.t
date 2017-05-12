use strict;
use warnings;
use Test::More tests => 2;
use lib qw( lib t/lib );
use Catalyst::Test 'MyApp';
use Data::Dump qw( dump );
use HTTP::Request::Common;

my $res;
ok( $res = request(
        HTTP::Request->new( GET => '/fileadaptermultipk/testfile;;/read' )
    ),
    "GET new file with null pk"
);

is( $res->code, 404, "no such file returns 404" );
