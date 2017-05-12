use strict;
use warnings;
use Test::More;

use App::LogStats;

test_median([0] => 0);
test_median([3] => 3);
test_median([1, 3] => 2);
test_median([2, 3] => 2.5);
test_median([1, 1, 3] => 1);
test_median([1, 2, 3] => 2);
test_median([2, 2, 3] => 2);
test_median([1, 3, 3] => 3);
test_median([1, 1, 1, 3] => 1);
test_median([1, 1, 2, 3] => 1.5);

done_testing;

sub test_median {
    my ($list, $expect) = @_;

    my $stats = App::LogStats->new;
    my $r = +{
        0 => +{
            list => $list,
        }
    };
    my $result = $stats->_calc_median(0, $r);
    is $result, $expect, "list: @{$r->{0}{list}}";
}
