use strict;
use warnings;
use Test::More;

use App::LogStats;

test_stddev([0], 0);
test_stddev([1], 0);
test_stddev([0, 1], qr/^0\.7071/);
test_stddev([1, 2, 3], 1);
test_stddev([0, 1, 1], qr/^0\.57735/);
test_stddev([0, 1, 2], 1);
test_stddev([1, 2, 3], 1);
test_stddev([1, 2, 3, 3], qr/^0\.95742/);

done_testing;

sub test_stddev {
    my ($list, $expect) = @_;

    my $stats = App::LogStats->new;
    my $r = +{
        0 => +{
            average => App::LogStats::_calc_average($list),
            list    => $list,
        }
    };
    my $result = $stats->_calc_stddev(0, $r);

    if (ref($expect) eq 'Regexp') {
        like $result, $expect, "list: @{$r->{0}{list}}";
    }
    else {
        is $result, $expect, "list: @{$r->{0}{list}}";
    }
}
