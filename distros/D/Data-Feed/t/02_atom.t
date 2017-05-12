use strict;
use Test::More (tests => 28);

my $HAVE_NETWORK;

BEGIN {
    if ( $ENV{DATA_FEED_NETWORK_TEST}) {
        $HAVE_NETWORK = 1;
    } else {
        eval {
            require IO::Socket::INET;
            my $socket = IO::Socket::INET->new(
                PeerAddr => 'api.flickr.com',
                PeerPort => 80
            );
            if ($socket && !$@) {
                $HAVE_NETWORK = 1;
            }
        };
    }
        

    use_ok("Data::Feed");
}

{
    my $atom = Data::Feed->parse( 't/data/atom.xml' );

    isa_ok($atom, "Data::Feed::Atom");

    is( $atom->title, 'First Weblog' );

    my @entries = $atom->entries;
    is( @entries, 2 );

    for my $entry (@entries) {
        ok( $entry->title );
    }
}

SKIP: {
    skip( "No network connection", 22 ) unless $HAVE_NETWORK;
    my $url = URI->new('http://api.flickr.com/services/feeds/photos_public.gne');

    my $feed = eval {
        Data::Feed->parse($url);
    };
    if ($@ && $@ =~ /Failed to fetch/) {
        skip( "Failed to fetch rss (skipping for sanity's sake)", 22 );
    }

    ok( $feed, "Fetch successful" );

    my @entries = $feed->entries;

    is( @entries, 20 );
    for (@entries) {
        for ($_->enclosures) {
            ok( $_->url );
        }
    }
}
