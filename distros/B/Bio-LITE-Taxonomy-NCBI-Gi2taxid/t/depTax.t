#!perl -T

use strict;
use warnings;
use Test::More;
use Bio::LITE::Taxonomy::NCBI::Gi2taxid;

eval { require Bio::LITE::Taxonomy };
plan skip_all => "Bio::LITE::Taxonomy not installed" if $@;
open my $in, '<:raw', "t/data/dict.bin" or die $!;
is((ref $in), 'GLOB', "Dictionary open for reading");
my $dict = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict => $in);
isa_ok($dict,"Bio::LITE::Taxonomy::NCBI::Gi2taxid","as filehandle");

my $dict2 = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict => 't/data/dict.bin');
isa_ok($dict2,"Bio::LITE::Taxonomy::NCBI::Gi2taxid","as filename");

is($dict->get_taxid(0),0,"Uninitilized values");
is($dict->get_taxid(5),23415,"Initilized values");
is($dict->get_taxid(14),23420, "Initialized values");
is($dict->get_taxid(20),23422, "Initialized last value");

done_testing();

