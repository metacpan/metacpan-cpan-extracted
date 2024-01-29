use Test2::V0;
#
use lib '../lib';
use App::bsky;
#
my $temp = Path::Tiny->tempfile('.bsky.XXXXX');
isa_ok my $cli = App::bsky::CLI->new( config_file => $temp ), ['App::bsky::CLI'];
subtest 'commands' => sub {
    can_ok $cli, $_ for sort qw[
        cmd_showprofile cmd_updateprofile
        cmd_showsession
        cmd_timeline    cmd_tl
        cmd_stream
        cmd_thread
        cmd_post    cmd_delete
        cmd_like    cmd_unlike      cmd_likes
        cmd_repost  cmd_reposts
        cmd_follow  cmd_unfollow    cmd_follows cmd_followers
        cmd_block   cmd_unblock     cmd_blocks
        cmd_login
        cmd_notifications   cmd_notif
        cmd_invitecodes
        cmd_listapppasswords    cmd_addapppassword  cmd_revokeapppassword
        cmd_config
        cmd_help
        cmd_VERSION cmd_version
    ];
};
subtest 'internals' => sub {
    can_ok $cli, $_ for sort qw[err say run config get_config put_config DESTROY];
};
#
done_testing;
