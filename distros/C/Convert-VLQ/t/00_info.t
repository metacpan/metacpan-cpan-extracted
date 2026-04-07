#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

ok(1);

# idea from Test::Harness, thanks!
diag(
  "Perl $], ",
  "$^X on $^O"
);
