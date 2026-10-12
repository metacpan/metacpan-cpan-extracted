use v5.40;
use Test2::V0;
use blib;
use Bluesky;

# Mock At: canned responses for every endpoint exercised below.
my ( $last_get, $last_post );
my $mock_at = mock 'At' => (
    override => [
        did  => sub {'did:plc:mock-user'},
        host => sub {'https://bsky.social'},
        get  => sub ( $self, $method, $params = {} ) {
            $last_get = { method => $method, params => $params };
            if ( $method eq 'com.atproto.server.getServiceAuth' ) {
                return { token => 'mock-service-token' };
            }
            if ( $method eq 'app.bsky.feed.getListFeed' ) {
                return { feed => [ { post => { uri => 'at://did:plc:x/app.bsky.feed.post/1' } } ] };
            }
            if ( $method eq 'app.bsky.graph.getListBlocks' or $method eq 'app.bsky.graph.getListMutes' ) {
                return { lists => [ { uri => 'at://did:plc:x/app.bsky.graph.list/1' } ] };
            }
            if ( $method eq 'app.bsky.graph.getListsWithMembership' ) {
                return { listsWithMembership => [ { list => { uri => 'at://did:plc:x/app.bsky.graph.list/1' } } ] };
            }
            if ( $method eq 'app.bsky.graph.getStarterPacksWithMembership' ) {
                return { starterPacksWithMembership => [ { starterPack => { uri => 'at://did:plc:x/app.bsky.graph.starterpack/1' } } ] };
            }
            if ( $method eq 'app.bsky.graph.getSuggestedFollowsByActor' ) {
                return { suggestions => [ { handle => 'friend.bsky.social' } ] };
            }
            if ( $method eq 'app.bsky.graph.searchStarterPacks' ) {
                return { starterPacks => [ { uri => 'at://did:plc:x/app.bsky.graph.starterpack/1' } ] };
            }
            if ( $method eq 'app.bsky.notification.getPreferences' ) {
                return { preferences => { priority => 1 } };
            }
            if ( $method eq 'app.bsky.notification.putPreferencesV2' ) {
                return { preferences => { chat => { include => 'all' } } };
            }
            if ( $method eq 'app.bsky.notification.listActivitySubscriptions' ) {
                return { subscriptions => [ { handle => 'fan.bsky.social' } ] };
            }
            if ( $method eq 'app.bsky.draft.getDrafts' ) {
                return { drafts => [ { id => 'draft1' } ] };
            }
            if ( $method eq 'app.bsky.contact.getMatches' ) {
                return { matches => [ { handle => 'match.bsky.social' } ] };
            }
            if ( $method eq 'app.bsky.contact.getSyncStatus' ) {
                return { syncStatus => { matchesCount => 2 } };
            }
            if ( $method eq 'app.bsky.contact.importContacts' ) {
                return { matchesAndContactIndexes => [ { contactIndex => 0 } ] };
            }
            if ( $method eq 'app.bsky.contact.verifyPhone' ) {
                return { token => 'single-use-jwt' };
            }
            if ( $method eq 'app.bsky.ageassurance.getConfig' ) {
                return { regions => [] };
            }
            if ( $method eq 'app.bsky.ageassurance.getState' ) {
                return { state => { status => 'unknown', access => 'unknown' }, metadata => {} };
            }
            if ( $method eq 'com.atproto.label.queryLabels' ) {
                return { labels => [ { val => 'porn' } ] };
            }
            return {};
        },
        post => sub ( $self, $method, $data = {} ) {
            $last_post = { method => $method, data => $data };
            if ( $method eq 'app.bsky.notification.putPreferencesV2' ) {
                return { preferences => { chat => { include => 'all' } } };
            }
            if ( $method eq 'app.bsky.draft.createDraft' ) {
                return { id => 'draft1' };
            }
            if ( $method eq 'app.bsky.contact.verifyPhone' ) {
                return { token => 'single-use-jwt' };
            }
            if ( $method eq 'app.bsky.contact.importContacts' ) {
                return { matchesAndContactIndexes => [ { contactIndex => 0 } ] };
            }
            return { success => 1 };
        },
    ]
);

# The video service talks to video.bsky.app over its own HTTP::Tiny client.
my $video_http = mock 'HTTP::Tiny' => (
    override => [
        new => sub { bless {}, shift },
        get => sub ( $self, $url, $opts ) {
            my $content = $url =~ /getJobStatus/ ? '{"jobStatus":{"jobId":"job1","state":"JOB_STATE_COMPLETED"}}' :
                '{"canUpload":1,"remainingDailyVideos":9}';
            return { success => 1, status => 200, headers => { 'content-type' => 'application/json' }, content => $content };
        },
    ]
);
my $bsky = Bluesky->new();
subtest 'Feed additions' => sub {
    my $feed = $bsky->getListFeed('at://did:plc:x/app.bsky.graph.list/1');
    is ref $feed,                 'ARRAY',                                'getListFeed returns arrayref';
    is $last_get->{method},       'app.bsky.feed.getListFeed',            'getListFeed routes correctly';
    is $last_get->{params}{list}, 'at://did:plc:x/app.bsky.graph.list/1', 'getListFeed passes list';
    $bsky->sendInteractions( interactions => [ { item => 'at://did:plc:x/app.bsky.feed.post/1', event => 'app.bsky.feed.defs#interactionSeen' } ] );
    is $last_post->{method}, 'app.bsky.feed.sendInteractions', 'sendInteractions routes correctly';
};
subtest 'Graph additions' => sub {
    is ref $bsky->getListBlocks(),                                     'ARRAY',              'getListBlocks returns arrayref';
    is ref $bsky->getListMutes(),                                      'ARRAY',              'getListMutes returns arrayref';
    is ref $bsky->getListsWithMembership('target.bsky.social'),        'ARRAY',              'getListsWithMembership returns arrayref';
    is $last_get->{params}{actor},                                     'target.bsky.social', 'getListsWithMembership passes actor';
    is ref $bsky->getStarterPacksWithMembership('target.bsky.social'), 'ARRAY',              'getStarterPacksWithMembership returns arrayref';
    my $sug = $bsky->getSuggestedFollowsByActor('bsky.app');
    is $sug->[0]{handle},                            'friend.bsky.social', 'getSuggestedFollowsByActor unwraps suggestions';
    is ref $bsky->searchStarterPacks( q => 'perl' ), 'ARRAY',              'searchStarterPacks returns arrayref';
};
subtest 'Notification additions' => sub {
    ok $bsky->getNotificationPreferences(), 'getNotificationPreferences returns preferences';
    $bsky->putNotificationPreferences( priority => 1 );
    is $last_post->{method}, 'app.bsky.notification.putPreferences', 'putNotificationPreferences routes correctly';
    ok $bsky->putNotificationPreferencesV2( chat => { include => 'all', push => 1 } ), 'putNotificationPreferencesV2 returns preferences';
    is ref $bsky->listActivitySubscriptions(), 'ARRAY', 'listActivitySubscriptions returns arrayref';
    $bsky->putActivitySubscription( 'did:plc:x', { post => 1, reply => 1 } );
    is $last_post->{method}, 'app.bsky.notification.putActivitySubscription', 'putActivitySubscription routes correctly';
    $bsky->registerPush( serviceDid => 'did:web:x', token => 't', platform => 'ios', appId => 'a' );
    is $last_post->{method}, 'app.bsky.notification.registerPush', 'registerPush routes correctly';
    $bsky->unregisterPush( serviceDid => 'did:web:x', token => 't', platform => 'ios', appId => 'a' );
    is $last_post->{method}, 'app.bsky.notification.unregisterPush', 'unregisterPush routes correctly';
};
subtest 'Video service' => sub {
    my $limits = $bsky->getVideoUploadLimits();
    ok $limits->{canUpload}, 'getVideoUploadLimits returns limits';
    my $job = $bsky->getVideoJobStatus('job1');
    is $job->{state}, 'JOB_STATE_COMPLETED', 'getVideoJobStatus unwraps jobStatus';
};
subtest Drafts => sub {
    is ref $bsky->getDrafts(), 'ARRAY', 'getDrafts returns arrayref';
    my $created = $bsky->createDraft( { posts => [ { text => 'Unfinished thought...' } ] } );
    is $created->{id}, 'draft1', 'createDraft returns id';
    $bsky->updateDraft( { id => 'draft1', draft => { posts => [] } } );
    is $last_post->{method}, 'app.bsky.draft.updateDraft', 'updateDraft routes correctly';
    $bsky->deleteDraft('draft1');
    is $last_post->{method},   'app.bsky.draft.deleteDraft', 'deleteDraft routes correctly';
    is $last_post->{data}{id}, 'draft1',                     'deleteDraft passes id';
};
subtest Contacts => sub {
    is ref $bsky->getContactMatches(), 'ARRAY', 'getContactMatches returns arrayref';
    ok $bsky->getContactSyncStatus(), 'getContactSyncStatus returns status';
    is ref $bsky->importContacts( token => 'jwt', contacts => ['+12125550123'] ), 'ARRAY', 'importContacts unwraps matches';
    $bsky->dismissContactMatch('did:plc:bad');
    is $last_post->{method}, 'app.bsky.contact.dismissMatch', 'dismissContactMatch routes correctly';
    $bsky->removeContactData();
    is $last_post->{method}, 'app.bsky.contact.removeData', 'removeContactData routes correctly';
    $bsky->startPhoneVerification('+12125550123');
    is $last_post->{method},                           'app.bsky.contact.startPhoneVerification', 'startPhoneVerification routes correctly';
    is $bsky->verifyPhone( '+12125550123', '123456' ), 'single-use-jwt',                          'verifyPhone returns token';
};
subtest 'Age assurance and labels' => sub {
    $bsky->beginAgeAssurance( email => 'me@example.com', language => 'en', countryCode => 'US' );
    is $last_post->{method}, 'app.bsky.ageassurance.begin', 'beginAgeAssurance routes correctly';
    ok $bsky->getAgeAssuranceConfig(),                     'getAgeAssuranceConfig returns config';
    ok $bsky->getAgeAssuranceState( countryCode => 'US' ), 'getAgeAssuranceState returns state';
    my $labels = $bsky->queryLabels( uriPatterns => ['at://did:plc:x/*'] );
    is $labels->[0]{val}, 'porn', 'queryLabels unwraps labels';
};
#
done_testing();
