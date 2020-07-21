#!/usr/bin/perl
use Test::More;
use lib '.';
require "t/test-lib.pl";

use_ok("Calendar::Schedule", ':all');

my $c = getfile('t/01-example1');
my $o; eval $c;
# for test development:
# putfile('t/01-example1.html', $o);
my $expected_o = getfile('t/01-example1.html');
is($o,$expected_o,'01-example1');

done_testing();
