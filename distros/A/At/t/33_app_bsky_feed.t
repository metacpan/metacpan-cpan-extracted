use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At::Bluesky;
#
isa_ok(
    At::Lexicon::app::bsky::feed::postView->new(
        uri        => 'https://blah.com/fun/fun/fun/',
        cid        => 'fdsafsd',
        author     => { did  => 'did:web:fdsafdafdsafdlsajkflds', handle => 'my.name.here' },
        record     => { user => 'defined' },
        indexedAt  => '2023-12-13T01:51:24Z',
        viewer     => { repost => 'https://original.com/fdsafdsa/', like => 'https://like.com/fdsafdsaf/', replyDisabled => !1 },
        threadgate => { cid    => 'fdsa' }
    ),
    ['At::Lexicon::app::bsky::feed::postView'],
    '::postView'
);
#
subtest 'live' => sub {
    my $bsky = At::Bluesky->new( identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );
    subtest 'feed_getSuggestedFeeds' => sub {
        ok my $feeds = $bsky->feed_getSuggestedFeeds(), '$bsky->feed_getSuggestedFeeds()';
        my $feed = $feeds->{feeds}->[0];
        isa_ok $feed,          ['At::Lexicon::app::bsky::feed::generatorView'], '...contains list of feeds';
        isa_ok $feed->creator, ['At::Lexicon::app::bsky::actor::profileView'],  '......feeds contain creators';
    };
    #
    subtest 'feed_getTimeline' => sub {
        ok my $timeline = $bsky->feed_getTimeline(), '$bsky->feed_getTimeline()';
        my $post = $timeline->{feed}->[0];
        isa_ok $post, ['At::Lexicon::app::bsky::feed::feedViewPost'], '...contains list of feedViewPost objects';
    };
    #
    subtest 'feed_searchPosts' => sub {
        ok my $results = $bsky->feed_searchPosts( query => 'perl' ), '$bsky->feed_searchPosts(query => "perl")';
        my $post = $results->{posts}->[0];
        isa_ok $post, ['At::Lexicon::app::bsky::feed::postView'], '...contains list of postView objects';
    };
    {
        my $replied;    # Set in getAuthorFeed and used later on
        subtest 'feed_getAuthorFeed' => sub {
            ok my $results = $bsky->feed_getAuthorFeed( actor => 'bsky.app' ), '$bsky->feed_getAuthorFeed(actor => "bsky.app")';
            my $post = $results->{feed}->[0];
            isa_ok $post, ['At::Lexicon::app::bsky::feed::feedViewPost'], '...contains list of feedViewPost objects';

            # Store the latest!
            ($replied) = grep { $_->post->replyCount } @{ $results->{feed} };
        };
        subtest 'feed_getRepostedBy' => sub {
            $replied // skip_all 'failed to find a reposted post';
            ok my $results = $bsky->feed_getRepostedBy( uri => $replied->post->uri, cid => $replied->post->cid ),
                sprintf '$bsky->feed_getRepostedBy(uri => "%s...", cid => "%s...")', substr( $replied->post->uri->as_string, 0, 25 ),
                substr( $replied->post->cid, 0, 10 );
            my $post = $results->{repostedBy}->[0];
            isa_ok $post, ['At::Lexicon::app::bsky::actor::profileView'], '...contains list of profileView objects';
        };
    }
    subtest 'feed_getActorFeeds' => sub {
        ok my $results = $bsky->feed_getActorFeeds( actor => 'bsky.app' ), '$bsky->feed_getActorFeeds(actor => "bsky.app")';
        my $post = $results->{feeds}->[0];
        isa_ok $post, ['At::Lexicon::app::bsky::feed::generatorView'], '...contains list of generatorView objects';
    };
    subtest 'feed_getActorLikes' => sub {
        ok my $results = $bsky->feed_getActorLikes( actor => 'atperl.bsky.social' ), '$bsky->feed_getActorLikes(actor => "atperl.bsky.social")';
        if ( !scalar @{ $results->{feed} } ) { skip_all 1, 'I apparently do not like anything. Weird' }
        else {
            my $post = $results->{feed}->[0];
            isa_ok $post, ['At::Lexicon::app::bsky::feed::feedViewPost'], '...contains list of feedViewPost objects';
        }
    };
    subtest 'feed_getPosts' => sub {    # hardcoded from https://bsky.app/profile/atproto.com/post/3kftlbujmfk24
        ok my $results = $bsky->feed_getPosts('at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24'), '$bsky->feed_getPosts(...)';
        my $post = $results->{posts}->[0];
        isa_ok $post, ['At::Lexicon::app::bsky::feed::postView'], '...contains list of postView objects';
    };
    subtest 'feed_getPostThread' => sub {    # hardcoded from https://bsky.app/profile/atproto.com/post/3kftlbujmfk24
        my $todo = todo 'An invalid TLD (literally "handle.invalid") is being used by some handle in this thread';
        ok my $results = eval { $bsky->feed_getPostThread('at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24') },
            '$bsky->feed_getPostThread("at://did:plc:ewvi...")';
        isa_ok $results->{thread}, ['At::Lexicon::app::bsky::feed::threadViewPost'], '...returns a threadViewPost object';
    };
    subtest 'feed_getLikes' => sub {
        ok my $results = $bsky->feed_getLikes( uri => 'at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24' ),
            '$bsky->feed_getLikes("at://did:plc:ewvi...")';
        isa_ok $results->{likes}->[0], ['At::Lexicon::app::bsky::feed::getLikes::like'], '...contains list of ::feed::getLikes::like objects';
    };
    subtest 'feed_getListFeed' => sub {      # TODO: I should create a new list for this
        ok my $results = $bsky->feed_getListFeed( list => 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.graph.list/3k4diugcw3k2p' ),
            '$bsky->feed_getListFeed("at://did:plc:kytt...")';
        isa_ok $results->{feed}->[0], ['At::Lexicon::app::bsky::feed::feedViewPost'], '...contains list of ::feed::feedViewPost objects';
    };
    can_ok $bsky, 'feed_getFeedSkeleton';    # TODO: test this
    subtest 'feed_getFeedGenerator' => sub {
        ok my $results = $bsky->feed_getFeedGenerator('at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.feed.generator/aaalfodybabzy'),
            '$bsky->feed_getFeedGenerator("at://did:plc:kytt...")';
        isa_ok $results->{view}, ['At::Lexicon::app::bsky::feed::generatorView'], '...returns a ::feed::generatorView object';
    };
    subtest 'feed_getFeedGenerators' => sub {
        ok my $results = $bsky->feed_getFeedGenerators('at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.feed.generator/aaalfodybabzy'),
            '$bsky->feed_getFeedGenerators("at://did:plc:kytt...")';
        isa_ok $results->{feeds}->[0], ['At::Lexicon::app::bsky::feed::generatorView'], '...returns a list of ::feed::generatorView objects';
    };
    subtest 'feed_getFeed' => sub {
        ok my $results = $bsky->feed_getFeed('at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.feed.generator/aaalfodybabzy'),
            '$bsky->feed_getFeed("at://did:plc:kytt...")';
        isa_ok $results->{feed}->[0], ['At::Lexicon::app::bsky::feed::feedViewPost'], '...contains list of ::feed::feedViewPost objects';
    };
    can_ok $bsky, 'feed_describeFeedGenerator';    # TODO: test this
};
#
done_testing;
