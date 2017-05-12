# this series tests low level Oid, OidDeleted, Object methods and operations
use t::lib;
use strict;
use autodbRunTests;

runtests_main();

# use t::lib;
# use strict;
# use Getopt::Long;
# use File::Basename qw(fileparse);
# use File::Spec;
# use Carp;
# use Test::More;
# use autodbRunTests;

# # preamble copied from autodbRunTests::runtests_main
# my($details,$nested,$basenum);
# GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
# $nested=1 if !defined $nested && defined $basenum; # basenum implies nested
# $details=1 if !defined $details && $nested; # nested implies details
# my($script,$testdir,$skip)=fileparse($0);

# # have to rerun 'store' before other tests
# my $testdir=testdir({testcode=>1});
# opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
# my @test010files=sort grep /\.010\./,grep /^[^.].*\.t$/,readdir DIR;
# opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
# my @test020files=sort grep /\.020\./,grep /^[^.].*\.t$/,readdir DIR;
# closedir DIR;
# my $store010=shift @test010files;	# store is always the '00' file
# my $store020=shift @test020files;	# store is always the '00' file
# my @testfiles=((map {($store010,$_)} @test010files),(map {($store020,$_)} @test020files));

# my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum},@testfiles;
# ok($ok,$script);

# done_testing();
