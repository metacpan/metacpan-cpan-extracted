#!perl

use strict;
use warnings;
use Test::More;

use Browser::Open qw(
  open_browser
  open_browser_cmd
  open_browser_cmd_all
);

my $cmd = open_browser_cmd();
if ($cmd) {
  ok($cmd,    "got command '$cmd'");
  
SKIP: {
  skip "Won't test execution on MSWin32", 1 if $^O eq 'MSWin32';
  ok(-x $cmd, '... and we can execute it');
}

  diag("Found '$cmd' for '$^O'");

  ok(open_browser_cmd_all(), '... and the all commands version is also ok');
}
else {
  $cmd = open_browser_cmd_all();
  if ($cmd) {
    pass("Found command in the 'all' version ($cmd)");
  }
  else {
    diag("$^O - need more data");
    pass("We can't make popcorn without corn");
  }
}
done_testing();
