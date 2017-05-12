#!/usr/bin/perl -w

# $Id: 08group.t,v 1.1 2004/11/05 09:17:14 jv Exp $

use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Data::Hexify'); }

my $data = pack("C*", 0..47);
is(Hexify(\$data, { chunk => 8, group => 2 }), <<'EOD', "small");
  0000: 0001 0203 0405 0607  ........
  0008: 0809 0a0b 0c0d 0e0f  ........
  0010: 1011 1213 1415 1617  ........
  0018: 1819 1a1b 1c1d 1e1f  ........
  0020: 2021 2223 2425 2627   !"#$%&'
  0028: 2829 2a2b 2c2d 2e2f  ()*+,-./
EOD

$data = pack("C*", 0..45);
is(Hexify(\$data, { chunk => 18, group => 6 }), <<'EOD', "large");
  0000: 000102030405 060708090a0b 0c0d0e0f1011  ..................
  0012: 121314151617 18191a1b1c1d 1e1f20212223  .............. !"#
  0024: 242526272829 2a2b2c2d                   $%&'()*+,-        
EOD
