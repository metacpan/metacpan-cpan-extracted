#!perl -w
use strict;
use Test::More tests => 3;
use lib qw(t/dummy);

use_ok("Bryar::Frontend::Mod_perl");

my $class = "Bryar::Frontend::Mod_perl";
# Test the parse_args method exists
ok($class->can("parse_args"), "We can call parse_args");
# Test the output method exists
ok($class->can("output"), "We can call output");

