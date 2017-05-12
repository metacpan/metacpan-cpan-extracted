#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
#all_pod_coverage_ok({  also_private => [ '/^[A-Z_]+$/' ], });

my @modules = all_modules();

my @testmodules;

my $tests = 0;

foreach my $module (@modules) {
    # currently no special handling
    $tests++;
    push @testmodules, $module;
}

plan tests => $tests;

# General modules
foreach my $module (@testmodules) {
	my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
	pod_coverage_ok( $module, $trustparents );
}

done_testing();
