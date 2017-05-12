#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 365;
use DateTime;
use DateTime::Calendar::ShalivahanaShaka::Southern;

# Source Date Panchanga http://www.datepanchang.com/panchang.asp

is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732677, 'date 1'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732678, 'date 2'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732679, 'date 3'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732680, 'date 4'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732681, 'date 5'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732682, 'date 6'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732683, 'date 7'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732684, 'date 8'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732685, 'date 9'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732686,
    'date 10'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732687,
    'date 11'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732688,
    'date 12'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732689,
    'date 13'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732690,
    'date 14'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732691,
    'date 15'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732692,
    'date 16'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732693,
    'date 17'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732694,
    'date 18'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732695,
    'date 19'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732696,
    'date 20'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732697,
    'date 21'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732698,
    'date 22'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732699,
    'date 23'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732700,
    'date 24'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732701,
    'date 25'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732702,
    'date 26'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732703,
    'date 27'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732704,
    'date 28'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732705,
    'date 29'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732706,
    'date 30'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732707,
    'date 31'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732708,
    'date 32'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732709,
    'date 33'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732710,
    'date 34'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732711,
    'date 35'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732712,
    'date 36'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732713,
    'date 37'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732714,
    'date 38'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732715,
    'date 39'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732716,
    'date 40'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732717,
    'date 41'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732718,
    'date 42'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732719,
    'date 43'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732720,
    'date 44'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732721,
    'date 45'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732722,
    'date 46'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732723,
    'date 47'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732724,
    'date 48'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732725,
    'date 49'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732726,
    'date 50'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732727,
    'date 51'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732728,
    'date 52'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732729,
    'date 53'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732730,
    'date 54'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732731,
    'date 55'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732732,
    'date 56'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732733,
    'date 57'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732734,
    'date 58'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732735,
    'date 59'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732736,
    'date 60'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732737,
    'date 61'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732738,
    'date 62'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732739,
    'date 63'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732740,
    'date 64'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732741,
    'date 65'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732742,
    'date 66'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732743,
    'date 67'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732744,
    'date 68'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732745,
    'date 69'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732746,
    'date 70'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732747,
    'date 71'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732748,
    'date 72'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732749,
    'date 73'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732750,
    'date 74'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732751,
    'date 75'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732752,
    'date 76'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732753,
    'date 77'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1928,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732754,
    'date 78'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732755,
    'date 79'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732756,
    'date 80'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732757,
    'date 81'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732758,
    'date 82'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732759,
    'date 83'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732760,
    'date 84'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732761,
    'date 85'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732762,
    'date 86'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732763,
    'date 87'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732764,
    'date 88'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732765,
    'date 89'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732766,
    'date 90'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732767,
    'date 91'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732768,
    'date 92'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732769,
    'date 93'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732770,
    'date 94'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732771,
    'date 95'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732772,
    'date 96'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732773,
    'date 97'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732774,
    'date 98'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732775,
    'date 99'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732776,
    'date 100'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732777,
    'date 101'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732778,
    'date 102'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732779,
    'date 103'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732780,
    'date 104'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732781,
    'date 105'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732782,
    'date 106'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732783,
    'date 107'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732784,
    'date 108'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732785,
    'date 109'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732786,
    'date 110'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732787,
    'date 111'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732788,
    'date 112'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732789,
    'date 113'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732790,
    'date 114'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732791,
    'date 115'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732792,
    'date 116'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732793,
    'date 117'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732794,
    'date 118'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732795,
    'date 119'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732796,
    'date 120'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732797,
    'date 121'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732798,
    'date 122'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732799,
    'date 123'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732800,
    'date 124'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732801,
    'date 125'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732802,
    'date 126'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732803,
    'date 127'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732804,
    'date 128'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732805,
    'date 129'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732806,
    'date 130'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732807,
    'date 131'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732808,
    'date 132'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732809,
    'date 133'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732810,
    'date 134'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732811,
    'date 135'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 2,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732812,
    'date 136'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732813,
    'date 137'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732814,
    'date 138'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732815,
    'date 139'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732816,
    'date 140'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732817,
    'date 141'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732818,
    'date 142'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732819,
    'date 143'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732820,
    'date 144'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732821,
    'date 145'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732822,
    'date 146'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732823,
    'date 147'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732824,
    'date 148'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732825,
    'date 149'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732826,
    'date 150'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732827,
    'date 151'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
             masa       => 3,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732828,
    'date 152'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732829,
    'date 153'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732830,
    'date 154'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732831,
    'date 155'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732832,
    'date 156'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732833,
    'date 157'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732834,
    'date 158'
);

TODO: {
    local $TODO = 'Off by one (732836) for some reason';
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732835,
    'date 159'
);

}

is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732836,
    'date 160'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732837,
    'date 161'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732838,
    'date 162'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732839,
    'date 163'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732840,
    'date 164'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732841,
    'date 165'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 1,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732842,
    'date 166'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732843,
    'date 167'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732844,
    'date 168'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732845,
    'date 169'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732846,
    'date 170'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732847,
    'date 171'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732848,
    'date 172'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732849,
    'date 173'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732850,
    'date 174'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732851,
    'date 175'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732852,
    'date 176'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732853,
    'date 177'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732854,
    'date 178'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732855,
    'date 179'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732856,
    'date 180'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732857,
    'date 181'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732858,
    'date 182'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732859,
    'date 183'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732860,
    'date 184'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732861,
    'date 185'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732862,
    'date 186'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732863,
    'date 187'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732864,
    'date 188'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732865,
    'date 189'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732866,
    'date 190'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732867,
    'date 191'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732868,
    'date 192'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732869,
    'date 193'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732870,
    'date 194'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732871,
    'date 195'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732872,
    'date 196'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732873,
    'date 197'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732874,
    'date 198'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732875,
    'date 199'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732876,
    'date 200'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732877,
    'date 201'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732878,
    'date 202'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732879,
    'date 203'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732880,
    'date 204'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732881,
    'date 205'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732882,
    'date 206'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732883,
    'date 207'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732884,
    'date 208'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732885,
    'date 209'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732886,
    'date 210'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732887,
    'date 211'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732888,
    'date 212'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732889,
    'date 213'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732890,
    'date 214'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732891,
    'date 215'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732892,
    'date 216'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732893,
    'date 217'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732894,
    'date 218'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732895,
    'date 219'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732896,
    'date 220'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732897,
    'date 221'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732898,
    'date 222'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732899,
    'date 223'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732900,
    'date 224'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732901,
    'date 225'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732902,
    'date 226'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732903,
    'date 227'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732904,
    'date 228'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732905,
    'date 229'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732906,
    'date 230'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732907,
    'date 231'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732908,
    'date 232'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732909,
    'date 233'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732910,
    'date 234'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732911,
    'date 235'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732912,
    'date 236'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732913,
    'date 237'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732914,
    'date 238'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732915,
    'date 239'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732916,
    'date 240'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732917,
    'date 241'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732918,
    'date 242'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732919,
    'date 243'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732920,
    'date 244'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732921,
    'date 245'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732922,
    'date 246'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732923,
    'date 247'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732924,
    'date 248'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732925,
    'date 249'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732926,
    'date 250'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732927,
    'date 251'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732928,
    'date 252'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732929,
    'date 253'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 5,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732930,
    'date 254'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732931,
    'date 255'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732932,
    'date 256'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732933,
    'date 257'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732934,
    'date 258'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732935,
    'date 259'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732936,
    'date 260'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732937,
    'date 261'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732938,
    'date 262'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732939,
    'date 263'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732940,
    'date 264'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732941,
    'date 265'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732942,
    'date 266'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732943,
    'date 267'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732944,
    'date 268'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732945,
    'date 269'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732946,
    'date 270'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732947,
    'date 271'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732948,
    'date 272'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732949,
    'date 273'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732950,
    'date 274'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732951,
    'date 275'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732952,
    'date 276'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732953,
    'date 277'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732954,
    'date 278'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732955,
    'date 279'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732956,
    'date 280'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732957,
    'date 281'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732958,
    'date 282'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732959,
    'date 283'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 6,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732960,
    'date 284'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732961,
    'date 285'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732962,
    'date 286'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732963,
    'date 287'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732964,
    'date 288'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732965,
    'date 289'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732966,
    'date 290'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732967,
    'date 291'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732968,
    'date 292'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732969,
    'date 293'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732970,
    'date 294'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732971,
    'date 295'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732972,
    'date 296'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732973,
    'date 297'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732974,
    'date 298'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732975,
    'date 299'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732976,
    'date 300'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732977,
    'date 301'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732978,
    'date 302'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732979,
    'date 303'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732980,
    'date 304'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732981,
    'date 305'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732982,
    'date 306'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732983,
    'date 307'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732984,
    'date 308'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732985,
    'date 309'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732986,
    'date 310'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732987,
    'date 311'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732988,
    'date 312'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 7,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732989,
    'date 313'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732990,
    'date 314'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732991,
    'date 315'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732992,
    'date 316'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732993,
    'date 317'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732994,
    'date 318'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732995,
    'date 319'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732996,
    'date 320'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732997,
    'date 321'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732998,
    'date 322'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732999,
    'date 323'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733000,
    'date 324'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733001,
    'date 325'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733002,
    'date 326'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733003,
    'date 327'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733004,
    'date 328'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733005,
    'date 329'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733006,
    'date 330'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733007,
    'date 331'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733008,
    'date 332'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733009,
    'date 333'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733010,
    'date 334'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733011,
    'date 335'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733012,
    'date 336'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733013,
    'date 337'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733014,
    'date 338'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733015,
    'date 339'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733016,
    'date 340'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733017,
    'date 341'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733018,
    'date 342'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733019,
    'date 343'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733020,
    'date 344'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733021,
    'date 345'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733022,
    'date 346'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733023,
    'date 347'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733024,
    'date 348'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733025,
    'date 349'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733026,
    'date 350'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733027,
    'date 351'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733028,
    'date 352'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733029,
    'date 353'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733030,
    'date 354'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733031,
    'date 355'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733032,
    'date 356'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733033,
    'date 357'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733034,
    'date 358'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733035,
    'date 359'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733036,
    'date 360'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733037,
    'date 361'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733038,
    'date 362'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733039,
    'date 363'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733040,
    'date 364'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733041,
    'date 365'
);
