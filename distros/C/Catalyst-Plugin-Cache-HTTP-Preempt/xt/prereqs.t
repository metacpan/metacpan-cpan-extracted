#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required to test dependencies" if $@;

# It seems to ignore test_requires

plan skip_all => "Bug in Test::Prereq";

prereq_ok();



