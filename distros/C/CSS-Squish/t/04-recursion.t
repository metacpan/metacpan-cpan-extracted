#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

use_ok("CSS::Squish");

my $expected = <<'EOT';

/**
  * From t/css/04-recursion.css: @import "foo/04-recursion-2.css";
  */


/**
  * From t/css/foo/04-recursion-2.css: @import "04-recursion-3.css";
  */

level 3

/** End of 04-recursion-3.css */

level 2

/** End of foo/04-recursion-2.css */

foobar
EOT

my $result = CSS::Squish->concatenate('t/css/04-recursion.css');

is($result, $expected, "Recursive import");

