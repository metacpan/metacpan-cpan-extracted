#!/usr/bin/perl -w

# $Id: 01basic.t,v 1.2 2004/06/29 14:58:40 jv Exp $

use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Data::Hexify'); }

my $data = pack("C*", 0..47);
is(Hexify(\$data), <<'EOD', "basic");
  0000: 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ................
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
EOD

$data = pack("C*", 0..45);
is(Hexify(\$data), <<'EOD', "fill");
  0000: 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ................
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d         !"#$%&'()*+,-  
EOD
