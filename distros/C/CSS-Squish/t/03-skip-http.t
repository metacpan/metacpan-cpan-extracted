#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

use_ok("CSS::Squish");

my $expected = <<'EOT';
@import url("http://example.com/foo.css");
foobar
EOT

my $result = CSS::Squish->concatenate('t/css/03-skip-http.css');

is($result, $expected, "Skip remote URLs");

