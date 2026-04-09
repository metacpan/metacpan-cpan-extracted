#!/usr/bin/env perl
#
# App wrapper for the packed counter example.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use PackedCounter;

PackedCounter::run();
