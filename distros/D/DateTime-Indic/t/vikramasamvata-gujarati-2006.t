#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 61;
use DateTime;
use DateTime::Calendar::VikramaSamvata::Gujarati;

# Source Janmabhoomi Panchanga (2007-2009)

is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732616, 'date 1'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732617, 'date 2'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732618, 'date 3'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732619, 'date 4'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    732620, 'date 5'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732621, 'date 6'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732622, 'date 7'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732623, 'date 8'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732624, 'date 9'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732625,
    'date 10'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732626,
    'date 11'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732627,
    'date 12'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732628,
    'date 13'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732629,
    'date 14'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732630,
    'date 15'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732631,
    'date 16'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732632,
    'date 17'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732633,
    'date 18'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732634,
    'date 19'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 8,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732635,
    'date 20'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732636,
    'date 21'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732637,
    'date 22'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732638,
    'date 23'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732639,
    'date 24'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732640,
    'date 25'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732641,
    'date 26'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732642,
    'date 27'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732643,
    'date 28'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732644,
    'date 29'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732645,
    'date 30'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732646,
    'date 31'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732647,
    'date 32'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732648,
    'date 33'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732649,
    'date 34'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732650,
    'date 35'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732651,
    'date 36'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732652,
    'date 37'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732653,
    'date 38'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732654,
    'date 39'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732655,
    'date 40'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732656,
    'date 41'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732657,
    'date 42'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 1,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732658,
    'date 43'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    732659,
    'date 44'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732660,
    'date 45'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732661,
    'date 46'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732662,
    'date 47'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    732663,
    'date 48'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    732664,
    'date 49'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 9,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    732665,
    'date 50'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    732666,
    'date 51'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    732667,
    'date 52'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    732668,
    'date 53'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    732669,
    'date 54'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    732670,
    'date 55'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    732671,
    'date 56'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    732672,
    'date 57'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    732673,
    'date 58'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    732674,
    'date 59'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    732675,
    'date 60'
);
is(
    (
        DateTime::Calendar::VikramaSamvata::Gujarati->new(
            varsha      => 2063,
            adhikamasa  => 0,
            masa        => 10,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    732676,
    'date 61'
);
