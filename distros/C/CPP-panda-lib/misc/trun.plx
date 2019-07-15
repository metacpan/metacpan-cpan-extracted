#!/usr/bin/env perl
use 5.012;
use lib 't';
use MyTest;
use Test::More;

my $tname = $ARGV[0] or die "usage: $0 <test name>";

Test::Catch::run($tname);

done_testing();

