use t::lib;
use strict;
use Carp;
use Config;
use Getopt::Long;
use File::Basename qw(fileparse);
use File::Spec;
use List::Util qw(min max);
use Test::More;
use autodbRunTests;

# preamble copied from autodbRunTests::runtests_main
my($details,$nested,$basenum);
GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
$nested=1 if !defined $nested && defined $basenum; # basenum implies nested
$details=1 if !defined $details && $nested; # nested implies details
my($script,$testdir,$skip)=fileparse($0);

my $testdir=testdir {testcode=>1};
my @del_types=qw(del del-multi);
my @testfiles;

########################################
# this sections deals w/ 010 basic del tests
my $testfile=File::Spec->catfile($testdir,scriptcode.'.010.00.put.t');

# my $count_get=`perl -Mblib $testfile count`;
# code below copied from perlvar
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS')
  {$secure_perl_path .= $Config{_exe} unless $secure_perl_path =~ m/$Config{_exe}$/i;}
#####
# invoke perl via full (secure) path. provide default just in case...
my $count=`$secure_perl_path -Mblib $testfile count` || 14;

# do both del types for first case
my @files=
  ('del.010.00.put.t','del.010.01.del.t 0 del',
   'del.010.00.put.t','del.010.01.del.t 0 del-multi');
# do rest with simple 'del'
for (my $i=1; $i<$count; $i++) {
  push(@files,"del.010.00.put.t","del.010.01.del.t $i");
}
# do remaining 010 tests starting at 1st case. need 'put' before each test
my $testdir=testdir({testcode=>1});
opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
my @test010files=sort grep /\.010\./,grep /^[^.].*\.t$/,readdir DIR;
closedir DIR;
my $put=shift @test010files;	# 'put' test is always 00
shift @test010files;		# skip 01 test - already done
push(@files,map {$put,$_} @test010files);
push(@testfiles,\@files);

########################################
# this sections deals w/ 012 mechanics tests
my @files;
# exhaustive loop too big. just cycle through cases
my $i=0;
for my $num_objects (1..3) {
  for my $list_count (0..3) {
    push(@files,"del.012.00.mechanics.t $num_objects $list_count");
    push(@files,"del.012.01.mechanics.t $num_objects $list_count");
    $i++;
  }
}
push(@testfiles,\@files);

my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum},@testfiles;
ok($ok,$script);

done_testing();
