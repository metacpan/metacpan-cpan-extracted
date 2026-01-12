#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Test that all modules compile
my @modules = qw(
    Acme::Claude::Shell
    Acme::Claude::Shell::Query
    Acme::Claude::Shell::Session
    Acme::Claude::Shell::Tools
    Acme::Claude::Shell::Hooks
);

plan tests => scalar(@modules);

for my $module (@modules) {
    use_ok($module) or BAIL_OUT("Failed to load $module");
}

diag("Testing Acme::Claude::Shell $Acme::Claude::Shell::VERSION, Perl $], $^X");

done_testing() unless Test::More->builder->has_plan;
