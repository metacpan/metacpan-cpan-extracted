#! perl

use Test2::V0;
use Test::Alien;
use Alien::LibCIAORegion;

alien_ok 'Alien::LibCIAORegion';
ffi_ok { symbols => ['regParse', 'regToStringRegion'] }, with_subtest {
  my($ffi) = @_;

  # ignore memory leaks
  my $parse = $ffi->function( regParse => ['string'] => 'opaque');
  my $to_string = $ffi->function( regToStringRegion => ['opaque'] => 'string');
  my $region = $parse->call( 'point(0,0)');
  my $string = $to_string->call( $region );
  is $string, 'Point(0,0)';
};

done_testing;
