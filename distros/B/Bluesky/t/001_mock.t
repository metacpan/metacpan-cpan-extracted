use v5.40;
use Test2::V0;
use blib;
use Bluesky;
use At::Error;
use Time::Moment;
use experimental 'try';

# Mock At: override just the methods Bluesky reaches for.
my ( $last_post, @last_writes );
my $mock_at = mock 'At' => (
    override => [
        did           => sub {'did:plc:mock-user'},
        host          => sub {'https://bsky.social'},
        _now          => sub { Time::Moment->now },
        create_record => sub ( $self, $collection, $record, $rkey = undef ) {
            $last_post = { collection => $collection, record => $record, rkey => $rkey };
            return { uri => "at://did:plc:mock-user/$collection/" . ( $rkey // 'mock-rkey' ), cid => 'mock-cid' };
        },
        get => sub ( $self, $method, $params = {} ) {
            return { followers => [ { handle => 'mutual.bsky.social', did => 'did:plc:mutual' } ] } if $method eq 'app.bsky.graph.getKnownFollowers';
            return { posts     => [ { cid    => 'mock-post-cid' } ] }                               if $method eq 'app.bsky.feed.getPosts';
            return {};
        },
        post => sub ( $self, $method, $data = {} ) {
            push @last_writes, { method  => $method, data => $data };
            return             { success => 1 };
        },
    ]
);
my $bsky = Bluesky->new();
subtest 'Threadgate Support' => sub {

    # We need to mock getReplyRefs because createPost calls it
    {
        no warnings 'redefine';
        *Bluesky::getReplyRefs = sub { return undef };
    }
    $bsky->createPost( text => 'Hello with gate', reply_gate => [ 'following', 'mention' ] );
    my $last = $last_post;
    is $last->{collection},                'app.bsky.feed.threadgate',               'Threadgate record created';
    is scalar @{ $last->{record}{allow} }, 2,                                        'Two rules added';
    is $last->{record}{allow}[0]{'$type'}, 'app.bsky.feed.threadgate#followingRule', 'Following rule added';
    is $last->{record}{allow}[1]{'$type'}, 'app.bsky.feed.threadgate#mentionRule',   'Mention rule added';
};
subtest 'Postgate Support' => sub {
    $bsky->createPost( text => 'No quotes please', post_gate => ['disable'] );
    my $last = $last_post;
    is $last->{collection},                         'app.bsky.feed.postgate',             'Postgate record created';
    is scalar @{ $last->{record}{embeddingRules} }, 1,                                    'One rule added';
    is $last->{record}{embeddingRules}[0]{'$type'}, 'app.bsky.feed.postgate#disableRule', 'Disable rule added';
    ok defined $last->{rkey}, 'rkey provided for postgate';
};
subtest 'Known Followers' => sub {
    my $res = $bsky->getKnownFollowers('target.bsky.social');
    is ref $res,          'ARRAY',              'Returns arrayref';
    is $res->[0]{handle}, 'mutual.bsky.social', 'Correct mutual follower returned';
};
subtest 'Moderation Report' => sub {
    $bsky->report( 'at://did:plc:bad-user/app.bsky.feed.post/123', 'com.atproto.moderation.defs#reasonSpam', 'Testing reports' );
    my $found = grep { $_->{method} eq 'com.atproto.moderation.createReport' } @last_writes;
    ok $found, 'Report POSTed';
};
#
done_testing();
