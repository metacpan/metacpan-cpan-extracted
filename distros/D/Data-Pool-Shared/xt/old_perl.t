use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Build and test under an older Perl (e.g. 5.24, 5.28) via plenv. Catches
# ppport.h changes, SvPV_nolen semantics, and XS ABI shifts. Select which
# Perl to use via OLD_PERL env; typical values: 5.24.4, 5.28.3, 5.30.3.

my $plenv = $ENV{OLD_PERL} or plan skip_all => "set OLD_PERL=5.28.3 to run";

my $perl = "$ENV{HOME}/.plenv/versions/$plenv/bin/perl";
plan skip_all => "$perl not installed (use: plenv install $plenv)" unless -x $perl;

diag "testing with $perl";
my $src = '/home/yk/dev/perl-modules/Data-Pool-Shared';
my $tmp = tempdir(CLEANUP => 1);

my $rc = system(
    "cd $tmp && cp -r $src/* . && " .
    "$perl Makefile.PL >/dev/null 2>&1 && " .
    "make >/dev/null 2>&1 && " .
    "make test >&2"
);
is $rc, 0, "build+test pass with Perl $plenv";

done_testing;
