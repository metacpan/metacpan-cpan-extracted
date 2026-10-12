use v5.40;
use Test2::V0;
use blib;
use Bluesky;
use Time::Moment;

# Mock At: one override table covering every call Bluesky makes below.
my ( $last_get, $last_post, $threaded_gets );
my @calls;
my $mock_at = mock 'At' => (
    override => [
        did           => sub {'did:plc:mock-user'},
        host          => sub {'https://bsky.social'},
        _now          => sub { Time::Moment->now },
        session       => sub { { handle => 'mock.bsky.social' } },
        create_record => sub ( $self, $collection, $record, $rkey = undef ) {
            push @calls, { op => 'create_record', collection => $collection, record => $record, rkey => $rkey };
            return _record_response( $collection, $rkey );
        },
        delete_record => sub ( $self, $collection, $rkey ) {
            push @calls, { op     => 'delete_record', collection => $collection, rkey => $rkey };
            return       { commit => { rev => 'rev1' } };
        },
        put_record => sub ( $self, $collection, $rkey, $record, $cid = undef ) {
            push @calls, { op => 'put_record', collection => $collection, rkey => $rkey, record => $record };
            return _record_response( $collection, $rkey );
        },
        upload_blob => sub ( $self, $data, $mime = undef ) {
            push @calls, { op  => 'upload_blob', mime => $mime };
            return       { cid => 'blobcid1' };
        },
        login => sub ( $self, $id, $pw ) {
            push @calls, { op => 'login', identifier => $id };
            return       { ok => 1 };
        },
        resume => sub ( $self, @args ) {
            push @calls, { op => 'resume' };
            return       { ok => 1 };
        },
        oauth_start => sub ( $self, $handle, @rest ) {
            push @calls, { op => 'oauth_start', handle => $handle };
            return 'https://auth.example/authorize';
        },
        oauth_callback => sub ( $self, $code, $state ) {
            push @calls, { op => 'oauth_callback', code => $code };
            return       { ok => 1 };
        },
        firehose => sub ( $self, $cb, $url = undef ) {
            push @calls, { op => 'firehose' };
            return bless { callback => $cb }, 'Mock::Firehose';
        },
        get => sub ( $self, $method, $params = {} ) {
            $last_get = { method => $method, params => $params };
            if ( $method eq 'com.atproto.identity.resolveHandle' ) {
                return { did => 'did:plc:resolved' };
            }
            if ( $method eq 'com.atproto.repo.getRecord' ) {
                my $uri = "at://$params->{repo}/$params->{collection}/$params->{rkey}";
                if ( $params->{collection} eq 'app.bsky.actor.profile' ) {
                    return { uri => $uri, cid => 'cid-prof', value => { '$type' => 'app.bsky.actor.profile', displayName => 'Old' } };
                }
                if ($threaded_gets) {
                    $threaded_gets--;
                    return {
                        uri   => $uri,
                        cid   => 'cid-parent',
                        value => { reply => { root => { uri => 'at://did:plc:x/app.bsky.feed.post/root1', cid => 'cid-root' } } }
                    };
                }
                return { uri => $uri, cid => 'cid-rec', value => {} };
            }
            if ( $method eq 'app.bsky.feed.getPosts' ) {
                require At::Protocol::URI;
                return {
                    posts => [
                        {   uri    => $params->{uris}[0],
                            cid    => 'postcid1',
                            viewer => {
                                like   => At::Protocol::URI->new('at://did:plc:x/app.bsky.feed.like/l1'),
                                repost => At::Protocol::URI->new('at://did:plc:x/app.bsky.feed.repost/r1')
                            }
                        }
                    ]
                };
            }
            if ( $method eq 'app.bsky.actor.getProfile' ) {
                return { did => 'did:plc:target', handle => 'target.bsky.social' };
            }
            my %canned = (
                'app.bsky.feed.getTimeline'               => { feed          => [ { post => { uri => 'at://x/1' } } ], cursor => 'c1' },
                'app.bsky.feed.getAuthorFeed'             => { feed          => [] },
                'app.bsky.feed.getPostThread'             => { thread        => { post => {} } },
                'app.bsky.feed.getFeed'                   => { feed          => [] },
                'app.bsky.feed.getFeedSkeleton'           => { feed          => [] },
                'app.bsky.feed.getLikes'                  => { likes         => [] },
                'app.bsky.bookmark.getBookmarks'          => { bookmarks     => [] },
                'app.bsky.feed.getQuotes'                 => { quotes        => [] },
                'app.bsky.feed.getActorLikes'             => { feed          => [] },
                'app.bsky.feed.searchPosts'               => { posts         => [] },
                'app.bsky.feed.getSuggestedFeeds'         => { feeds         => [] },
                'app.bsky.feed.describeFeedGenerator'     => { did           => 'did:web:feed', feeds => [] },
                'app.bsky.feed.getFeedGenerator'          => { view          => {}, isOnline => 1, isValid => 1 },
                'app.bsky.feed.getFeedGenerators'         => { feeds         => [] },
                'app.bsky.feed.getActorFeeds'             => { feeds         => [] },
                'app.bsky.feed.getRepostedBy'             => { repostedBy    => [] },
                'app.bsky.graph.getBlocks'                => { blocks        => [] },
                'app.bsky.graph.getFollows'               => { follows       => [] },
                'app.bsky.graph.getFollowers'             => { followers     => [] },
                'app.bsky.graph.getRelationships'         => { relationships => [] },
                'app.bsky.graph.getMutes'                 => { mutes         => [] },
                'app.bsky.graph.getLists'                 => { lists         => [] },
                'app.bsky.graph.getList'                  => { list          => {}, items => [] },
                'app.bsky.graph.getStarterPack'           => { starterPack   => {} },
                'app.bsky.graph.getStarterPacks'          => { starterPacks  => [] },
                'app.bsky.graph.getActorStarterPacks'     => { starterPacks  => [] },
                'app.bsky.actor.getPreferences'           => { preferences   => [] },
                'app.bsky.actor.getProfiles'              => { profiles      => [] },
                'app.bsky.actor.getSuggestions'           => { actors        => [] },
                'app.bsky.actor.searchActors'             => { actors        => [] },
                'app.bsky.actor.searchActorsTypeahead'    => { actors        => [] },
                'app.bsky.notification.listNotifications' => { notifications => [] },
                'app.bsky.notification.getUnreadCount'    => { count         => 3 },
                'com.atproto.server.describeServer'       => { did           => 'did:web:bsky.social' },
                'com.atproto.repo.listRecords'            => { records       => [] },
                'app.bsky.labeler.getServices'            => { views         => [] },
                'chat.bsky.convo.listConvos'              => { convos        => [] },
                'chat.bsky.convo.getConvo'                => { convo         => { id => 'c1' } },
                'chat.bsky.convo.getConvoForMembers'      => { convo         => { id => 'c1' } },
                'chat.bsky.convo.getMessages'             => { messages      => [] },
                'chat.bsky.convo.getConvoAvailability'    => { canChat       => 'all' }
            );
            return $canned{$method} // {};
        },
        post => sub ( $self, $method, $data = {} ) {
            $last_post = { method => $method, data => $data };
            push @calls, { op      => 'post', method => $method, data => $data };
            return       { success => 1 };
        },
    ]
);

sub _record_response ( $collection, $rkey = undef ) {
    return { uri => "at://did:plc:mock-user/$collection/" . ( $rkey // 'rkey1' ), cid => 'cid-new' };
}
{

    package Mock::Firehose;
    sub start {1}
}
my $bsky = Bluesky->new();
subtest 'auth and session' => sub {
    ok $bsky->login( 'user.bsky.social', 'fake-app-password' ), 'login delegates';
    is $calls[-1]{identifier}, 'user.bsky.social', 'login passes identifier';
    ok $bsky->resume( 'access', 'refresh' ), 'resume delegates';
    is $bsky->oauth_start( 'user.bsky.social', 'http://localhost', 'http://127.0.0.1:8888/callback' ), 'https://auth.example/authorize',
        'oauth_start returns url';
    ok $bsky->oauth_callback( 'code1', 'state1' ), 'oauth_callback delegates';
    is $bsky->session->{handle}, 'mock.bsky.social',  'session delegates';
    is $bsky->did,               'did:plc:mock-user', 'did delegates';
    my $fh = $bsky->firehose( sub { } );
    ok $fh && $fh->start, 'firehose delegates and starts';
};
subtest 'feed reads' => sub {
    ok $bsky->getTimeline(), 'getTimeline';
    is $last_get->{method}, 'app.bsky.feed.getTimeline', 'getTimeline routes';
    ok $bsky->getAuthorFeed( actor => 'bsky.app' ),                          'getAuthorFeed';
    ok $bsky->getPostThread( uri => 'at://did:plc:x/app.bsky.feed.post/1' ), 'getPostThread';
    is ref $bsky->getFeed('at://did:plc:x/app.bsky.feed.generator/1'),         'ARRAY', 'getFeed unwraps feed';
    is ref $bsky->getFeedSkeleton('at://did:plc:x/app.bsky.feed.generator/1'), 'ARRAY', 'getFeedSkeleton unwraps feed';
    my $post = $bsky->getPost('at://did:plc:x/app.bsky.feed.post/1');
    is $post->{cid}, 'postcid1',                                                                                       'getPost hydrates single post';
    is scalar @{ $bsky->getPosts( 'at://did:plc:x/app.bsky.feed.post/1', 'at://did:plc:x/app.bsky.feed.post/2' ) }, 1, 'getPosts hydrates list';
    ok $bsky->getLikes( uri => 'at://did:plc:x/app.bsky.feed.post/1' ), 'getLikes';
    is ref $bsky->getBookmarks(), 'ARRAY', 'getBookmarks unwraps';
    $bsky->createBookmark('at://did:plc:x/app.bsky.feed.post/1');
    is $last_post->{method},    'app.bsky.bookmark.createBookmark', 'createBookmark routes';
    is $last_post->{data}{cid}, 'postcid1',                         'createBookmark auto-fetches cid';
    $bsky->deleteBookmark('at://did:plc:x/app.bsky.feed.post/1');
    is $last_post->{method},                                                 'app.bsky.bookmark.deleteBookmark', 'deleteBookmark routes';
    is ref $bsky->getQuotes( uri => 'at://did:plc:x/app.bsky.feed.post/1' ), 'ARRAY',                            'getQuotes unwraps';
    is ref $bsky->getActorLikes( actor => 'bsky.app' ),                      'ARRAY',                            'getActorLikes unwraps';
    is ref $bsky->searchPosts( q => 'perl' ),                                'ARRAY',                            'searchPosts unwraps';
    is ref $bsky->getSuggestedFeeds(),                                       'ARRAY',                            'getSuggestedFeeds unwraps';
    ok $bsky->describeFeedGenerator(),                                      'describeFeedGenerator';
    ok $bsky->getFeedGenerator('at://did:plc:x/app.bsky.feed.generator/1'), 'getFeedGenerator';
    is $last_get->{params}{feed},                       'at://did:plc:x/app.bsky.feed.generator/1', 'getFeedGenerator passes feed';
    is ref $bsky->getFeedGenerators( feeds => [] ),     'ARRAY',                                    'getFeedGenerators unwraps';
    is ref $bsky->getActorFeeds( actor => 'bsky.app' ), 'ARRAY',                                    'getActorFeeds unwraps';
    is ref $bsky->getRepostedBy( uri => 'at://did:plc:x/app.bsky.feed.post/1' ), 'ARRAY',           'getRepostedBy unwraps';
};
subtest 'posting' => sub {
    @calls = ();
    my $post = $bsky->createPost( text => 'Hello @handle.example.com https://example.com #perl' );
    ok $post->{uri}, 'createPost returns uri';
    my ($write) = grep { $_->{op} eq 'create_record' && $_->{collection} eq 'app.bsky.feed.post' } @calls;
    ok $write, 'createPost creates post record';
    is scalar @{ $write->{record}{facets} },          3,                  'createPost parses mention, link, and tag facets';
    is $write->{record}{facets}[0]{features}[0]{did}, 'did:plc:resolved', 'mention facet resolves DID';
    my $reply = $bsky->createPost( reply_to => 'at://did:plc:x/app.bsky.feed.post/1', text => 'reply' );
    ok $reply, 'reply posts';
    ($write) = reverse grep { $_->{op} eq 'create_record' && $_->{collection} eq 'app.bsky.feed.post' } @calls;
    ok $write->{record}{reply}{parent}{uri}, 'reply refs parent';
    $bsky->createPost(
        text            => 'gated',
        reply_gate      => [ 'mention', 'follower', 'following', 'list' ],
        reply_gate_list => 'at://did:plc:x/app.bsky.graph.list/9'
    );
    my ($gate) = grep { ( $_->{collection} // '' ) eq 'app.bsky.feed.threadgate' } @calls;
    ok $gate, 'reply_gate creates threadgate';
    is scalar @{ $gate->{record}{allow} }, 4,                                       'all four rule types recorded';
    is $gate->{record}{allow}[1]{'$type'}, 'app.bsky.feed.threadgate#followerRule', 'follower rule supported';
    is $gate->{record}{allow}[3]{list},    'at://did:plc:x/app.bsky.graph.list/9',  'list rule carries list uri';
    is $gate->{rkey},                      'rkey1',                                 'threadgate rkey matches post rkey';
    $bsky->createPost( text => 'no quotes', post_gate => ['disable'] );
    my ($pgate) = grep { ( $_->{collection} // '' ) eq 'app.bsky.feed.postgate' } @calls;
    is $pgate->{record}{embeddingRules}[0]{'$type'}, 'app.bsky.feed.postgate#disableRule', 'post_gate disable rule';
    $bsky->createPost(
        text   => 'meta',
        lang   => ['en'],
        tags   => ['perl'],
        labels => ['porn'],
        embed  => { ref => 'at://did:plc:x/app.bsky.feed.post/1' }
    );
    ($write) = reverse grep { $_->{op} eq 'create_record' && $_->{collection} eq 'app.bsky.feed.post' } @calls;
    is $write->{record}{langs},                  ['en'],                  'langs preserved';
    is $write->{record}{labels}{values}[0]{val}, 'porn',                  'self labels recorded';
    is $write->{record}{embed}{'$type'},         'app.bsky.embed.record', 'ref embed built';
    @calls = ();
    $bsky->deletePost('at://did:plc:x/app.bsky.feed.post/1');
    my @dels = grep { $_->{op} eq 'delete_record' } @calls;
    is [ map { $_->{collection} } @dels ], [ 'app.bsky.feed.post', 'app.bsky.feed.threadgate', 'app.bsky.feed.postgate' ],
        'deletePost cleans gates too';
    my $like = $bsky->like('at://did:plc:x/app.bsky.feed.post/1');
    ok $like->{uri}, 'like returns record';
    ($write) = grep { ( $_->{collection} // '' ) eq 'app.bsky.feed.like' } @calls;
    is $write->{record}{subject}{cid}, 'postcid1', 'like auto-fetches cid';
    my $unlike = $bsky->deleteLike('at://did:plc:x/app.bsky.feed.post/1');
    ok $unlike->{commit}, 'deleteLike via post uri';
    ($write) = reverse grep { $_->{op} eq 'delete_record' } @calls;
    is $write->{collection}, 'app.bsky.feed.like', 'deleteLike removes like record';
    $bsky->repost('at://did:plc:x/app.bsky.feed.post/1');
    ($write) = grep { ( $_->{collection} // '' ) eq 'app.bsky.feed.repost' } @calls;
    is $write->{record}{subject}{cid}, 'postcid1', 'repost auto-fetches cid';
    $bsky->deleteRepost('at://did:plc:x/app.bsky.feed.post/1');
    ($write) = reverse grep { $_->{op} eq 'delete_record' } @calls;
    is $write->{collection}, 'app.bsky.feed.repost', 'deleteRepost via post uri';
    my $blob = $bsky->uploadBlob( 'raw-bytes', mime_type => 'image/png' );
    is $blob->{cid}, 'blobcid1', 'uploadBlob delegates to upload_blob';
    ($write) = grep { $_->{op} eq 'upload_blob' } @calls;
    is $write->{mime}, 'image/png', 'uploadBlob passes mime type';
};
subtest 'social graph' => sub {
    $bsky->block('target.bsky.social');
    my ($write) = grep { ( $_->{collection} // '' ) eq 'app.bsky.graph.block' } @calls;
    is $write->{record}{subject}, 'did:plc:target', 'block resolves handle to DID';
    is ref $bsky->getBlocks(),    'ARRAY',          'getBlocks unwraps';
    $bsky->deleteBlock('at://did:plc:x/app.bsky.graph.block/b1');
    ($write) = reverse grep { $_->{op} eq 'delete_record' } @calls;
    is $write->{collection}, 'app.bsky.graph.block', 'deleteBlock removes block';
    $bsky->follow('target.bsky.social');
    ($write) = grep { ( $_->{collection} // '' ) eq 'app.bsky.graph.follow' } @calls;
    is $write->{record}{subject}, 'did:plc:target', 'follow resolves handle to DID';
    $bsky->deleteFollow('at://did:plc:x/app.bsky.graph.follow/f1');
    ($write) = reverse grep { $_->{op} eq 'delete_record' } @calls;
    is $write->{collection},                                  'app.bsky.graph.follow', 'deleteFollow removes follow';
    is ref $bsky->getFollows('bsky.app'),                     'ARRAY',                 'getFollows unwraps';
    is ref $bsky->getFollowers('bsky.app'),                   'ARRAY',                 'getFollowers unwraps';
    is ref $bsky->getRelationships( actors => ['bsky.app'] ), 'ARRAY',                 'getRelationships unwraps';
    is $last_get->{params}{others},                           ['bsky.app'],            'actors accepted as alias for others';
    is $last_get->{params}{actor},                            'did:plc:mock-user',     'actor defaults to own DID';
    is ref $bsky->getMutes(),                                 'ARRAY',                 'getMutes unwraps';
    $bsky->muteThread('at://did:plc:x/app.bsky.feed.post/1');
    is $last_post->{method}, 'app.bsky.graph.muteThread', 'muteThread routes';
    $bsky->unmuteThread('at://did:plc:x/app.bsky.feed.post/1');
    is $last_post->{method},                                       'app.bsky.graph.unmuteThread', 'unmuteThread routes';
    is ref $bsky->getLists('bsky.app'),                            'ARRAY',                       'getLists unwraps';
    is ref $bsky->getList('at://did:plc:x/app.bsky.graph.list/1'), 'ARRAY',                       'getList unwraps items';
    ok $bsky->getStarterPack('at://did:plc:x/app.bsky.graph.starterpack/1'), 'getStarterPack';
    is ref $bsky->getStarterPacks('at://did:plc:x/app.bsky.graph.starterpack/1'), 'ARRAY', 'getStarterPacks unwraps';
    is ref $bsky->getActorStarterPacks('bsky.app'),                               'ARRAY', 'getActorStarterPacks unwraps';
};
subtest 'actors' => sub {
    ok $bsky->getProfile('bsky.app'), 'getProfile';
    is ref $bsky->getPreferences(), 'ARRAY', 'getPreferences unwraps';
    $bsky->putPreferences( [ { '$type' => 'pref' } ] );
    is $last_post->{method}, 'app.bsky.actor.putPreferences', 'putPreferences routes';
    my $up = $bsky->upsertProfile( sub (%existing) { return { %existing, displayName => 'New' } } );
    ok $up, 'upsertProfile returns';
    my ($put) = reverse grep { $_->{op} eq 'put_record' } @calls;
    is $put->{collection},                                              'app.bsky.actor.profile', 'upsertProfile writes profile collection';
    is $put->{rkey},                                                    'self',                   'upsertProfile uses self rkey';
    is $put->{record}{displayName},                                     'New',                    'callback modifications applied';
    is ref $bsky->getProfiles( actors => [ 'bsky.app', 'did:plc:x' ] ), 'ARRAY',                  'getProfiles unwraps';
    is ref $bsky->getSuggestions(),                                     'ARRAY',                  'getSuggestions unwraps';
    is ref $bsky->searchActors( q => 'perl' ),                          'ARRAY',                  'searchActors unwraps';
    is ref $bsky->searchActorsTypeahead( q => 'san' ),                  'ARRAY',                  'searchActorsTypeahead unwraps';
    $bsky->mute('target.bsky.social');
    is $last_post->{method}, 'app.bsky.graph.muteActor', 'mute routes';
    $bsky->unmute('target.bsky.social');
    is $last_post->{method}, 'app.bsky.graph.unmuteActor', 'unmute routes';
    $bsky->muteModList('at://did:plc:x/app.bsky.graph.list/1');
    is $last_post->{method}, 'app.bsky.graph.muteActorList', 'muteModList routes';
    $bsky->unmuteModList('at://did:plc:x/app.bsky.graph.list/1');
    is $last_post->{method}, 'app.bsky.graph.unmuteActorList', 'unmuteModList routes';
    $bsky->blockModList('at://did:plc:x/app.bsky.graph.list/1');
    my ($blk) = grep { ( $_->{collection} // '' ) eq 'app.bsky.graph.listblock' } @calls;
    ok $blk, 'blockModList creates listblock';
    $bsky->unblockModList('at://did:plc:x/app.bsky.graph.listblock/1');
    ($blk) = reverse grep { $_->{op} eq 'delete_record' } @calls;
    is $blk->{collection}, 'app.bsky.graph.listblock', 'unblockModList removes listblock';
};
subtest 'notifications and identity' => sub {
    is ref $bsky->listNotifications(),    'ARRAY', 'listNotifications unwraps';
    is $bsky->countUnreadNotifications(), 3,       'countUnreadNotifications returns count';
    ok $bsky->updateSeenNotifications(), 'updateSeenNotifications';
    is $last_post->{method},             'app.bsky.notification.updateSeen', 'updateSeen routes';
    is $bsky->resolveHandle('bsky.app'), 'did:plc:resolved',                 'resolveHandle returns DID';
    $bsky->updateHandle('new.bsky.social');
    is $last_post->{method}, 'com.atproto.identity.updateHandle', 'updateHandle routes';
    ok $bsky->describeServer(), 'describeServer';
    is ref $bsky->listRecords( repo => 'bsky.app', collection => 'app.bsky.feed.post' ), 'ARRAY', 'listRecords unwraps';
    is ref $bsky->getLabelerServices( dids => ['did:plc:x'] ),                           'ARRAY', 'getLabelerServices unwraps views';
};
subtest 'chat remainder' => sub {
    is $bsky->getConvo('c1')->{id},                                 'c1',    'getConvo unwraps convo';
    is $bsky->getConvoForMembers( members => ['did:plc:x'] )->{id}, 'c1',    'getConvoForMembers unwraps convo';
    is ref $bsky->getMessages( convoId => 'c1' ),                   'ARRAY', 'getMessages unwraps';
    $bsky->sendMessage( 'c1', { text => 'hi' } );
    is $last_post->{method}, 'chat.bsky.convo.sendMessage', 'sendMessage routes';
    $bsky->acceptConvo('c1');
    is $last_post->{method}, 'chat.bsky.convo.acceptConvo', 'acceptConvo routes';
    $bsky->leaveConvo('c1');
    is $last_post->{method}, 'chat.bsky.convo.leaveConvo', 'leaveConvo routes';
    $bsky->updateRead('c1');
    is $last_post->{method}, 'chat.bsky.convo.updateRead', 'updateRead routes';
    $bsky->muteConvo('c1');
    is $last_post->{method}, 'chat.bsky.convo.muteConvo', 'muteConvo routes';
    $bsky->unmuteConvo('c1');
    is $last_post->{method}, 'chat.bsky.convo.unmuteConvo', 'unmuteConvo routes';
    $bsky->addReaction( 'c1', 'm1', 'like' );
    is $last_post->{method}, 'chat.bsky.convo.addReaction', 'addReaction routes';
    $bsky->removeReaction( 'c1', 'm1', 'like' );
    is $last_post->{method}, 'chat.bsky.convo.removeReaction', 'removeReaction routes';
    $bsky->deleteMessageForSelf( 'c1', 'm1' );
    is $last_post->{method}, 'chat.bsky.convo.deleteMessageForSelf', 'deleteMessageForSelf routes';
    ok $bsky->getConvoAvailability(), 'getConvoAvailability';
    ok $bsky->getLog(),               'getLog';
    is ref $bsky->listConvos(), 'ARRAY', 'listConvos unwraps';
};
subtest 'utils' => sub {
    is [ $bsky->parse_mentions('@handle.example.com and @bsky.app') ],
        [ { start => 0, end => 19, handle => 'handle.example.com' }, { start => 24, end => 33, handle => 'bsky.app' } ], 'parse_mentions spans';
    is [ $bsky->parse_mentions('💩 @handle.example.com') ], [ { start => 5, end => 24, handle => 'handle.example.com' } ],
        'parse_mentions uses byte offsets';
    is [ $bsky->parse_urls('see https://example.com/x here') ], [ { start => 4, end => 25, url => 'https://example.com/x' } ], 'parse_urls spans';
    is [ $bsky->parse_tags('hello #perl world') ],              [ { start => 6, end => 11, tag => 'perl' } ], 'parse_tags spans include the hash';
    my @facets = $bsky->parse_facets('@handle.example.com https://example.com #perl');
    is scalar @facets,               3,                     'parse_facets finds all three features';
    is $facets[0]{features}[0]{did}, 'did:plc:resolved',    'parse_facets resolves mention DID';
    is $facets[1]{features}[0]{uri}, 'https://example.com', 'parse_facets links URL';
    is $facets[2]{features}[0]{tag}, 'perl',                'parse_facets tags hashtag';
    is $bsky->parse_uri('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l'),
        { repo => 'did:plc:z72i7hdynmk6r22z27h6tvur', collection => 'app.bsky.feed.post', rkey => '3l6oveex3ii2l' }, 'parse_uri splits AT-URI';
    my $refs = $bsky->getReplyRefs('at://did:plc:x/app.bsky.feed.post/1');
    is $refs->{parent}{cid}, 'cid-rec', 'getReplyRefs parent';
    is $refs->{root}{cid},   'cid-rec', 'standalone post is its own root';
    $threaded_gets = 1;
    $refs          = $bsky->getReplyRefs('at://did:plc:x/app.bsky.feed.post/2');
    is $refs->{parent}{cid}, 'cid-parent', 'reply parent kept';
    is $refs->{root}{cid},   'cid-rec',    'reply root resolved';
    my $embed = $bsky->getEmbedRef('at://did:plc:x/app.bsky.feed.post/1');
    is $embed->{'$type'}, 'app.bsky.embed.record', 'getEmbedRef builds record embed';
    ok $embed->{record}{uri}, 'getEmbedRef keeps uri';
};
#
done_testing();
