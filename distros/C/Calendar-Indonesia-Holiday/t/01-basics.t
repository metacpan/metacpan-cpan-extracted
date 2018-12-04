#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Calendar::Indonesia::Holiday qw(
                                       list_id_holidays
                                       enum_id_workdays
                                       count_id_workdays
                               );

my $res;

subtest list_id_holidays => sub {
    $res = list_id_holidays(year => 2011, month => 12);
    is($res->[0], 200, "status");
    is(scalar(@{$res->[2]}), 2, "num");
};

subtest "list_id_holidays (is_joint_leave=0)" => sub {
    $res = list_id_holidays(year => 2011, month => 12, is_joint_leave=>0);
    is($res->[0], 200, "status");
    is(scalar(@{$res->[2]}), 1, "num");
};

subtest count_id_workdays => sub {
    $res = count_id_workdays(start_date => '2011-12-01',
                             end_date => '2011-12-31');
    is($res->[0], 200, "status");
    is($res->[2], 21, "num");
};

subtest "count_id_workdays (work_saturdays=1)" => sub {
    $res = count_id_workdays(start_date => '2011-12-01',
                             end_date => '2011-12-31',
                             work_saturdays=>1);
    is($res->[0], 200, "status");
    is($res->[2], 26, "num");
};

subtest "count_id_workdays (observe_joint_leaves=0)" => sub {
    $res = count_id_workdays(start_date => '2011-12-01',
                             end_date => '2011-12-31',
                             observe_joint_leaves=>0);
    is($res->[0], 200, "status");
    is($res->[2], 22, "num");
};

test_year_has_num_of_holidays(2014, 17, 4);
test_year_has_num_of_holidays(2015, 16, 4);
test_year_has_num_of_holidays(2016, 15, 4);
test_year_has_num_of_holidays(2017, 16, 5);
test_year_has_num_of_holidays(2018, 17, 8);
test_year_has_num_of_holidays(2019, 16, 4);

DONE_TESTING:
done_testing;

sub test_year_has_num_of_holidays {
    my ($year, $numh, $numjl) = @_;

    subtest "year $year" => sub {
        my $res;
        $res = list_id_holidays(year=>$year, is_joint_leave=>0);
        is(~~@{$res->[2]}, $numh, "num holidays");
        $res = list_id_holidays(year=>$year, is_joint_leave=>1);
        is(~~@{$res->[2]}, $numjl, "num joint_leave");
    };
}
