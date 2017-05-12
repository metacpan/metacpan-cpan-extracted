#!/usr/bin/perl -w

# $Id: 04show.t,v 1.2 2004/06/29 14:58:40 jv Exp $

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Data::Hexify'); }

my $data = pack("C*", 16..63);

is(Hexify(\$data, { showdata => sub { my $t = shift;
				  $t =~ s/[^0-9]/_/g; $t } }),
   <<'EOD', "showdata: underscore");
  0000: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ________________
  0010: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f  ________________
  0020: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f  0123456789______
EOD
