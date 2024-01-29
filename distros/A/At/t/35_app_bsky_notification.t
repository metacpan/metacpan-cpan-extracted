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
subtest 'notificaton' => sub {
    my $notification = At::Lexicon::app::bsky::notification->new(
        author => {
            avatar      => 'https://fake.image/test.jpeg',
            description => 'random description for a test',
            did         => 'did:plc:sLklfdsaio23jklazfvjgyyqo',
            displayName => 'Totally A. Test',
            handle      => 'test.com',
            indexedAt   => '2023-10-11T07:09:20.887Z',
            labels      => [],
            viewer      => { blockedBy => !1, muted => !1, },
        },
        cid           => 'fjdsa9f38warpjcmaur83mrjakrfufca8w9rtmuwjaiocuyfdsar83aw9ru',
        indexedAt     => '2023-11-20T23:03:53.219Z',
        isRead        => !1,
        labels        => [],
        reason        => 'like',
        reasonSubject => 'at://did:plc:lfdsjkalfeiwoaeaaf923fsa/app.bsky.feed.post/9fdkfakfods89',
        record        => {
            '$type'     => 'app.bsky.feed.like',
            'createdAt' => '2023-11-22T23:40:53.555Z',
            'subject'   => {
                cid => 'fjdsa9f38warpjcmaur83mrjakrfufca8w9rtmuwjaiocuyfdsar83aw9ru',
                uri => 'at://did:plc:lfdsjkalfeiwoaeaaf923fsa/app.bsky.feed.post/9fdkfakfods89',
            },
        },
        uri => 'at://did:plc:ba9bo32fksdaf2398ua8c9ap/app.bsky.feed.like/8ufdsjdsoapfj',
    );
    isa_ok( $notification, ['At::Lexicon::app::bsky::notification'], '::notificaton' );
};
subtest 'live' => sub {
    my $bsky = At::Bluesky->new( identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );
    my $count;
    subtest 'notification_getUnreadCount' => sub {
        ok my $res = $bsky->notification_getUnreadCount(), '$bsky->notification_getUnreadCount()';
        $count = $res->{count};
        diag $count == 1 ? '1 unseen notification' : $count . ' unseen notificatons';
    };
    subtest 'notification_listNotifications' => sub {
    SKIP: {
            skip 'no unread notifications' unless $count;
            ok my $res = $bsky->notification_listNotifications(), '$bsky->notification_listNotifications()';
            isa_ok $res->{notifications}->[0], ['At::Lexicon::app::bsky::notification'], '...returns a list of ::bsky::notification objects';
        }
    };
    subtest 'notification_updateSeen' => sub {
        my $lastyear = time - 31536000;
        ok $bsky->notification_updateSeen($lastyear), '$bsky->notification_updateSeen( ' . $lastyear . ' )';
    };

    # See https://github.com/bluesky-social/atproto/discussions/1914
    can_ok $bsky, 'notification_registerPush';
};
#
done_testing;
