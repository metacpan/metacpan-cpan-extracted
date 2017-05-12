#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

use_ok("CSS::Squish");

my $expected_result = <<'EOT';


/**
  * From t/css/01-basic.css: @import "01-basic-import.css";
  */

inside 01-basic-import.css

/** End of 01-basic-import.css */

body { color: blue; }

EOT

my $result = CSS::Squish->concatenate('t/css/01-basic.css');

is($result, $expected_result, "Basic import");

