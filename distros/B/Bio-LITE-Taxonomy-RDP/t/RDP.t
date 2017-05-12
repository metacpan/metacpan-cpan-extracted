#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok ('Bio::LITE::Taxonomy'); # T1
  use_ok ('Bio::LITE::Taxonomy::RDP'); # T2
}


can_ok ("Bio::LITE::Taxonomy", qw/get_taxonomy get_taxonomy_with_levels get_level_from_name get_taxid_from_name get_taxonomy_from_name/); # T2

my $datapath = "t/data";

ok (-e "${datapath}/bergeyTrainingTree.xml","bergeyTrainingTree.xml not present");  # T3
ok (-r "${datapath}/bergeyTrainingTree.xml","bergeyTrainingTree.xml not readable"); # T4

my $taxRDP = new_ok ("Bio::LITE::Taxonomy::RDP" => ([bergeyXML=>"${datapath}/bergeyTrainingTree.xml"]) );

my ($tax,@tax);
eval {
  @tax = $taxRDP->get_taxonomy(22075);
};
is($@,"",""); # T6
ok($#tax == 7, "");                   # T7
is($tax[0],"Bacteria", "");       # T8

eval {
  $tax = $taxRDP->get_taxonomy(22075);
};
isa_ok ($tax,"ARRAY");

eval {
  $tax = $taxRDP->get_taxonomy(300000);
};
ok($tax eq "","");

eval {
  $tax=$taxRDP->get_taxonomy();
};
ok (!defined $tax);

my $level;
eval {
  $level = $taxRDP->get_level_from_name("Bacillaceae 1");
};
is($@,"",""); # T7
is($level,"subfamily",""); # T8

done_testing();
