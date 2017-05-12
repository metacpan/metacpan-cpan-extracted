
use strict;
use lib("t/lib");
use Test::More tests => 4;
use Catalyst::Test 'TestApp';

my $res;

{
    $res = request('/load');
    ok( $res->is_success, "request is success" );
    like( $res->content, qr/today: OK/, 'dynamic value ok');
}

SKIP: {
    if ( (! eval "require Catalyst::Plugin::Cache" || ! eval "require Cache::Memory" )|| $@) {

        skip "Catalyst::Plugin::Cache and/or Cache::Memory not available", 2;
    }

    # request again, make sure that the cached instance is being used
    $res = request('/load');
    ok( $res->is_success, "request is success" );
    like( $res->content, qr/today: OK/, 'dynamic value ok');
}
