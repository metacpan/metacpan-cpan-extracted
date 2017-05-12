#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw/ tmpnam /;

use BeePack;

my $dbfile = defined $ENV{BEEPACK_GENERATE_INTEGER_TESTDB}
  ? $ENV{BEEPACK_GENERATE_INTEGER_TESTDB} : tmpnam();
my $tempfile = tmpnam();

my %vals = (
  posfixint => 127,
  negfixint => -32,
  uint8 => 255,
  uint16 => 65535,
  uint32 => 4294967295,
  uint64 => 4294967296,
  int8 => -128,
  int16 => -32768,
  int32 => -2147483648,
  int64 => -2147483649,
);

{
  my $init_beepack = BeePack->open($dbfile,$tempfile);

  isa_ok($init_beepack,'BeePack','$init_beepack');

  for my $k (keys %vals) {
    $init_beepack->set_integer( $k, $vals{$k} );  
  }

  $init_beepack->save;
}

{
  my $beepack_ro = BeePack->open($dbfile);

  isa_ok($beepack_ro,'BeePack','$beepack_ro');

  for my $k (keys %vals) {
    is($beepack_ro->get($k),$vals{$k},'Reading '.$k);
  }
}

done_testing;
