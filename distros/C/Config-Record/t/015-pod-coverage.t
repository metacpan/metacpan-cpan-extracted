# -*- perl -*-

use Test::More;
use strict;
use warnings;
eval "use Test::Pod::Coverage 1.00 tests => 1";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
pod_coverage_ok("Config::Record", { pod_from => "lib/Config/Record.pod"});
