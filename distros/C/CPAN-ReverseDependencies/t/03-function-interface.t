#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 1;
use CPAN::ReverseDependencies qw/ get_reverse_dependencies /;

my @deps;

SKIP: {
    eval { @deps = get_reverse_dependencies('Module-Path'); };
    skip("looks like you and/or MetaCPAN are offline", 1) if $@;
    ok(grep({ $_ eq 'App-PrereqGrapher' } @deps), 
       "check we got some dependents and App-PrereqGrapher was one of them");
}

