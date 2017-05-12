use strict;
use warnings;

use App::Rssfilter::Feed;
use Test::Most;
throws_ok {
    App::Rssfilter::Feed->new();
} qr/Missing required arguments: name, url/,
'constructor must be passed name & url';

lives_and {
    my $feed = App::Rssfilter::Feed->new( foo => 'http://bar/' );
    is
        $feed->name,
        'foo';
} 'passing single key-value pair to ctor sets name to key';

lives_and {
    my $feed = App::Rssfilter::Feed->new( foo => 'http://bar/' );
    is
        $feed->url,
        'http://bar/';
} 'passing single key-value pair to ctor sets url to value';

done_testing;
