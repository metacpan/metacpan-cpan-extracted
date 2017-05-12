#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;
use Test::More;

use Browser::Open qw( open_browser );

my $ok = open_browser('http://127.0.0.1/');
ok(defined($ok), 'Found command to open a browser');
is($ok, 0, 'No problems running command');

done_testing();