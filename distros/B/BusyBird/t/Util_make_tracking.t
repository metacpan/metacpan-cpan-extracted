use strict;
use warnings;
use Test::More;
use BusyBird::Util qw(make_tracking);
use BusyBird::StatusStorage::SQLite;
use BusyBird::Timeline;
use BusyBird::Test::StatusStorage qw(:status);
use Scalar::Util qw(refaddr);
use lib "t";
use testlib::Timeline_Util qw(sync status test_content);

sub create_storage {
    return BusyBird::StatusStorage::SQLite->new(path => ':memory:');
}

sub setup_tracking {
    my $storage = create_storage();
    my $main = BusyBird::Timeline->new(name => "main", storage => $storage);
    my $tracking = BusyBird::Timeline->new(name => "tracking", storage => $storage);
    is refaddr(make_tracking($tracking, $main)), refaddr($tracking),
        "make_tracking() should return the tracking timeline object";
    my @main_filter_log = ();
    $main->add_filter(sub {
        my ($statuses) = @_;
        push @main_filter_log, [map { +{%$_} } @$statuses];
        return $statuses;
    });
    return ($main, $tracking, \@main_filter_log);
}

{
    my ($main, $tracking, $main_filter_log) = setup_tracking();
    my ($error, $count) = sync($tracking, "add_statuses",
                               statuses => [map {status($_)} 1..5]);
    is $error, undef, "add to tracking timeline OK";
    is $count, 5, "5 statuses added to tracking OK";
    test_content($tracking, {count => "all"}, [reverse 1..5], "tracking timeline content OK");
    test_content($main, {count => "all"}, [reverse 1..5], "main timeline content OK");
    is scalar(@$main_filter_log), 1, "forwarded statuses went through the main timeline's filter";
    test_status_id_list($main_filter_log->[0], [1..5], "all five statuses are forwarded");

    @$main_filter_log = ();
    ($error, $count) = sync($tracking, "add_statuses",
                            statuses => [map {status($_)} 3..7]);
    is $error, undef, "add to tracking timeline OK";
    is $count, 2, "only new statuses are inserted to tracking";
    test_content($tracking, {count => 'all'}, [reverse 1..7], "tracking timeline content OK");
    test_content($main, {count => 'all'}, [reverse 1..7], "main timeline content OK");
    is scalar(@$main_filter_log), 1, "forwarded statuses went through the main timeline's filter";
    test_status_id_list($main_filter_log->[0], [6, 7], "only new statuses are forwarded to the main timeline");

    note("--- input statuses with no ID");
    @$main_filter_log = ();
    my $input_status = status(1);
    delete $input_status->{id};
    $input_status->{text} = "hogehoge";
    ($error, $count) = sync($tracking, "add_statuses",
                            statuses => $input_status);
    is $error, undef, "add to tracking OK";
    is $count, 1, "1 status add OK";
    is scalar(@$main_filter_log), 1, "status forwarded to main filter";
    is scalar(@{$main_filter_log->[0]}), 1, "1 status forwarded";
    is $main_filter_log->[0][0]{id}, undef, "the status is forwarded with its id being undef";
    is $main_filter_log->[0][0]{text}, "hogehoge", "forwarded status text is OK";
}

{
    note("--- mixed input");
    my ($main, $tracking, $main_filter_log) = setup_tracking();
    my ($error, $count) = sync($tracking, "add_statuses",
                               statuses => [map { status($_) } 1..10]);
    is $error, undef, "add OK";
    is $count, 10, "add count OK";

    @$main_filter_log = ();
    my @input_ids = (1, 11, 2, 12, 3, 13, 4, 14);
    my @input = map { my $s = status($_); $s->{text} = "id $_"; $s } @input_ids;
    delete $_->{id} foreach @input[0,1,4];
    ($error, $count) = sync($tracking, "add_statuses",
                            statuses => \@input);
    is $error, undef, "add to tracking OK";
    is $count, 6, "6 statuses added";
    is scalar(@$main_filter_log), 1, "statuses are forwarded to main";
    is scalar(@{$main_filter_log->[0]}), 6, "6 new statuses are forwarded to main";
    is_deeply([map { $_->{text} } @{$main_filter_log->[0]}],
              [map { "id $_" } (1, 11, 12, 3, 13, 14)],
              "ID-less statuses and not-contained-ID statuses are forwarded to main");
}

done_testing;
