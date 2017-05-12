#!/usr/bin/perl

use strict;
use Test::More;

# plan skip_all => "Test::Prereq cannot handle this distribition";

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;
prereq_ok();
