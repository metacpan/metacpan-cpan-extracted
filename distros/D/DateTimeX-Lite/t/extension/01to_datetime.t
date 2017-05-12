use strict;
use Test::More;
BEGIN {
    eval { require DateTime };
    if ($@) {
        plan(skip_all => "DateTime not available");
    } else {
        plan(tests => 1);
    }
}

use DateTimeX::Lite;

my $dt_lite = DateTimeX::Lite->new(year => 2008, month => 1, day => 1);
my $dt = $dt_lite->to_datetime;

is_deeply([ $dt_lite->utc_rd_values ], [ $dt->utc_rd_values ]);