#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 121;
use DateTime;
use DateTime::Calendar::ShalivahanaShaka::Southern;

# Source Date Panchanga http://www.datepanchang.com/panchang.asp

is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733042, 'date 1'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733043, 'date 2'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733044, 'date 3'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733045, 'date 4'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733046, 'date 5'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733047, 'date 6'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733048, 'date 7'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733049, 'date 8'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733050, 'date 9'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733051,
    'date 10'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733052,
    'date 11'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733053,
    'date 12'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733054,
    'date 13'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733055,
    'date 14'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733056,
    'date 15'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733057,
    'date 16'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733058,
    'date 17'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733059,
    'date 18'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733060,
    'date 19'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733061,
    'date 20'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733062,
    'date 21'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733063,
    'date 22'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733064,
    'date 23'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733065,
    'date 24'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733066,
    'date 25'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733067,
    'date 26'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733068,
    'date 27'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733069,
    'date 28'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733070,
    'date 29'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733071,
    'date 30'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733072,
    'date 31'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733073,
    'date 32'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733074,
    'date 33'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733075,
    'date 34'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733076,
    'date 35'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733077,
    'date 36'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733078,
    'date 37'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733079,
    'date 38'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733080,
    'date 39'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733081,
    'date 40'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733082,
    'date 41'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733083,
    'date 42'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733084,
    'date 43'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733085,
    'date 44'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733086,
    'date 45'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733087,
    'date 46'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733088,
    'date 47'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733089,
    'date 48'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733090,
    'date 49'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733091,
    'date 50'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733092,
    'date 51'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733093,
    'date 52'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733094,
    'date 53'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733095,
    'date 54'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733096,
    'date 55'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733097,
    'date 56'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733098,
    'date 57'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733099,
    'date 58'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733100,
    'date 59'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733101,
    'date 60'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733102,
    'date 61'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733103,
    'date 62'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733104,
    'date 63'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733105,
    'date 64'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733106,
    'date 65'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733107,
    'date 66'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 11,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733108,
    'date 67'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733109,
    'date 68'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733110,
    'date 69'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733111,
    'date 70'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733112,
    'date 71'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733113,
    'date 72'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733114,
    'date 73'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733115,
    'date 74'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733116,
    'date 75'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733117,
    'date 76'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733118,
    'date 77'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733119,
    'date 78'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733120,
    'date 79'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733121,
    'date 80'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733122,
    'date 81'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733123,
    'date 82'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733124,
    'date 83'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733125,
    'date 84'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733126,
    'date 85'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733127,
    'date 86'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733128,
    'date 87'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733129,
    'date 88'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733130,
    'date 89'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733131,
    'date 90'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733132,
    'date 91'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733133,
    'date 92'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733134,
    'date 93'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733135,
    'date 94'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733136,
    'date 95'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733137,
    'date 96'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1929,
            adhikamasa  => 0,
            masa        => 12,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733138,
    'date 97'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733139,
    'date 98'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733140,
    'date 99'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733141,
    'date 100'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733142,
    'date 101'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733143,
    'date 102'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733144,
    'date 103'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733145,
    'date 104'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733146,
    'date 105'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733147,
    'date 106'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733148,
    'date 107'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733149,
    'date 108'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733150,
    'date 109'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733151,
    'date 110'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733152,
    'date 111'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733153,
    'date 112'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733154,
    'date 113'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733155,
    'date 114'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733156,
    'date 115'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733157,
    'date 116'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733158,
    'date 117'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733159,
    'date 118'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733160,
    'date 119'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733161,
    'date 120'
);
is(
    (
        DateTime::Calendar::ShalivahanaShaka::Southern->new(
            varsha      => 1930,
            adhikamasa  => 0,
            masa        => 1,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733162,
    'date 121'
);
