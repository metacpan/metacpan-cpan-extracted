#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon ':silent', qw/bug/; # Test2::V0 etc.

use Data::Dumper::Interp qw/visnew/;

# Temporary test to try to figure out where the "inline delegation" error is

is(visnew->vis(42), 42);

done_testing();
