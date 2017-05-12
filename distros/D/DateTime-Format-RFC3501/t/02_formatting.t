#!perl

use strict;
use warnings;

use Test::More;

use DateTime                 ();
use DateTime::Format::RFC3501();

my @tests = (
    [ # UTC
        DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
        ' 1-Jul-2002 13:50:05 +0000',
    ],
    [ # Positive offset
        DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London' ),
        ' 1-Jul-2002 13:50:05 +0100',
    ],
    [ # Zero offset
        DateTime->new( year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London' ),
        ' 1-Jan-2002 13:50:05 +0000',
    ],
    [ # Negative offset.
        DateTime->new( year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'America/New_York' ),
        ' 1-Jan-2002 13:50:05 -0500',
    ],
    [ # Offset with non-integral minutes.
        DateTime->new( year => 1880, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'America/New_York' ),
        ' 1-Jan-1880 04:56:02 +0000',
    ],
);

plan tests => 0+@tests;

for (@tests) {
    my ($dt, $expected_str) = @$_;
    $dt->set_formatter('DateTime::Format::RFC3501');
    my $actual_str = "$dt";
    is( $actual_str, $expected_str );
}
