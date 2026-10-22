use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path getcwd);
use ExtUtils::Manifest qw(maniread manicopy);

# Build and test under an older Perl (e.g. 5.24, 5.28) via plenv. Catches
# ppport.h changes, SvPV_nolen semantics, and XS ABI shifts. Select which
# Perl to use via OLD_PERL env; typical values: 5.24.4, 5.28.3, 5.30.3.

my $plenv = $ENV{OLD_PERL} or plan skip_all => "set OLD_PERL=5.28.3 to run";

my $perl = "$ENV{HOME}/.plenv/versions/$plenv/bin/perl";
plan skip_all => "$perl not installed (use: plenv install $plenv)" unless -x $perl;

diag "testing with $perl";
my $src = dirname(dirname(abs_path(__FILE__)));
my $tmp = tempdir(CLEANUP => 1);
my $cwd = getcwd();
chdir $src or die $!;
manicopy(maniread(), $tmp, 'cp');
chdir $tmp or die $!;

my $rc = system($perl, 'Makefile.PL');
$rc ||= system('make', '-s');
$rc ||= system('make', 'test');
is $rc, 0, "build+test pass with Perl $plenv";
chdir $cwd or die $!;

done_testing;
