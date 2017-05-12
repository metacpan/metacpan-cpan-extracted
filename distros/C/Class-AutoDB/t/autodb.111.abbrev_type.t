use t::lib;
use strict;
use Getopt::Long;
use File::Basename qw(fileparse);
use File::Spec;
use Test::More;
use autodbRunTests;

# regression test for bug in which redefinition of type to a valid abbreviation is 
#   seen as inconsistent

# preamble copied from autodbRunTests::runtests_main
my($details,$nested,$basenum);
GetOptions ('details=i'=>\$details,'nested=i'=>\$nested,'basenum=s'=>\$basenum);
$nested=1 if !defined $nested && defined $basenum; # basenum implies nested
$details=1 if !defined $details && $nested; # nested implies details
my($script,$testdir,$skip)=fileparse($0);

my $ok=runtests {testcode=>1,details=>$details,nested=>$nested,basenum=>$basenum}, 
  qw(abbrev_type.010.00.create_full.t
     abbrev_type.010.01.alter_abbrev.t
     abbrev_type.010.00.create_full.t
     abbrev_type.010.02.use_abbrev.t
     abbrev_type.010.10.create_abbrev.t
     abbrev_type.010.11.alter_full.t
     abbrev_type.010.10.create_abbrev.t
     abbrev_type.010.12.use_full.t);
ok($ok,$script);

done_testing();
