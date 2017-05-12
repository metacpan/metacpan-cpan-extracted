use strict;
use warnings;
use Test::More;
use BusyBird::Main;
use BusyBird::Timeline;
use BusyBird::StatusStorage::SQLite;
use BusyBird::Log;
use lib "t";
use testlib::Main_Util qw(create_main);

$BusyBird::Log::Logger = undef;

sub create_main_and_timeline {
    my $main = create_main();
    my $timeline = $main->timeline("test");
    return ($main, $timeline);
}


{
    my ($main, $timeline) = create_main_and_timeline();
    note("--- basic config");
    foreach my $case (
        {label => "Main", target => $main},
        {label => "Timeline", target => $timeline}
    ) {
        is($case->{target}->get_config("_this_does_not_exist"), undef, "$case->{label}: get_config() for non-existent item returns undef");
        $case->{target}->set_config("__1" => 1, "__2" => 2);
        is($case->{target}->get_config("__1"), 1, "$case->{label}: set_config() param 1 OK");
        is($case->{target}->get_config("__2"), 2, "$case->{label}: set_config() param 2 OK");
    }
}

{
    note("--- config precedence for _get_timeline_config() method");
    my ($main, $timeline) = create_main_and_timeline();
    $main->set_config("_some_item" => "hoge");
    is($main->get_config("_some_item"), "hoge", "main gives hoge");
    is($timeline->get_config("_some_item"), undef, "timeline gives undef");
    is($main->get_timeline_config("test", "_some_item"), "hoge", "timeline_config gives hoge");
    $timeline->set_config("_some_item", "foobar");
    is($main->get_config("_some_item"), "hoge", "main gives hoge even after timeline config is set");
    is($timeline->get_config("_some_item"), "foobar", "timeline gives foobar after timeline config is set");
    is($main->get_timeline_config("test", "_some_item"), "foobar", "timeline_config gives foobar");
    is($main->get_timeline_config("__no_timeline", "_some_item"), "hoge", "timeline_config for non-existent timeline gives main's config");
    is($main->get_timeline_config("test", "no_item"), undef, "timeline_config for item not existing in either timeline or main gives undef");
}

{
    note("--- default config (_item_for_test)");
    my ($main, $timeline) = create_main_and_timeline();
    foreach my $case (
        {key => "time_zone", exp => "local"},
        {key => "time_format", exp => '%x (%a) %X %Z'},
        {key => "time_locale", exp => $ENV{LC_TIME} || "C"},
        {key => "post_button_url", exp => "https://twitter.com/intent/tweet"},
        {key => "timeline_web_notifications", exp => "simple"},
        {key => "hidden", exp => 0},
        {key => "attached_image_max_height", exp => 360},
        {key => "attached_image_show_default", exp => "hidden"},
        {key => "acked_statuses_load_count", exp => 20},
        {key => "default_level_threshold", exp => 0},
    ) {
        is($main->get_config($case->{key}), $case->{exp}, "$case->{key} get_config OK");
        is($main->get_timeline_config("test", $case->{key}), $case->{exp}, "$case->{key} get_timeline_config OK");
    }
}

{
    note("--- warning for unknown config");
    my @logs = ();
    local $BusyBird::Log::Logger = sub {
        push @logs, \@_;
    };
    my ($main, $timeline) = create_main_and_timeline();

    foreach my $case (
        {label => "main, typo in key", target => $main, key => "timeline_page_entry_max", val => 100},
        {label => "timeline", target => $timeline, key => "THIS DOES NOT EXIST", val => "foo"},
        {label => "timeline, global config", target => $timeline, key => "sharedir_path", val => "/some/path"}
    ) {
        @logs = ();
        $case->{target}->set_config($case->{key}, $case->{val});
        cmp_ok(scalar(grep { $_->[0] eq "warn" } @logs), ">", 0, "$case->{label}: at least 1 warning");
        is($case->{target}->get_config($case->{key}), $case->{val}, "$case->{label}: the config is set anyway");
    }
}

done_testing();
