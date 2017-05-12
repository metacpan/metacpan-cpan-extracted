#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok ('Bio::LITE::Taxonomy::NCBI::Gi2taxid', "new_dict");            ## Test 1
}

# eval {
#   new_dict(in=>"t/data/dict.in");
# };
# ok ($@ eq "", "");

my $out;
eval {
  open $out,'>', "t/data/dict.bin"
};
ok ($@ eq "", "");

is((ref $out), 'GLOB', "Dictionary open for writing");

new_dict (in=>"t/data/dict.in",
          out=>$out,
	  chunk_size => 15);
#is(tell($out), 24, "Filehandle not automatically closed");
close($out);
is(( -s "t/data/dict.bin" ), 75, "Dictionary creation from filehandle");

eval {
 new_dict (in=>"t/data/dict.in",
	   out=>"t/data/dict.bin",
	  chunk_size => 15);
};
ok ($@ eq "","");
is(( -s "t/data/dict.bin" ), 75, "Dictionary creation from filename");

eval {
  new_dict();
};
like ($@,qr/No input dictionary file provided/,"Check input");

eval {
  my $wrongDict = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict => "t/data/dict.in");
};
like ($@,qr/ERROR/,"Error with text dictionaries");


my $dict = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict=>'t/data/dict.bin', savemem => 0);
my $taxid = $dict->get_taxid(5);
is ($taxid, 23415, "Error getting taxid from gi");

$taxid = $dict->get_taxid(1);
is ($taxid, 1, "Error getting taxid from gi");

$dict = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict=>'t/data/dict.bin', savemem => 1);
$taxid = $dict->get_taxid(5);
is ($taxid, 23415, "Error getting taxid from gi");

$taxid = $dict->get_taxid(1);
is ($taxid, 1, "Error getting taxid from gi");

#$taxid = $dict->get_taxid(6);


done_testing();
