#!perl

BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for "smoke bot" testing');
  }
}


use strict;
use warnings;
use Test::More;

use Browser::Open qw( open_browser_cmd_all );

## Ignore $^O restrictions for a moment
my $cmd = open_browser_cmd_all();
diag("Found '$cmd' for '$^O'") if $cmd;

pass('thank you for your time to make Browser::Open better');
done_testing();