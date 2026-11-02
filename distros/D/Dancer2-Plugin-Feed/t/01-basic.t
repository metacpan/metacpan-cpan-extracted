use strict;
use warnings;

use Test::More tests => 77;

use lib 't/lib';
use XML::Feed;
use TestApp;

use Dancer2;
use Plack::Test;
use HTTP::Request::Common;

my $psgi = Plack::Test->create( Dancer2->runner->psgi_app );
my ( $res, $feed );

$res = $psgi->request( GET '/feed' );
is( $res->code, 500, "response for GET /feed is 500" );

$res = $psgi->request( GET '/feed/gibberish' );
is( $res->code, 500, "response for GET /feed/gibberish is 500" );

for my $format (qw/atom rss/) {
    for my $route ( "/feed/$format", "/other/feed/$format" ) {
        ok( $res = $psgi->request( GET $route ) );
        is( $res->code, 200, "$format - $route" );
        is( $res->header('Content-Type'), "application/$format+xml" );
        ok( $feed = XML::Feed->parse( \$res->decoded_content ) );
        is( $feed->title, 'TestApp with ' . $format );
        my @entries = $feed->entries;
        is( scalar @entries,    9 );
        is( $entries[0]->title, 'entry 0' );

        # test categories
        for my $idx ( 0 .. 4 ) {
            my $entry      = $entries[$idx];
            my @categories = $entry->category;
            is( scalar @categories, $idx );
        }
        is( ref $entries[5]->category, '', 'scalar category' );
        is( $entries[6]->category,
            (), 'scalar empty category does get ignored' );
        is( $entries[7]->category,
            (), 'empty category in array does get ignored' );
        my @categories_8 = $entries[8]->category;
        is( scalar @categories_8, 2, 'two items in array' );
        is( $categories_8[0],     'a' );
        is( $categories_8[1],     'b' );
    }
}

#eval { $res = dancer_response(GET => '/feed/foo')};
#like $@, qr/unknown format/;
$res = $psgi->request( GET '/feed/foo' );
is( $res->code, 500, "response for GET /feed/foo is 500" );

{

    package TestApp;
    setting plugins => { Feed => { format => 'atom' } };
}
ok( $res = $psgi->request( GET '/feed' ) );
is( $res->header('Content-Type'), 'application/atom+xml' );
