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
      'UTC',
      $default_format,
      DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
      '2002-07-01T13:50:05Z',
   ],
);

plan tests => 0+@tests;

for ( @tests ) {
   my ( $name, $format, $dt, $expected_str ) = @$_;
   ( $dt = $dt->clone )
      ->set_formatter( $format );
   my $actual_str = "$dt";
   is( $actual_str, $expected_str, $name );
}
