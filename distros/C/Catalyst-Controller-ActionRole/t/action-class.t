use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

{
    my $resp = request( "/actionclass/one" );
    ok( $resp->is_success );
    is( $resp->content, 'Catalyst::Action::TestActionClass' );
}

{
    my $resp = request("/boo/foo");
    ok( $resp->is_success );
    is( $resp->content, 'hello' );
}

done_testing;
