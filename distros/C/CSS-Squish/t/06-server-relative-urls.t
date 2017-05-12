#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More skip_all => "Functionality non-existant.  (and tests incomplete.)";
use Test::LongString;

use_ok("CSS::Squish");

my $expect = <<'EOT';

EOT

my $result = CSS::Squish->concatenate('t/css/06-server-relative-urls.t');

is_string($result, $expect, "Server-relative URLs work");

