#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use Test::More tests=>1;

use_ok("Bio::Sketch");

