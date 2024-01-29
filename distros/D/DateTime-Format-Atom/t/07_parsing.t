#!perl

use strict;
use warnings;

use Test::More;

use DateTime               qw( );
use DateTime::Format::Atom qw( );

my @tests;

my $default_format = 'DateTime::Format::Atom';

push @tests, (
   [
      undef,
      $default_format,
      '2002-07-01T13:50:05Z',
      DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
   ],
);

plan tests => 0+@tests;

for ( @tests ) {
   my ( $name, $format, $str, $expected_dt ) = @$_;

   $name //= $str;

   my $actual_dt = eval { $format->parse_datetime( $str ) };
   my $e = $@;

   if ( ref( $expected_dt ) eq 'DateTime' ) {
      is( $actual_dt, $expected_dt, $name );
      diag( "Exception: $e" ) if $e;
   } else {
      like( $e, $expected_dt, $name )
   }
}
