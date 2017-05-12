use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Fatal;
use DateTime;
use BusyBird::DateTime::Format;
use Storable qw(dclone);
use lib "t";
use testlib::CrazyStatus qw(crazy_statuses);

BEGIN {
    use_ok('BusyBird::Util', 'sort_statuses');
}

sub dtstr {
    my ($epoch) = @_;
    return BusyBird::DateTime::Format->format_datetime(
        DateTime->from_epoch(epoch => $epoch, time_zone => 'UTC')
    );
}

sub test_sort {
    my ($in_statuses, $exp_statuses, $msg) = @_;
    my $got_statuses = sort_statuses($in_statuses);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply(
        $got_statuses,
        $exp_statuses,
        $msg
    ) or do {
        diag("ID: " . $_->{id}) foreach @$got_statuses;
    };
}

{
    my @orig = (
        {id =>  0, created_at => dtstr(16000), busybird => { acked_at => dtstr(44192) }},
        {id =>  1, busybird => {acked_at => dtstr(32921)}},
        {id =>  2, created_at => dtstr(21834), busybird => { acked_at => dtstr(88321) }},
        {id =>  3, created_at => dtstr(4440)},
        {id =>  4, busybird => {acked_at => dtstr(44192)}},
        {id =>  5, busybird => {acked_at => ""}},
        {id =>  6, created_at => dtstr(1200)},
        {id =>  7, created_at => dtstr(383911), busybird => { acked_at => dtstr(55432) }},
        {id =>  8, created_at => dtstr(393922), busybird => { acked_at => dtstr(88321) }},
        {id =>  9, created_at => dtstr(5000)},
        {id => 10, created_at => dtstr(4440), busybird => { acked_at => "" } },
        {id => 11, },
        {id => 12, created_at => dtstr(5000), busybird => { acked_at => dtstr(44192) }},
        {id => 13, created_at => ""},
        {id => 14, created_at => "", busybird => { acked_at => dtstr(55432) }},
    );
    test_sort(dclone(\@orig), [@orig[5,11,13, 9,3,10,6, 8,2, 14,7, 4,0,12, 1]], "sort ok");
}

{
    note("--- sort crazy statuses");
    my @input = crazy_statuses();
    my $got;
    is(exception { $got = sort_statuses(\@input) }, undef, "sort_statuses() lives");
    my %got_ids = map { $_->{id} => 1 } @$got;
    my %exp_ids = map { $_->{id} => 1 } @input;
    is_deeply \%got_ids, \%exp_ids, "set of statuses preserved.";
}


done_testing();
