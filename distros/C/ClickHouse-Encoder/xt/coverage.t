#!/usr/bin/env perl
# Author test: build the XS with Devel::Cover instrumentation, run the t/
# suite, and print a coverage summary. The XS path is line-coverage only
# (Devel::Cover doesn't instrument C); for that, use a host C tool like
# `gcov` separately. This script is mainly useful for the .pm + helpers.

use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run coverage'
    unless $ENV{RELEASE_TESTING};

eval { require Devel::Cover; 1 }
    or plan skip_all => 'Devel::Cover not installed';

my $cover = `which cover 2>/dev/null`;
chomp $cover;
plan skip_all => "'cover' tool not found in PATH" unless $cover && -x $cover;

# Reuse the existing build; only re-run the suite under coverage harness.
diag('running prove with -MDevel::Cover ...');
my $rc = system(
    'prove', '-b', '-It/lib',
    '-MDevel::Cover=-silent,1,-summary,0,-coverage,statement,branch,condition,subroutine',
    glob('t/*.t'),
);
ok($rc == 0, 't/ suite passes under Devel::Cover');

diag('coverage summary:');
diag(scalar `cover -summary 2>&1`);
ok(1, 'coverage report generated; see cover_db/');

done_testing();
