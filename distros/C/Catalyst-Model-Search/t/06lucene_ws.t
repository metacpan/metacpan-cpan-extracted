#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    
    eval "use Net::LuceneWS";
    plan $@
        ? (  skip_all => 'needs Net::LuceneWS for testing' )
        : ( $ENV{LOCAL_LUCENE_SERVER } ? ( tests => 24 ) : (skip_all => "Requires a local lucene server. set LOCAL_LUCENE_SERVER to force." ))
}

use Catalyst::Test 'TestApp';

# remove previous keys
ok( my $res = request('http://localhost/lucene_ws/remove/key1') );
is( $res->content, 'ok', 'removed key1' );
ok( $res = request('http://localhost/lucene_ws/remove/full') );
is( $res->content, 'ok', 'removed full' );

# add an item and get it back out a few different ways
ok( $res = request('http://localhost/lucene_ws/add/key1?text=Andy&author=agrundma') );
is( $res->content, 'ok', 'document added ok' );
ok( $res = request('http://localhost/lucene_ws/is_indexed/key1') );
is( $res->content, 1, 'document is indexed' );
ok( $res = request('http://localhost/lucene_ws/query_total_hits?q=Andy') );
is( $res->content, '1', 'get_total_hits ok' );
ok( $res = request('http://localhost/lucene_ws/query_items?q=Andy') );
like( $res->content, qr/key=key1/, 'get_items key ok' );
ok( $res = request('http://localhost/lucene_ws/query_items?q=author:agrundma') );
like( $res->content, qr/key=key1/, 'search query 2 ok' );

ok( $res = request('http://localhost/lucene_ws/add/full?text=fulltest&author=draven') );
ok( $res = request('http://localhost/lucene_ws/is_indexed/full') );
is( $res->content, 1, 'document is indexed' );
ok( $res = request('http://localhost/lucene_ws/query_total_hits?q=draven') );
is( $res->content, '1', 'get_total_hits ok' );
ok( $res = request('http://localhost/lucene_ws/query_data?q=draven') );
like( $res->content, qr/text=fulltest/, 'full search query data ok' );
like( $res->content, qr/author=draven/, 'full search query data ok' );

# test optimize
SKIP: {
    skip "optimize appears to hang my Lucene instance", 2;
    ok( $res = request('http://localhost/lucene_ws/optimize') );
    is( $res->content, 'ok', 'optimize ok' );
}




