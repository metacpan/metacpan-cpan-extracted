use Test;
BEGIN {
  require 't/common.pl';
  need_module('Digest::SHA');
}

BEGIN { plan tests => 7 }

use strict;
use Crypt::SKey qw(key compute);
$Crypt::SKey::HASH = 'SHA1';

ok(1);

{
  my $line = compute(2468, 'testme32', 'notsecret');
  ok($line, 'RAVE THUG BORG NEWT BLAT ON');
}

{
  my @lines = compute(50, 'fo099804', 'pwd', 4);
  ok($lines[0], 'LAWN TRAM GUM COOT JULY LOG');
  ok($lines[1], 'GILD GLOW SEN EACH FILM FORM');
  ok($lines[2], 'ELAN BRAD SO MOST DUD WARN');
  ok($lines[3], 'DOLL NOR SAP HOOT SOFA CAT');
}

{
  # Try hex mode
  local $Crypt::SKey::HEX = 1;
  ok compute(1234, "test5678", "secret"), "3508A6B41AC09FC2";
}
