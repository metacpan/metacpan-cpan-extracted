#!/usr/bin/perl -w

# $Id: 03align.t,v 1.2 2004/06/29 14:58:40 jv Exp $

use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('Data::Hexify'); }

my $data = pack("C*", 0..255);

is(Hexify(\$data, { start => 16, length => 48, align => 0 }),
   <<'EOD', "start, length");
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0030: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789:;<=>?
EOD

is(Hexify(\$data, { start => 21, length => 48, align => 0 }),
   <<'EOD', "start, length, lead");
  0015: 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24  ........... !"#$
  0025: 25 26 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34  %&'()*+,-./01234
  0035: 35 36 37 38 39 3a 3b 3c 3d 3e 3f 40 41 42 43 44  56789:;<=>?@ABCD
EOD

is(Hexify(\$data, { start => 16, first => 40, length => 48, align => 0 }),
   <<'EOD', "start, length, first");
  0028: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0038: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0048: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789:;<=>?
EOD

is(Hexify(\$data, { start => 3, length => 4, align => 0 }),
   <<'EOD', "short");
  0003: 03 04 05 06                                      ....            
EOD

is(Hexify(\$data, { start => 3, length => 4, first => 7, align => 0 }),
   <<'EOD', "short, first");
  0007: 03 04 05 06                                      ....            
EOD
