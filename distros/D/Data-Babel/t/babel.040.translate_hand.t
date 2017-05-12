########################################
# 040.translate_hand -- translate using handcrafted Babel & components
########################################
use t::lib;
use t::runtests;
use t::util;
use Carp;
use Getopt::Long;
use Test::More;
use Text::Abbrev;
use strict;

our %OPTIONS;
Getopt::Long::Configure('pass_through'); # leave unrecognized options in @ARGV
GetOptions (\%OPTIONS,qw(bundle:s));
our %bundle=abbrev qw(install);
$OPTIONS{bundle}='install' unless defined $OPTIONS{bundle};
my $bundle=$bundle{$OPTIONS{bundle}} || confess "Invalid bundle option $OPTIONS{bundle}";

my $subtestdir=subtestdir;
opendir(DIR,$subtestdir) or confess "Cannot read subtest directory $subtestdir: $!";
my @testfiles=sort grep /^[^.].*\.t$/,readdir DIR;
closedir DIR;

my @tests;
if ($bundle eq 'install') {
  my $startup=shift @testfiles;
  for my $what (qw(baseline history pdups_multi pdups_wide)) {
    push(@tests,"$startup --what $what");
  # run each test once with default parameters
    push(@tests,@testfiles);
  }}
# TODO: implement other bundles
my $ok=runtests {details=>1,nested=>1,exact=>1,testdir=>scriptbasename},@tests;
ok($ok,script);
done_testing();
