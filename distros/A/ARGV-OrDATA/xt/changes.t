#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;
use ARGV::OrDATA;

use FindBin;

my $module_version = $ARGV::OrDATA::VERSION;

my $dir = $FindBin::Bin . '/..';
open my $changes, '<', "$dir/Changes" or die 'Changes not found';

my $found;
while (<$changes>) {
    $found = 1, last if /\Q$module_version\E\s/;
}

ok $found, "$module_version found in Changes";
