use strict;
use warnings;

use Test::More tests => 32;

use lib 't/lib';
use XML::Feed;
use TestApp;

use Dancer2;
use Plack::Test;
use HTTP::Request::Common;

my $psgi = Plack::Test->create( Dancer2->runner->psgi_app );
my ($res, $feed);

$res = $psgi->request( GET '/feed' );
is $res->code, 500, "response for GET /feed is 500";

for my $format (qw/atom rss/) {
    for my $route ("/feed/$format", "/other/feed/$format") {
        ok ($res = $psgi->request( GET $route ) );
        is $res->code, 200, "$format - $route";
        is ($res->header('Content-Type'), "application/$format+xml");
        ok ( $feed = XML::Feed->parse( \$res->decoded_content ) );
        is ( $feed->title, 'TestApp with ' . $format );
        my @entries = $feed->entries;
        is (scalar @entries, 10);
        is ($entries[0]->title, 'entry 1');
    }
}

#eval { $res = dancer_response(GET => '/feed/foo')};
#like $@, qr/unknown format/;
$res = $psgi->request( GET '/feed/foo' );
is $res->code, 500, "response for GET /feed/foo is 500";

{ 
    package TestApp; 
    setting plugins => { Feed => { format => 'atom' } };
}
ok ($res = $psgi->request( GET '/feed' ) );
is ($res->header('Content-Type'), 'application/atom+xml');
