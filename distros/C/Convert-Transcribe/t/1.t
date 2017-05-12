# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# We only test whether we can load the module in this first test.

use Test;
BEGIN { plan tests => 1 };
use Convert::Transcribe;
ok(1);
