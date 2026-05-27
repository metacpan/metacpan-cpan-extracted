#!/usr/bin/env perl
# Syntax-check every eg/*.pl example. Catches API-drift regressions
# in the examples without needing live infrastructure - perl -c
# compiles the script (including `use` of dependencies) without
# running it. Heavy deps that examples may load (DBD::Pg, AnyEvent,
# Net::Kafka, etc.) are tolerated as compile errors are not fatal -
# we report them but don't fail the test, since author runs may not
# have every example's dependencies installed.
use strict;
use warnings;
use Test::More;
use File::Spec;

plan skip_all => 'set RELEASE_TESTING=1 to run eg-compile tests'
    unless $ENV{RELEASE_TESTING};

my @scripts = sort glob('eg/*.pl');
plan skip_all => 'no eg/*.pl scripts found' unless @scripts;

for my $script (@scripts) {
    # Run perl -c with blib/ on @INC so the examples can find the
    # built module. Capture both stdout and stderr for the diag.
    my $cmd = qq{$^X -Iblib/lib -Iblib/arch -c "$script" 2>&1};
    my $out = `$cmd`;
    my $rc  = $? >> 8;
    if ($rc == 0) {
        pass("eg/$script compiles");
    } else {
        # Distinguish "missing optional dep" (skipped) from real errors.
        if ($out =~ /Can't locate (\S+) in \@INC/) {
            my $dep = $1;
          SKIP: { skip "eg/$script needs optional dep $dep", 1; }
        } else {
            fail("eg/$script: $out");
        }
    }
}

done_testing();
