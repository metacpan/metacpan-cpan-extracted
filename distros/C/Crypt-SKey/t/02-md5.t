# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test;
BEGIN {
  require 't/common.pl';
  need_module('Digest::MD5');
}  

BEGIN { plan tests => 7 }

use strict;
use Crypt::SKey qw(key compute);
$Crypt::SKey::HASH = 'MD5';

ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{
  my $line = compute(50, 'fo099804', 'pwd');
  ok($line, 'SOD SOAK SLAB MONT STEW OVAL', $line);
}

{
  my @lines = compute(50, 'fo099804', 'pwd', 4);
  ok($lines[0], 'ON TALK MOO TORE GAG BEY', $lines[0]);
  ok($lines[1], 'MASK PI LASS BELA GAB NIT',  $lines[1]);
  ok($lines[2], 'ROWS SLOG TOP CAM FROM BUSY',  $lines[2]);
  ok($lines[3], 'SOD SOAK SLAB MONT STEW OVAL', $lines[3]);
}

{
  # Try hex mode
  local $Crypt::SKey::HEX = 1;
  ok compute(1234, "test5678", "secret"), "61BEB7029243EC0E";
}
