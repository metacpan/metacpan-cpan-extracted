## test script for Bio::DB::Biblio::eutils
use utf8;
use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok("Bio::Biblio"); }

my $db = Bio::Biblio->new(-access => "eutils");
ok (defined ($db) && ref ($db) eq "Bio::DB::Biblio::eutils");

## these aren't exactly the most stringent of tests
my $search = '"Day A"[AU] AND ("Database Management Systems"[MH] OR "Databases,'.
             ' Genetic"[MH] OR "Software"[MH] OR "Software Design"[MH])';
$db->find($search);
my $ct = 0;
$ct++ while (my $xml = $db->get_next);
cmp_ok ($ct, ">=", 4);
