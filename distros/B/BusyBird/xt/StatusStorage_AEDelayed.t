use strict;
use warnings;
use lib "t";
use Test::More;
use BusyBird::Test::StatusStorage qw(:all);
use BusyBird::StatusStorage::SQLite;
use testlib::StatusStorage::AEDelayed;
use testlib::StatusStorage::CrazyStatus qw(test_storage_crazy_statuses);
use AnyEvent;

my $cv;

sub loop {
    $cv = AnyEvent->condvar;
    $cv->recv;
}

sub unloop {
    $cv->send;
}

sub storage {
    my (%backend_args) = @_;
    return testlib::StatusStorage::AEDelayed->new(
        backend => BusyBird::StatusStorage::SQLite->new(path => ':memory:', %backend_args)
    );
}

test_storage_common(storage(), \&loop, \&unloop);
test_storage_ordered(storage(), \&loop, \&unloop);
test_storage_truncation(storage(max_status_num => 2, hard_max_status_num => 2), {hard_max => 2, soft_max => 2}, \&loop, \&unloop);
test_storage_crazy_statuses(storage(), \&loop, \&unloop);

done_testing();
