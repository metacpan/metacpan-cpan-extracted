use strict;
use warnings;
use Test::More;
use lib "t";
use BusyBird::Log;
use testlib::HTTP;
use testlib::Timeline_Util qw(status);
use testlib::StatusHTML;
use testlib::Main_Util;
use Plack::Test;
use BusyBird::Main;
use BusyBird::Main::PSGI qw(create_psgi_app);
use BusyBird::StatusStorage::SQLite;
use utf8;

$BusyBird::Log::Logger = undef;

sub create_main {
    my $main = testlib::Main_Util::create_main();
    $main->timeline('test');
    return $main;
}

{
    my $main = create_main();
    my @statuses = map { status($_, $_ + 10) } 0..9;
    $main->timeline('test')->add(\@statuses);
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my @statuses_html = testlib::StatusHTML->new_multiple($tester->request_ok(
            "GET", "/timelines/test/statuses.html?count=5&max_id=7", undef,
            qr/^200$/, "GET statuses.html OK"
        ));
        is(scalar(@statuses_html), 5, "5 status nodes");
        my @exp_ids = reverse(3 .. 7);
        my @exp_levels = reverse(13 .. 17);
        foreach my $status_html (@statuses_html) {
            my $exp_id = shift(@exp_ids);
            my $exp_level = shift(@exp_levels);
            is($status_html->level, $exp_level, "status node level OK");
            is($status_html->id, $exp_id, "status node ID OK");
        }
    };
}

{
    note("--- various status ID renderings");
    my $main = create_main();
    my $timeline = $main->timeline('test');
    foreach my $case (
        {label => "url", in_id => 'http://example.com/', exp_id => 'http://example.com/'},
        {label => "diamond", in_id => 'crazy<>ID', exp_id => 'crazy&lt;&gt;ID'},
        {label => "span tag", in_id => 'crazier<span>ID</span>', exp_id => 'crazier&lt;span&gt;ID&lt;/span&gt;'},
        {label => "space", in_id => 'ID with space', exp_id => 'ID with space'},
        {label => "unicode", in_id => 'Unicode ユニコード ID', exp_id => 'Unicode ユニコード ID'},
    ) {
        $timeline->delete_statuses(ids => undef);
        my $in_status = { id => $case->{in_id} };
        $timeline->add([$in_status]);
        test_psgi create_psgi_app($main), sub {
            my $tester = testlib::HTTP->new(requester => shift);
            my @statuses_html = testlib::StatusHTML->new_multiple($tester->request_ok(
                "GET", "/timelines/test/statuses.html?count=100", undef,
                qr/^200$/, "$case->{label}: GET statuses.html OK"
            ));
            is(scalar(@statuses_html), 1, "$case->{label}: 1 status node");
            is($statuses_html[0]->id, $case->{exp_id}, "$case->{label}: ID OK");
        };
    }
}

{
    note("--- retweet rendering");
    my $main = create_main();
    $main->set_config(
        time_zone => "+0000",
        time_locale => 'en_US',
        time_format => '%Y-%m-%d %H:%M:%S',
        status_permalink_builder => sub { "" },
    );
    my $timeline = $main->timeline('test');
    $timeline->add([{
        id => "retweet_id",
        created_at => "Fri Jun 07 13:50:13 +0900 2013",
        user => { screen_name => "retweeter" },
        busybird => { level => 5 },
        text => 'RT @speaker: I say something!',
        entities => {
            user_mentions => [ { screen_name => 'speaker', indices => [3,11] } ],
        },
        retweeted_status => {
            id => "original_id",
            created_at => "Tue Jun 04 22:12:01 +0000 2013",
            user => { screen_name => 'speaker' },
            text => 'I say something!',
        },
    }]);
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my @statuses_html = testlib::StatusHTML->new_multiple($tester->request_ok(
            "GET", "/timelines/test/statuses.html?count=100", undef,
            qr/^200$/, "GET statuses.html OK"
        ));
        is(scalar(@statuses_html), 1, "1 status node");
        my $status_html = $statuses_html[0];
        is($status_html->id, "retweet_id", "ID: retweet");
        is($status_html->level, 5, "level: retweet");
        is($status_html->username, "speaker", "username: original");
        is($status_html->created_at, "2013-06-04 22:12:01", 'created_at: original');
        is($status_html->text, "I say something!", "text: original");
    };
}

done_testing();

