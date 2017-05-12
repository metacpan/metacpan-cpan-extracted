use strict;
use warnings;
use Test::More;

use App::LogStats;

test_mode([0], 0);
test_mode([1], 1);
test_mode([0, 1], 0.5);
test_mode([0, 0, 1], 0);
test_mode([0, 1, 1], 1);
test_mode([0, 1, 2], 1);
test_mode([1, 2, 3], 2);
test_mode([1, 2, 3, 3], 3);

done_testing;

sub test_mode {
    my ($list, $expect) = @_;

    my $stats = App::LogStats->new;
    my $r = +{
        0 => +{
            list => $list,
        }
    };
    my $result = $stats->_calc_mode(0, $r);
    is $result, $expect, "list: @{$r->{0}{list}}";
}