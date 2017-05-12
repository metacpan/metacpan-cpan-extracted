use strict;
use warnings;
use Test::More;
use Plack::Test;
use lib "t";
use testlib::HTTP;
use BusyBird::StatusStorage::Memory;

BEGIN {
    use_ok("BusyBird");
}

isa_ok busybird, "BusyBird::Main";

{
    busybird->set_config(timeline_list_per_page => 5);
    is busybird->get_config("timeline_list_per_page"), 5, "main config set/get ok";
    busybird->set_config(timeline_list_pager_entry_max => 1);
    is busybird->get_config("timeline_list_per_page"), 5, "main config preserved";
    is busybird->get_config("timeline_list_pager_entry_max"), 1, "main config new set/get ok";
}

busybird->set_config("default_status_storage" => BusyBird::StatusStorage::Memory->new);

isa_ok timeline("hoge"), "BusyBird::Timeline";

{
    my @timelines = busybird->get_all_timelines();
    is scalar(@timelines), 1, "1 timeline installed";
    is $timelines[0]->name, "hoge", "... its name is hoge";
}

{
    my $psgi_app = end;
    is ref($psgi_app), "CODE", "end() returns a code-ref";
    test_psgi $psgi_app, sub {
        my $http = testlib::HTTP->new(requester => shift);
        $http->request_ok("GET", "/timelines/hoge/", undef, qr/^200$/, "GET timeline hoge should be success");
        $http->request_ok("GET", "/timelines/home/", undef, qr/^[45]/, "GET timeline home should be failure");
    };
}

done_testing;

