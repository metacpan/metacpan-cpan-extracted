#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 1;
use App::mqtt2job qw/ helper_v1 /;

# vary testing times when test called from mqtt2job
my $sleep = $ARGV[0] || 0;
sleep($sleep);

like(helper_v1({rm => 1}), qr/\.pl$/, "Generated script template scalar" );

done_testing();

