#!perl
use strict;
use warnings;
use Encode;
use Data::Deduper;
use XML::Feed;

my $uri = "http://api.twitter.com/1/statuses/public_timeline.rss";

my $dd = Data::Deduper->new(
    expr => sub {
        my ( $a, $b ) = @_;
        $a->link eq $b->link;
    },
    size => 50,
);

while (1) {
    my $feed = XML::Feed->parse( URI->new($uri) );
    for ( $dd->dedup( $feed->entries ) ) {
        print encode_utf8 $_->content->body."\n";
    }
    sleep 3;
}
