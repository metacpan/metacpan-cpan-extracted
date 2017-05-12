#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    eval {
        require Plucene;    
        require Plucene::Plugin::Analyzer::SnowballAnalyzer;
    };
    plan $@
        ? ( skip_all => 'needs Plucene and Plucene::Plugin::Analyzer::SnowballAnalyzer for testing' )
        : ( tests => 5 );
}

# remove previous index
rmtree 't/var' if -d 't/var';

use Catalyst::Test 'TestApp';

# change the analyzer
TestApp::M::Search::Plucene->analyzer(
    'Plucene::Plugin::Analyzer::SnowballAnalyzer'
);

# add an item and get it back out a few different ways
# Snowball allows indexing things like numbers, so test with an IP address
ok( my $res = request('http://localhost/plucene/add/key1?text=192.168.1.1&author=agrundma') );
ok( $res = request('http://localhost/plucene/is_indexed/key1') );
is( $res->content, 1, 'document is indexed' );
ok( $res = request('http://localhost/plucene/query_items?q=192.168*') );
like( $res->content, qr/key=key1/, 'search query ok' );
