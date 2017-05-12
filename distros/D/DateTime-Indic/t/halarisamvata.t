#!perl
#
# $Id$
#
use strict;
use warnings;

use Test::More tests => 31;
use DateTime;
use DateTime::Calendar::HalariSamvata;

is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2064,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733224, 'date 1'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2064,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733225, 'date 2'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2064,
            adhikamasa  => 0,
            masa        => 3,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 30
          )->utc_rd_values
    )[0],
    733226, 'date 3'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733227, 'date 4'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733228, 'date 5'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733229, 'date 6'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733230, 'date 7'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733231, 'date 8'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733232, 'date 9'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733233,
    'date 10'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733234,
    'date 11'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 10
          )->utc_rd_values
    )[0],
    733235,
    'date 12'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733236,
    'date 13'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733237,
    'date 14'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 1,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733238,
    'date 15'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733239,
    'date 16'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733240,
    'date 17'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 0,
            adhikatithi => 0,
            tithi       => 15
          )->utc_rd_values
    )[0],
    733241,
    'date 18'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 1
          )->utc_rd_values
    )[0],
    733242,
    'date 19'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 2
          )->utc_rd_values
    )[0],
    733243,
    'date 20'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 3
          )->utc_rd_values
    )[0],
    733244,
    'date 21'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 4
          )->utc_rd_values
    )[0],
    733245,
    'date 22'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 5
          )->utc_rd_values
    )[0],
    733246,
    'date 23'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 6
          )->utc_rd_values
    )[0],
    733247,
    'date 24'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 7
          )->utc_rd_values
    )[0],
    733248,
    'date 25'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 8
          )->utc_rd_values
    )[0],
    733249,
    'date 26'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 9
          )->utc_rd_values
    )[0],
    733250,
    'date 27'
);

TODO: {

local $TODO = 'Off by one (733252) for some reason';
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 11
          )->utc_rd_values
    )[0],
    733251,
    'date 28'
);

}

is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 12
          )->utc_rd_values
    )[0],
    733252,
    'date 29'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 13
          )->utc_rd_values
    )[0],
    733253,
    'date 30'
);
is(
    (
        DateTime::Calendar::HalariSamvata->new(
            varsha      => 2065,
            adhikamasa  => 0,
            masa        => 4,
            paksha      => 1,
            adhikatithi => 0,
            tithi       => 14
          )->utc_rd_values
    )[0],
    733254,
    'date 31'
);
