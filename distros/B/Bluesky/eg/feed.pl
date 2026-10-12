# eg/feed.pl - read timeline and threads, like/unlike a post.
#
#   cd eg
#   perl feed.pl [post-uri]
use v5.40;
use blib;
$|++;
use Bluesky;
#
my $bsky = Bluesky->new->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic transition:chat.bsky' );

# Home timeline
my $timeline = $bsky->getTimeline( limit => 5 );
for my $item ( @{ $timeline->{feed} // [] } ) {
    my $post = $item->{post};
    say sprintf '@%s: %s', $post->{author}{handle} // '?', substr( $post->{record}{text} // '', 0, 80 );
}

# Thread for the given post (or the first timeline post)
my $uri = shift // $timeline->{feed}[0]{post}{uri} or die "No post to inspect\n";
say "\nThread for $uri:";
my $thread = $bsky->getPostThread( uri => $uri, depth => 2 );
say 'Replies: ' . scalar @{ $thread->{thread}{replies} // [] };

# Like round-trip
my $post = $bsky->getPost($uri);
say "\nLiking $uri ...";
my $like = $bsky->like( $uri, $post->{cid} );
say 'Liked: ' . ( $like->{uri} // '?' );
my $unlike = $bsky->deleteLike( $like->{uri} );
say 'Unliked.';
