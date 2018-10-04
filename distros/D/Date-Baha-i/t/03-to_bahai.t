#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Date::Baha::i';

my %d = to_bahai(
    year  => 2018,
    month => 10,
    day   => 2,
);

my $expected = {
    cycle       => 10,
    cycle_name  => 'Hubb',
    cycle_year  => 4,
    day         => 6,
    day_name    => 'Rahmat',
    dow         => 4,
    dow_name    => 'Fidal',
    kull_i_shay => 1,
    month       => 11,
    month_name  => 'Mashiyyat',
    year        => 175,
    year_name   => 'Dal',
};

is_deeply \%d, $expected, 'to_bahai';

done_testing();
