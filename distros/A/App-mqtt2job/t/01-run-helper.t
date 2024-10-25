#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 1;
use App::mqtt2job qw/ ha_helper_cfg /;

# vary testing times when test called from mqtt2job
my $sleep = $ARGV[0] || 0;
sleep($sleep);

like(ha_helper_cfg(), qr/^=====/, "Generated ha helper scalar" );

done_testing();

