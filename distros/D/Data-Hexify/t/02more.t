#!/usr/bin/perl -w

# $Id: 02more.t,v 1.2 2004/06/29 14:58:40 jv Exp $

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('Data::Hexify'); }

my $data = pack("C*", 0..255);
is(Hexify(\$data, { length => 48 }),
   <<'EOD', "length");
  0000: 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ................
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
EOD

is(Hexify(\$data, { start => 16, length => 48 }),
   <<'EOD', "start, length");
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0030: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789:;<=>?
EOD

is(Hexify(\$data, { start => 21, length => 48 }),
   <<'EOD', "start, length, lead");
  0010:                15 16 17 18 19 1a 1b 1c 1d 1e 1f       ...........
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0030: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789:;<=>?
  0040: 40 41 42 43 44                                   @ABCD           
EOD

is(Hexify(\$data, { start => 16, first => 32, length => 48 }),
   <<'EOD', "start, length, first");
  0020: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0030: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0040: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789:;<=>?
EOD

is(Hexify(\$data, { start => 16, first => 40, length => 48 }),
   <<'EOD', "start, length, first, lead");
  0020:                         10 11 12 13 14 15 16 17          ........
  0030: 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 26 27  ........ !"#$%&'
  0040: 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 36 37  ()*+,-./01234567
  0050: 38 39 3a 3b 3c 3d 3e 3f                          89:;<=>?        
EOD

is(Hexify(\$data, { start => 3, length => 4 }),
   <<'EOD', "short");
  0000:          03 04 05 06                                ....         
EOD

