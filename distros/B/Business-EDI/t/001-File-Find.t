#!/usr/bin/perl

use strict; use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('File::Find::Rule');
}

my $target = 'Business/EDI/data/edifact/untdid';
my @dirs = @INC;
foreach (split /\//, $target) {
    @dirs = File::Find::Rule->maxdepth(1)->name($_)->directory()->in(@dirs);
}
note(scalar(@dirs) . " $target dirs:\n" . join("\n", @dirs));
ok(scalar(@dirs), "Spec directory ($target) found in \@INC");

# print "Files:\n", join"\n", File::Find::Rule->in(@INC)->name("EDSD.*.CSV")->file();

