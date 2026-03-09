use v5.40;
use Test::More;
use lib 'lib', '../At.pm/lib';
use Bluesky;
use At::Error;
use Time::Moment;
use experimental 'try';

# Mock At instance
{

    package Mock::At;
    use feature 'class';
    no warnings 'experimental::class';

    class Mock::At {
        field $did : param = 'did:plc:mock-user';
        field $last_post;
        field $last_writes = [];
        method did()  {$did}
        method host() {'https://bsky.social'}

        method create_record ( $collection, $record, $rkey = undef ) {
            $last_post = { collection => $collection, record => $record, rkey => $rkey };
            return { uri => "at://$did/$collection/" . ( $rkey // 'mock-rkey' ), cid => 'mock-cid' };
        }

        method get ( $method, $params = {} ) {
            if ( $method eq 'app.bsky.graph.getKnownFollowers' ) {
                return { followers => [ { handle => 'mutual.bsky.social', did => 'did:plc:mutual' } ] };
            }
            if ( $method eq 'app.bsky.feed.getPosts' ) {
                return { posts => [ { cid => 'mock-post-cid' } ] };
            }
            return {};
        }

        method post ( $method, $data = {} ) {
            push @$last_writes, { method  => $method, data => $data };
            return              { success => 1 };
        }
        method last_post()   {$last_post}
        method last_writes() {$last_writes}
        method _now()        { return Time::Moment->now; }

        method http() {
            state $h = bless { token_type => 'Bearer' }, 'Mock::HTTP';

            # Add proxy method to mock http
            {
                no warnings 'redefine', 'once';
                *Mock::HTTP::at_protocol_proxy = sub {undef};
            }
            return $h;
        }
    }
}

# We need to override Bluesky's internal _at_for to return our mock
my $mock = Mock::At->new();
{
    no warnings 'redefine';
    *Bluesky::_at_for = sub {$mock};

    # Also override the internal $at field access if possible, or just the accessor
    *Bluesky::at = sub {$mock};
}

# Re-initialize bsky so it uses the mocked methods if any were cached
my $bsky = Bluesky->new();
subtest 'Threadgate Support' => sub {

    # We need to mock getReplyRefs because createPost calls it
    {
        no warnings 'redefine';
        *Bluesky::getReplyRefs = sub { return undef };
    }
    $bsky->createPost( text => 'Hello with gate', reply_gate => [ 'following', 'mention' ] );
    my $last = $mock->last_post();
    is( $last->{collection},                'app.bsky.feed.threadgate',               'Threadgate record created' );
    is( scalar @{ $last->{record}{allow} }, 2,                                        'Two rules added' );
    is( $last->{record}{allow}[0]{'$type'}, 'app.bsky.feed.threadgate#followingRule', 'Following rule added' );
    is( $last->{record}{allow}[1]{'$type'}, 'app.bsky.feed.threadgate#mentionRule',   'Mention rule added' );
};
subtest 'Known Followers' => sub {
    my $res = $bsky->getKnownFollowers('target.bsky.social');
    is( ref $res,          'ARRAY',              'Returns arrayref' );
    is( $res->[0]{handle}, 'mutual.bsky.social', 'Correct mutual follower returned' );
};
subtest 'Moderation Report' => sub {
    $bsky->report( 'at://did:plc:bad-user/app.bsky.feed.post/123', 'com.atproto.moderation.defs#reasonSpam', 'Testing reports' );
    my $writes = $mock->last_writes();
    my $found  = grep { $_->{method} eq 'com.atproto.moderation.createReport' } @$writes;
    ok( $found, 'Report POSTed' );
};
done_testing();
