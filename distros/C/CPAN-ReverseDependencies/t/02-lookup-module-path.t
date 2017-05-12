#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 2;
use CPAN::ReverseDependencies;

my $crd = CPAN::ReverseDependencies->new();
my @deps;

ok(defined($crd), "create instance of CPAN::ReverseDependencies");

SKIP: {
    eval { @deps = $crd->get_reverse_dependencies('Module-Path'); };
    skip("looks like you and/or MetaCPAN are offline", 1) if $@;
    ok(grep({ $_ eq 'App-PrereqGrapher' } @deps), 
       "check we got some dependents and App-PrereqGrapher was one of them");
}

