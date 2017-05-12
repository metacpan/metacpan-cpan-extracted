#!perl

use strict;
use warnings;
use Test::More;
use Convert::ModHex 'modhex2hex', 'modhex2dec', 'hex2modhex', 'dec2modhex';

my @test_cases = (
  ['cbcc', '0100', '256'],
  ['cubd', '0e12', '3602'],
  ['fvvu', '4ffe', '20478'],
  ['ducd', '2e02', '11778'],
  ['fktl', '49da', '18906'],
  ['icih', '7076', '28790'],
  ['fggf', '4554', '17748'],
  ['gnuj', '5be8', '23528'],
  ['gfiu', '547e', '21630'],
  ['rcbf', 'c014', '49172'],
  ['rekn', 'c39b', '50075'],
);

for my $tc (@test_cases) {
  my ($m, $h, $d) = @$tc;
  my $m2h = modhex2hex($m);
  my $m2d = modhex2dec($m);
  my $h2m = hex2modhex($h);
  my $d2m = dec2modhex($d);

  is($m2h, $h, "modhex2hex ok for '$m'");
  is($m2d, $d, "modhex2hex ok for '$m'");
  is($h2m, $m, "hex2modhex ok for '$h'");
  is($d2m, $m, "dec2modhex ok for '$d'");
}

done_testing();
