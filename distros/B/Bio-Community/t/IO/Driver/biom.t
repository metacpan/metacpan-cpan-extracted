use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $meta, $output_file, $member, $count, $taxonomy,
   $community, $community2, $community3, $community4, $community5, $community6 );
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_minimal_dense.txt'),
), 'Format detection';
is $in->format, 'biom';


# Read BIOM metacommunity with name

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_rich_sparse.txt'),
   -format => 'biom',
), 'Read BIOM metacommunity with a name';

ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, 'Human microbiomes';
is $meta->get_members_count, 37;
is $meta->get_communities_count, 6;
is $meta->get_richness, 5;
$in->close;


# Write BIOM metacommunity with name

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'biom',
), 'Write BIOM metacommunity with a name';

ok $out->write_metacommunity($meta);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'biom',
);
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, 'Human microbiomes';
is $meta->get_members_count, 37;
is $meta->get_communities_count, 6;
is $meta->get_richness, 5;
$in->close;


# Read BIOM minimal dense file

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_minimal_dense.txt'),
   -format => 'biom',
), 'Read BIOM minimal dense file';
isa_ok $in, 'Bio::Community::IO::Driver::biom';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is $in->multiple_communities, 1;
is $in->explicit_ids, 1;

@methods = qw(
  _next_metacommunity_init _next_community_init next_member _next_community_finish _next_metacommunity_finish
  _write_metacommunity_init _write_community_init write_member _write_community_finish _write_metacommunity_finish)
;
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 2;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'dense';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community->get_count($member), 5;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community->get_count($member), 2;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community2->get_count($member), 3;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, '';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community6->get_count($member), 2;
ok $member = $community6->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community6->get_count($member), 1;
is $community6->get_member_by_rank(3), undef;


# Write BIOM minimal dense file

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file        => '>'.$output_file,
   -format      => 'biom',
   -matrix_type => 'dense',
), 'Write BIOM minimal dense file';

ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
ok $out->write_community($community4);
ok $out->write_community($community5);
ok $out->write_community($community6);
is $out->get_matrix_type, 'dense';
is $out->_get_matrix_element_type, 'int';
$out->close;

ok $in = Bio::Community::IO->new(
   -file        => $output_file,
   -format      => 'biom',
   -matrix_type => 'dense',
), 'Re-read BIOM file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 2;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'dense';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community->get_count($member), 5;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community->get_count($member), 2;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community2->get_count($member), 3;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, '';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community6->get_count($member), 2;
ok $member = $community6->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, '';
is $community6->get_count($member), 1;
is $community6->get_member_by_rank(3), undef;


# Read BIOM rich sparse file (with taxonomy)

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('biom_rich_sparse.txt'),
   -taxonomy => Bio::DB::Taxonomy->new( -source => 'list' ),
   -format   => 'biom',
), 'Read BIOM rich sparse file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 2;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'sparse';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $member->taxon->node_name, 'g__Dolichospermum';
is $community->get_count($member), 5;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $member->taxon->node_name, 's__saccharolyticum';
is $community->get_count($member), 2;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $member->taxon->node_name, 'g__Dolichospermum';
is $community2->get_count($member), 3;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $member->taxon->node_name, 's__saccharolyticum';
is $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $member->taxon->node_name, 'g__Escherichia';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $member->taxon->node_name, 'g__Escherichia';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $member->taxon->node_name, 'g__Methanosarcina';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $member->taxon->node_name, 's__saccharolyticum';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $member->taxon->node_name, 'g__Escherichia';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $member->taxon->node_name, 'g__Methanosarcina';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $member->taxon->node_name, 'g__Dolichospermum';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $member->taxon->node_name, 'g__Dolichospermum';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $member->taxon->node_name, 'g__Methanosarcina';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $member->taxon->node_name, 'g__Dolichospermum';
is $community6->get_count($member), 2;
ok $member = $community6->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $member->taxon->node_name, 's__saccharolyticum';
is $community6->get_count($member), 1;
is $community6->get_member_by_rank(3), undef;


# Write BIOM rich sparse file

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file        => '>'.$output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Write BIOM rich sparse file';

ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
ok $out->write_community($community4);
ok $out->write_community($community5);
ok $out->write_community($community6);
is $out->get_matrix_type, 'sparse';
is $out->_get_matrix_element_type, 'int';
$out->close;

ok $in = Bio::Community::IO->new(
   -file        => $output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Re-read BIOM file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 2;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'sparse';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $community->get_count($member), 5;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $community->get_count($member), 2;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $community2->get_count($member), 3;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae; g__Escherichia; s__';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, 'k__Archaea; p__Euryarchaeota; c__Methanomicrobia; o__Methanosarcinales; f__Methanosarcinaceae; g__Methanosarcina; s__';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, 'k__Bacteria; p__Cyanobacteria; c__Nostocophycideae; o__Nostocales; f__Nostocaceae; g__Dolichospermum; s__';
is $community6->get_count($member), 2;
ok $member = $community6->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_4';
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Halanaerobiales; f__Halanaerobiaceae; g__Halanaerobium; s__saccharolyticum';
is $community6->get_count($member), 1;
is $community6->get_member_by_rank(3), undef;


# Read BIOM file with decimals

ok $in = Bio::Community::IO->new(
   -file        => test_input_file('biom_float.txt'),
   -format      => 'biom',
   -matrix_type => 'sparse'
), 'Read BIOM file with decimals';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 9;
is $community->name, 'replicate_1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 10;
is $community2->name, 'replicate_2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 10;
is $community3->name, 'replicate_3';

is $in->next_community, undef;

is $in->get_matrix_type, 'sparse';
is $in->_get_matrix_element_type, 'float';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '84';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Deltaproteobacteria; o__Myxococcales; f__; g__; s__';
delta_ok $community2->get_count($member), 3714.82697742678;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '84';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Deltaproteobacteria; o__Myxococcales; f__; g__; s__';
delta_ok $community2->get_count($member), 3714.82697742678;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '118';
is $member->desc, 'k__Bacteria; p__Verrucomicrobia; c__Opitutae; o__Opitutales; f__Opitutaceae; g__Opitutus; s__';
delta_ok $community3->get_count($member), 5719.78392977718;


# Write BIOM file with decimals

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file        => '>'.$output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Write BIOM file with decimals';

ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
is $out->get_matrix_type, 'sparse';
is $out->_get_matrix_element_type, 'float';
$out->close;

ok $in = Bio::Community::IO->new(
   -file        => $output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Re-read BIOM file';


ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 9;
is $community->name, 'replicate_1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 10;
is $community2->name, 'replicate_2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 10;
is $community3->name, 'replicate_3';

is $in->next_community, undef;

is $in->get_matrix_type, 'sparse';
is $in->_get_matrix_element_type, 'float';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '84';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Deltaproteobacteria; o__Myxococcales; f__; g__; s__';
delta_ok $community2->get_count($member), 3714.82697742678;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '84';
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Deltaproteobacteria; o__Myxococcales; f__; g__; s__';
delta_ok $community2->get_count($member), 3714.82697742678;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, '118';
is $member->desc, 'k__Bacteria; p__Verrucomicrobia; c__Opitutae; o__Opitutales; f__Opitutaceae; g__Opitutus; s__';
delta_ok $community3->get_count($member), 5719.78392977718;


# Read BIOM file with duplicates

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_dups.txt'),
   -format => 'biom',
), 'Read BIOM file with duplicates';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 1;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'dense';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community->get_count($member), 7;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community2->get_count($member), 5;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, '';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community6->get_count($member), 3;
is $community6->get_member_by_rank(2), undef;


# Write BIOM file with duplicates

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file        => '>'.$output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Write BIOM file with duplicates';

ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
ok $out->write_community($community4);
ok $out->write_community($community5);
ok $out->write_community($community6);
is $out->get_matrix_type, 'sparse';
is $out->_get_matrix_element_type, 'int';
$out->close;

ok $in = Bio::Community::IO->new(
   -file        => $output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Re-read BIOM file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 2;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 2;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 1;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, 'sparse';
is $in->_get_matrix_element_type, 'int';

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community->get_count($member), 7;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community2->get_count($member), 5;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community2->get_count($member), 1;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_1';
is $member->desc, '';
is $community3->get_count($member), 4;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community3->get_count($member), 3;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_5';
is $member->desc, '';
is $community3->get_count($member), 1;
is $community3->get_member_by_rank(5), undef;

ok $member = $community4->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community4->get_count($member), 4;
ok $member = $community4->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community4->get_count($member), 2;
is $community4->get_member_by_rank(3), undef;

ok $member = $community5->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community5->get_count($member), 3;
ok $member = $community5->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_3';
is $member->desc, '';
is $community5->get_count($member), 2;
is $community5->get_member_by_rank(3), undef;

ok $member = $community6->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->id, 'GG_OTU_2';
is $member->desc, '';
is $community6->get_count($member), 3;
is $community6->get_member_by_rank(2), undef;


# Read BIOM containing no species, just sample names and metadata

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_no_spp.txt'),
   -format => 'biom',
), 'Read BIOM file with no species';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 0;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 0;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 0;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 0;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 0;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 0;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, undef;
is $in->_get_matrix_element_type, undef;

$in->close;

is $member = $community->get_member_by_rank(1), undef;
is $member = $community2->get_member_by_rank(1), undef;
is $member = $community3->get_member_by_rank(1), undef;
is $member = $community4->get_member_by_rank(1), undef;
is $member = $community5->get_member_by_rank(1), undef;
is $member = $community6->get_member_by_rank(1), undef;


# Write BIOM file with no species

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file        => '>'.$output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',   
), 'Write BIOM file with duplicates';

ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
ok $out->write_community($community4);
ok $out->write_community($community5);
ok $out->write_community($community6);
is $out->get_matrix_type, 'sparse';
is $out->_get_matrix_element_type, undef;
$out->close;

ok $in = Bio::Community::IO->new(
   -file        => $output_file,
   -format      => 'biom',
   -matrix_type => 'sparse',
), 'Re-read BIOM file';


ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 0;
is $community->name, 'Sample1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 0;
is $community2->name, 'Sample2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 0;
is $community3->name, 'Sample3';

ok $community4 = $in->next_community;
isa_ok $community4, 'Bio::Community';
is $community4->get_richness, 0;
is $community4->name, 'Sample4';

ok $community5 = $in->next_community;
isa_ok $community5, 'Bio::Community';
is $community5->get_richness, 0;
is $community5->name, 'Sample5';

ok $community6 = $in->next_community;
isa_ok $community6, 'Bio::Community';
is $community6->get_richness, 0;
is $community6->name, 'Sample6';

is $in->next_community, undef;

is $in->get_matrix_type, undef;
is $in->_get_matrix_element_type, undef;

$in->close;

is $member = $community->get_member_by_rank(1), undef;
is $member = $community2->get_member_by_rank(1), undef;
is $member = $community3->get_member_by_rank(1), undef;
is $member = $community4->get_member_by_rank(1), undef;
is $member = $community5->get_member_by_rank(1), undef;
is $member = $community6->get_member_by_rank(1), undef;


# Test invalid biom file

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('biom_invalid.txt'),
   -format => 'biom',
);

throws_ok { $in->next_metacommunity } qr/EXCEPTION/, 'Invalid biom file';


done_testing();

exit;
