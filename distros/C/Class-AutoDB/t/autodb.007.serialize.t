# this series tests low level Serialize and Oid functions
use t::lib;
use strict;
use Getopt::Long;
use File::Basename qw(fileparse);
use File::Spec;
use Carp;
use Test::More;
use autodbRunTests;

# preamble copied from autodbRunTests::runtests_main
my($details,$nested,$basenum);
GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
$nested=1 if !defined $nested && defined $basenum; # basenum implies nested
$details=1 if !defined $details && $nested; # nested implies details
my($script,$testdir,$skip)=fileparse($0);

# have to rerun 'store' before 030 tests
my $testdir=testdir({testcode=>1});
opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
my @test030files=sort grep /\.030\./,grep /^[^.].*\.t$/,readdir DIR;
closedir DIR;
my $store=shift @test030files;	# store is always the '00' file
my @testfiles=map {($store,$_)} @test030files;

my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum},@testfiles;
ok($ok,$script);

done_testing();
