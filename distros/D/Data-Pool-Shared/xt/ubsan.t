use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Rebuild with -fsanitize=undefined and run the test suite. Catches
# signed overflow, unaligned loads, shift-by-width, and other UB that
# optimizer can otherwise silently fold into working (but fragile) code.

plan skip_all => "set UBSAN=1 to run" unless $ENV{UBSAN};

my $src = '/home/yk/dev/perl-modules/Data-Pool-Shared';
my $tmp = tempdir(CLEANUP => 1);

diag "building in $tmp with UBSAN...";
my $rc = system(
    "cd $tmp && cp -r $src/* . && make clean >/dev/null 2>&1; " .
    "CCFLAGS='-fsanitize=undefined -fno-sanitize-recover=undefined -O1 -g' " .
    "OTHERLDFLAGS='-fsanitize=undefined' " .
    "perl Makefile.PL >/dev/null && make >/dev/null 2>&1"
);
is $rc, 0, "UBSAN build succeeded";

$rc = system("cd $tmp && make test 2>&1");
is $rc, 0, "UBSAN test pass — no undefined behavior detected";

done_testing;
