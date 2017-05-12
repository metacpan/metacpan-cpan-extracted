#!perl -T

use strict;
use warnings;

use DateTime                  qw( );
use DateTime::Format::RFC3339 qw( );

my @tests;
BEGIN {
   @tests = (
      [ # UTC
         DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
         '2002-07-01T13:50:05Z',
      ],
      [ # Positive offset
         DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London' ),
         '2002-07-01T13:50:05+01:00',
      ],
      [ # Zero offset
         DateTime->new( year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/London' ),
         '2002-01-01T13:50:05+00:00',
      ],
      [ # Negative offset.
         DateTime->new( year => 2002, month => 1, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'America/New_York' ),
         '2002-01-01T13:50:05-05:00',
      ],
      [ # Offset with non-integral minutes.
         DateTime->new( year => 1880, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'America/New_York' ),
         '1880-01-01T04:56:02Z',
      ],
   );
}

use Test::More tests => 0+@tests;

for (@tests) {
   my ($dt, $expected_str) = @$_;
   $dt->set_formatter('DateTime::Format::RFC3339');
   my $actual_str = "$dt";
   is( $actual_str, $expected_str );
}
