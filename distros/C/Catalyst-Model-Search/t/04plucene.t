#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    eval "use Plucene";
    plan $@
        ? ( skip_all => 'needs Plucene for testing' )
        : ( tests => 21 );
}

# remove previous index
rmtree 't/var' if -d 't/var';

use Catalyst::Test 'TestApp';

# add an item and get it back out a few different ways
ok( my $res = request('http://localhost/plucene/add/key1?text=Andy&author=agrundma') );
ok( $res = request('http://localhost/plucene/is_indexed/key1') );
is( $res->content, 1, 'document is indexed' );
ok( $res = request('http://localhost/plucene/query_total_hits?q=Andy') );
is( $res->content, '1', 'get_total_hits ok' );
ok( $res = request('http://localhost/plucene/query_items?q=Andy') );
like( $res->content, qr/key=key1/, 'get_items key mode ok' );
ok( $res = request('http://localhost/plucene/query_items?q=author:agrundma') );
like( $res->content, qr/key=key1/, 'search query 2 ok' );

# make sure key mode doesn't return any data
ok( $res = request('http://localhost/plucene/query_data?q=Andy') );
unlike( $res->content, qr/author=agrundma/, 'get_items key mode did not return author' );

# test full data mode
TestApp::M::Search::Plucene->config->{return_style} = 'full';
TestApp::M::Search::Plucene->init();

ok( $res = request('http://localhost/plucene/add/full?text=fulltest&author=draven') );
ok( $res = request('http://localhost/plucene/is_indexed/full') );
is( $res->content, 1, 'document is indexed' );
ok( $res = request('http://localhost/plucene/query_total_hits?q=draven') );
is( $res->content, '1', 'get_total_hits ok' );
ok( $res = request('http://localhost/plucene/query_data?q=draven') );
like( $res->content, qr/text=fulltest/, 'full search query data ok' );
like( $res->content, qr/author=draven/, 'full search query data ok' );

# test optimize
ok( $res = request('http://localhost/plucene/optimize') );
is( $res->content, 'ok', 'optimize ok' );

