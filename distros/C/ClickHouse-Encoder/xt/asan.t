#!/usr/bin/env perl
# Re-run the test suite with ASAN preloaded into the perl interpreter.
# Catches use-after-scope, use-after-free, intra-object overflows that
# valgrind's leak check can miss. Skipped unless RELEASE_TESTING=1 and a
# usable libasan is found.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan skip_all => 'set RELEASE_TESTING=1 to run ASAN tests'
    unless $ENV{RELEASE_TESTING};

# Locate libasan.so via the host C compiler.
my $cc = $ENV{CC} // 'cc';
chomp(my $libasan = `$cc -print-file-name=libasan.so 2>/dev/null`);
plan skip_all => 'no usable libasan.so on this host'
    unless $libasan && -f $libasan;

my $perl = $^X;
$perl = $1 if $perl =~ m{^(.+plenv/versions/[^/]+/bin/perl[^/]*)$};

# Resolve any plenv shim to the underlying perl, since LD_PRELOAD doesn't
# survive an exec to another perl.
chomp(my $real = `$perl -e 'print \$^X'`);
$perl = $real if -x $real;

my @tests = sort glob 't/*.t';
plan tests => scalar @tests;

for my $t (@tests) {
    my $cmd = "LD_PRELOAD='$libasan' ASAN_OPTIONS='detect_leaks=0:abort_on_error=0' "
            . "$perl -Mblib '$t' 2>&1";
    my $output = `$cmd`;
    my $rc     = $? >> 8;
    if ($rc != 0) {
        diag("ASAN output for $t:\n$output");
    }
    is($rc, 0, "$t passes under ASAN");
}
