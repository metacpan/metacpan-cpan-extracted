#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok ('Bio::LITE::Taxonomy'); # T1
}

  can_ok ("Bio::LITE::Taxonomy", qw/get_taxonomy get_taxonomy_with_levels get_level_from_name get_taxid_from_name get_taxonomy_from_name/); # T2

# SKIP: {
#   eval { require Bio::LITE::Taxonomy::RDP };

#   my $datapath = "t/data";

#   skip "Bio::LITE::Taxonomy::RDP not installed", 6 if $@;
#   skip "bergeyTrainingTree.xml not found", 6 unless (-e "${datapath}/bergeyTrainingTree.xml");
#   skip "bergeyTrainingTree.xml not readable", 6 unless (-r "${datapath}/bergeyTrainingTree.xml");

#   my $taxRDP = new_ok ( "Bio::LITE::Taxonomy::RDP" => [(bergeyXML=>"${datapath}/bergeyTrainingTree.xml")] ); # T3
#   my @tax;
#   eval {
#     @tax = $taxRDP->get_taxonomy(22075);
#   };
#   is($@,"",""); # T4
#   ok($#tax == 6, "");                   # T5
#   is($tax[0],"Bacteria", "");       # T6

#   my $level;
#   eval {
#     $level = $taxRDP->get_level_from_name("Bacillaceae 1");
#   };
#   is($@,"",""); # T7
#   is($level,"subfamily",""); # T8
# }

# SKIP: {
#   eval { require Taxonomy::NCBI };

#   my $datapath = "t/data";

#   my $n_block_tests = 9;

#   skip "Taxonomy::NCBI not installed", $n_block_tests if $@;
#   skip "names.dmp file not found", $n_block_tests unless (-e "${datapath}/names.dmp");
#   skip "nodes.dmp file not found", $n_block_tests unless (-e "${datapath}/nodes.dmp");
#   skip "names.dmp file not readable", $n_block_tests unless (-r "${datapath}/names.dmp");
#   skip "nodes.dmp file not readable", $n_block_tests unless (-r "${datapath}/nodes.dmp");

#   my $taxNCBI = new_ok ( "Taxonomy::NCBI" => [(nodes=>"${datapath}/nodes.dmp",names=>"${datapath}/names.dmp")] ); # T9
#   my ($tax,@tax);
#   eval {
#     @tax = $taxNCBI->get_taxonomy(1442);
#   };
#   is($@,"",""); # T10
#   ok($#tax == 9, "");                   # T11
#   is($tax[0],"Bacteria", "");       # T12

#   eval {
#     $tax = $taxNCBI->get_taxonomy(1442);
#   };
#   isa_ok($tax,"ARRAY"); # T13

#   my $level;
#   eval {
#     $level = $taxNCBI->get_level_from_name("Bacillaceae");
#   };
#   is($@,"",""); # T14
#   is($level,"family",""); # T15

#   eval {
#     $tax = $taxNCBI->get_taxonomy(3);
#   };
#   is($tax,"",""); # T16

#   eval {
#     $tax = $taxNCBI->get_taxonomy();
#   };
#   ok (!defined $tax, ""); # T17
# }

done_testing();
