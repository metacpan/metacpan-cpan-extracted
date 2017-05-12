#
# $Id: BSD-getloadavg.t,v 0.3 2007/04/18 19:37:10 dankogai Exp dankogai $
#
use strict;
use warnings;

use Test::More tests => 5;
#use Test::More qw/no_plan/;
BEGIN { use_ok('BSD::getloadavg') };
my @loadavg =   getloadavg();
is scalar @loadavg, 3, join(", ", @loadavg);
like $loadavg[0], qr/^(0|\d+\.\d+)$/, $loadavg[0];
like $loadavg[1], qr/^(0|\d+\.\d+)$/, $loadavg[1];
like $loadavg[2], qr/^(0|\d+\.\d+)$/, $loadavg[2];

