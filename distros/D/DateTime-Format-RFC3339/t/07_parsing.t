#!perl

use strict;
use warnings;

use Test::More;

use DateTime                  qw( );
use DateTime::Format::RFC3339 qw( );

my @tests;

my $default_format = 'DateTime::Format::RFC3339';

push @tests, (
   [
      undef,
      $default_format,
      '2002-07-01T13:50:05Z',
      DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
   ],
   [
      undef,
      $default_format,
      '2002-07-01T13:50:05.123Z',
      DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, nanosecond => 123000000, time_zone => 'UTC' ),
   ],
);

my $dt = DateTime->new( year => 2023, month => 12, day => 31, hour => 23, minute => 59, second => 59, time_zone => 'UTC' );

push @tests, (
   [
      undef,
      $default_format,
      '2023-12-31T23:59:59Z',
      $dt,
   ],
   [
      undef,
      $default_format,
      '2023/12/31T23:59:59Z',
      qr/^Incorrectly formatted date\b/,
   ],
   [
      undef,
      $default_format,
      '2023-12-31T23-59-59Z',
      qr/^Incorrectly formatted time\b/,
   ],
   [
      undef,
      $default_format,
      '2023-12-31T23:59:59Y',
      qr/^Incorrect or missing time zone offset\b/,
   ],
   [
      undef,
      $default_format,
      '2023-12-31T23:59:59ZZ',
      qr/^Incorrectly formatted datetime\b/,
   ],
);

push @tests, (
   [
      "sep => undef, sep_re => undef",
      DateTime::Format::RFC3339->new( sep => undef, sep_re => undef ),
      '2023-12-31T23:59:59Z',
      $dt,
   ],
   [
      "sep => 'T', sep_re => undef",
      DateTime::Format::RFC3339->new( sep => 'T', sep_re => undef ),
      '2023-12-31T23:59:59Z',
      $dt,
   ],
   [
      "sep => ' ', sep_re => undef",
      DateTime::Format::RFC3339->new( sep => ' ', sep_re => undef ),
      '2023-12-31 23:59:59Z',
      $dt,
   ],
   [
      "sep => ' ', sep_re => qr/\\s/",
      DateTime::Format::RFC3339->new( sep => ' ', sep_re => qr/\s/ ),
      "2023-12-31\t23:59:59Z",
      $dt,
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
