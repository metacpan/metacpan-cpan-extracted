#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use Crypt::XKCDCommon1949 qw(xkcd_common_1949);

my @words = xkcd_common_1949;
ok @words == 1949, "got right number of results back"