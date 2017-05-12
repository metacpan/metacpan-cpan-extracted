use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;

use XML::Feed;

plan tests => 32;

my ($res, $feed);

$res = dancer_response GET => '/feed';
is $res->{status}, 500, "response for GET /feed is 500";

for my $format (qw/atom rss/) {
    for my $route ("/feed/$format", "/other/feed/$format") {
        ok ($res = dancer_response(GET => $route));
        is ($res->{status}, 200);
        is ($res->header('Content-Type'), "application/$format+xml");
        ok ( $feed = XML::Feed->parse( \$res->{content} ) );
        is ( $feed->title, 'TestApp with ' . $format );
        my @entries = $feed->entries;
        is (scalar @entries, 10);
        is ($entries[0]->title, 'entry 1');
    }
}

#eval { $res = dancer_response(GET => '/feed/foo')};
#like $@, qr/unknown format/;
$res = dancer_response GET => '/feed/foo';
is $res->{status}, 500, "response for GET /feed/foo is 500";

setting plugins => { Feed => { format => 'atom' } };
ok ($res = dancer_response(GET => '/feed'));
is ($res->header('Content-Type'), 'application/atom+xml');
