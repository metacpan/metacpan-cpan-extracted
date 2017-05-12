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

# main tests need to be run twice. first w/ 'setup', then w/ 'test'
# TODO: structuring the tests this way was a bad idea. too much redundancy
my $testdir=testdir({testcode=>1});
opendir(DIR,$testdir) or confess "Cannot read test directory $testdir: $!";
my @mainfiles=sort grep /\.(020|030|040)\./,grep /^[^.].*\.t$/,readdir DIR;
closedir DIR;
my @testfiles=map {("$_ setup","$_ test")} @mainfiles;

my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum},@testfiles;
ok($ok,$script);

done_testing();
