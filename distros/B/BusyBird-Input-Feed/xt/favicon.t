use strict;
use warnings;
use Test::More;
use BusyBird::Input::Feed;
use LWP::UserAgent;
use File::Spec;

my $input = BusyBird::Input::Feed->new;
my $ua = LWP::UserAgent->new;
$ua->env_proxy;

if(!$ENV{BB_INPUT_FEED_NETWORK_TEST}) {
    plan('skip_all', "Set BB_INPUT_FEED_NETWORK_TEST environment to enable the test");
    exit;
}

{
    note('--- case: <link rel="shortcut icon"> exists');
    my $got_statuses = $input->parse_file(File::Spec->catfile(qw(. t samples stackoverflow.atom)));
    my $got_status = $got_statuses->[0];
    like $got_status->{user}{profile_image_url}, qr{^https?://}, "user.profile_image_url looks like URL";
    my $res = $ua->get($got_status->{user}{profile_image_url});
    ok $res->is_success, "Succeed to get favicon $got_status->{user}{profile_image_url}";
}

{
    note('--- case: <link rel="shortcut icon"> does not exist');
    my $got_statuses = $input->parse_url('https://forums.ubuntulinux.jp/extern.php?action=active&type=RSS&nfid=21');
    cmp_ok scalar(@$got_statuses), ">", 0, "at least 1 status loaded";
    my $got_status = $got_statuses->[0];
    like $got_status->{user}{profile_image_url}, qr{https?://}, "user.profile_image_url looks like URL";
    my $res = $ua->get($got_status->{user}{profile_image_url});
    ok $res->is_success, "Succeed to get favicon $got_status->{user}{profile_image_url}";
}

{
    note('--- case: no favicon');
    my $got_statuses = $input->parse_file(File::Spec->catfile(qw(. t samples pukiwiki_rss09.rss)));
    my $got_status = $got_statuses->[0];
    is $got_status->{user}{profile_image_url}, undef, "user.profile_image_url should be undef because this site does not have favicon";
}

done_testing;


