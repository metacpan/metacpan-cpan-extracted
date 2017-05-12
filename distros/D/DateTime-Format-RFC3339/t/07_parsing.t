#!perl

use strict;
use warnings;

use Test::More;

use DateTime                  qw( );
use DateTime::Format::RFC3339 qw( );

{
   my @pos_tests = (
      [ '2002-07-01T13:50:05Z',     DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ) ],
      [ '2002-07-01T13:50:05.123Z', DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, nanosecond => 123000000, time_zone => 'UTC' ) ],
   );

   my @neg_tests = (
   );

   plan tests => @pos_tests + @neg_tests;

   for (@pos_tests) {
      my ($str, $expected_dt) = @$_;
      my $actual_dt = eval { DateTime::Format::RFC3339->parse_datetime($str) };
      ok( defined($actual_dt) && $actual_dt eq $expected_dt, $str );
   }

   for (@neg_tests) {
      my ($str, $expected_e) = @$_;
      eval { DateTime::Format::RFC3339->parse_datetime($str) };
      my $actual_e = $@;
      like( $actual_e, $expected_e, $str );
   }
}
