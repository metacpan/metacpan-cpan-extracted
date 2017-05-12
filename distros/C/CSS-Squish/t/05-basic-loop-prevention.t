#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;
use Test::LongString;

use_ok("CSS::Squish");

my $expected = <<'EOT';

/** Skipping: 
@import "05-loop-prevention.css";
  */

foobar
EOT

my $result = CSS::Squish->concatenate('t/css/05-loop-prevention.css');

is_string($result, $expected, "Skip direct loop-causing imports");



