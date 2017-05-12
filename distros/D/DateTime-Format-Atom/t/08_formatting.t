#!perl

use strict;
use warnings;

use Test::More;

use DateTime               qw( );
use DateTime::Format::Atom qw( );

{
   my @tests = (
      [ DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ), '2002-07-01T13:50:05Z' ],
   );

   plan tests => 0+@tests;

   for (@tests) {
      my ($dt, $expected_str) = @$_;
      $dt->set_formatter('DateTime::Format::Atom');
      my $actual_str = "$dt";
      is( $actual_str, $expected_str );
   }
}
