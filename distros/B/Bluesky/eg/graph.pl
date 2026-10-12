# eg/graph.pl - follows, relationships, lists, and starter packs.
#
#   cd eg
#   perl graph.pl [handle]
use v5.40;
use blib;
$|++;
use Bluesky;
#
my $bsky   = Bluesky->new->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic transition:chat.bsky' );
my $handle = shift // 'bsky.app';

# Follow round-trip
say "Following $handle ...";
my $follow = $bsky->follow($handle);
say 'Followed: ' . ( $follow->{uri} // '?' );
say 'Unfollowing ...';
$bsky->deleteFollow( $follow->{uri} );
say 'Unfollowed.';

# Who follows whom
my $follows   = $bsky->getFollows( $bsky->did );
my $followers = $bsky->getFollowers( $bsky->did );
say sprintf 'Following %d, followed by %d', scalar @$follows, scalar @$followers;

# Relationship to the handle
my $rels = $bsky->getRelationships( actors => [$handle] );
say 'Relationship: ' . ( $rels->[0]{following} ? 'following' : 'not following' );

# Lists by the handle, plus a taste of the first list's feed
my $lists = $bsky->getLists($handle);
say sprintf '%s owns %d lists', $handle, scalar @$lists;
if ( my $list = $lists->[0] ) {
    say 'First list: ' . ( $list->{name} // $list->{uri} );
    my $items = $bsky->getList( $list->{uri}, limit => 3 );
    say 'Members shown: ' . scalar @$items;
    my $feed = $bsky->getListFeed( $list->{uri}, limit => 3 );
    say 'Recent posts in list feed: ' . scalar @$feed;
}

# Starter packs
my $packs = $bsky->searchStarterPacks( q => 'perl', limit => 3 );
say 'Starter packs matching perl: ' . scalar @$packs;
my $suggested = $bsky->getSuggestedFollowsByActor($handle);
say 'Suggested follows: ' . scalar @$suggested;
