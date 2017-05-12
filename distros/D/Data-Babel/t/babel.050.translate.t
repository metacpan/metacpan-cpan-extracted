use t::lib;
use t::runtests;
use t::util;
use Carp;
use Getopt::Long;
# use Set::Scalar;
use Test::More;
use Text::Abbrev;
use strict;

# if --developer set, run longer versions of tests
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
  # run each test once with default parameters
  @tests=@testfiles;
}
# TODO: implement other bundles
# my $startup=shift @testfiles;
# @testfiles=grep /main/,@testfiles if $bundle eq 'short';
# closedir DIR;
# # my @extras=(undef,qw(history validate));
# my @extras=new Set::Scalar(qw(history validate))->power_set->members;
# @extras=sort {$a->size <=> $b->size} @extras;
# my @ops=qw(translate count);
# my @db_types=$user_type eq 'developer'? qw(binary staggered basecalc): qw(binary);
# my @graph_types=$user_type eq 'developer'? qw(star chain tree): qw(star);

# my @tests;
# for my $extra (@extras) {
#   $extra=join(' ',map {"--$_"} $extra->members);
#   for my $graph_type (@graph_types) {
#     my $test=$startup;
#     $test.=" --graph_type $graph_type --user_type $user_type" unless $user_type eq 'installer';
#     $test.=" $extra" if length $extra;
#     push(@tests,$test);
#     for my $op (@ops) {
#       push(@tests,
# 	   map {my $test="$_ --op $op";
# 		$test.=" --graph_type $graph_type --user_type $user_type" 
# 		  unless $user_type eq 'installer';
# 		$test.=" $extra" if length $extra;
# 		$test}
# 	   @testfiles);
#     }}}
my $ok=runtests {details=>1,nested=>1,exact=>1,testdir=>scriptbasename},@tests;
ok($ok,script);
done_testing();
