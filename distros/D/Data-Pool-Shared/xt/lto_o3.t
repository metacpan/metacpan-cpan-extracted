use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Rebuild with -O3 -flto. Aggressive inlining sometimes exposes missing
# atomic fences, strict-aliasing violations, or load/store reorderings
# that -O2 builds happen to mask.

plan skip_all => "set LTO=1 to run" unless $ENV{LTO};

my $src = '/home/yk/dev/perl-modules/Data-Pool-Shared';
my $tmp = tempdir(CLEANUP => 1);

diag "building with -O3 -flto in $tmp...";
my $rc = system(
    "cd $tmp && cp -r $src/* . && make clean >/dev/null 2>&1; " .
    "CCFLAGS='-O3 -flto -g' OTHERLDFLAGS='-flto' " .
    "perl Makefile.PL >/dev/null && make >/dev/null 2>&1"
);
is $rc, 0, "LTO build succeeded";

$rc = system("cd $tmp && make test 2>&1");
is $rc, 0, "all tests pass under -O3 -flto";

done_testing;
