use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Meta;
use Bio::Community::Member;
use Bio::DB::Taxonomy;
use Method::Signatures;

use_ok($_) for qw(
    Bio::Community::Tools::Summarizer
);


my ($summarizer, $member, $member1, $member2, $member3, $member4, $member5,
   $member6, $member7, $member8, $member9, $member10, $meta, $community1,
   $community2, $community3, $summary_meta, $summary, $group, $id, $id1, $id2,
   $id3, $in);


# Basic object

ok $summarizer = Bio::Community::Tools::Summarizer->new(), 'Bare object';
isa_ok $summarizer, 'Bio::Community::Tools::Summarizer';
throws_ok { $summarizer->get_summary } qr/EXCEPTION.*metacommunity/msi;


# Test with multiple communities

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );
$member4 = Bio::Community::Member->new( -desc => 'D' );
$member5 = Bio::Community::Member->new( -desc => 'E' );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1 );
$community1->add_member( $member2, 95);
$community1->add_member( $member3, 1 );
$community1->add_member( $member4, 3 );

$community2 = Bio::Community->new( -name => 'grassland' );
$community2->add_member( $member1, 8 );
$community2->add_member( $member2, 90);
$community2->add_member( $member3, 1 );
$community2->add_member( $member5, 1 );

$meta = Bio::Community::Meta->new(-communities => [$community1, $community2]);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<', 2],
), 'Multiple communities';

is_deeply $summarizer->metacommunity, $meta;
is_deeply $summarizer->by_rel_ab, ['<', 2];

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 2;

$summary = $summary_meta->next_community;

$group = get_group($summary);
isa_ok $group, 'Bio::Community::Member';
is $group->desc, 'Other < 2 %';
$id = $group->id;

is $summary->name, 'Unnamed';
delta_ok $summary->get_count($member1), 1;
delta_ok $summary->get_count($member2), 95;
delta_ok $summary->get_count($member3), 0;
delta_ok $summary->get_count($member4), 3;
delta_ok $summary->get_count($member5), 0;
delta_ok $summary->get_count($group)  , 1;

$summary = $summary_meta->next_community;
$group = get_group($summary);
is $group->id, $id; # different object because the weight is different, 
                    # but ID need to be the same
is $summary->name, 'grassland';
delta_ok $summary->get_count($member1), 8;
delta_ok $summary->get_count($member2), 90;
delta_ok $summary->get_count($member3), 0;
delta_ok $summary->get_count($member4), 0;
delta_ok $summary->get_count($member5), 0;
delta_ok $summary->get_count($group)  , 2;

is $summary_meta->next_community, undef;


# Test <= operator

$community1 = Bio::Community->new();
$community1->add_member( $member1,  2 );
$community1->add_member( $member2, 98 );

$meta = Bio::Community::Meta->new(-communities => [$community1]);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<=', 1.9],
), "Operator '<='";

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
$group = get_group($summary);
is $group, undef;
delta_ok $summary->get_count($member1), 2;
delta_ok $summary->get_count($member2), 98;

is $summary_meta->next_community, undef;


ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<=', 2],
);

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 98;
delta_ok $summary->get_count($group  ), 2;

is $summary_meta->next_community, undef;


# Test < operator

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<', 2.1],
), "Operator '<'";

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 98;
delta_ok $summary->get_count($group  ), 2;

is $summary_meta->next_community, undef;


ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<', 2],
);

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$group = get_group($summary);
is $group, undef;
delta_ok $summary->get_count($member1), 2;
delta_ok $summary->get_count($member2), 98;

is $summary_meta->next_community, undef;


# Test > operator

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['>', 2],
), "Operator '>'";

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 2;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 98;

is $summary_meta->next_community, undef;


ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['>', 1.9],
);

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 100;

is $summary_meta->next_community, undef;


# Test >= operator

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['>=', 3],
), "Operator '>='";

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 2;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 98;

is $summary_meta->next_community, undef;


ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['>=', 2],
);

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 100;

is $summary_meta->next_community, undef;


# Test with multiple communities with weighted members

$member1 = Bio::Community::Member->new( -desc => 'A', -weights => [1] );
$member2 = Bio::Community::Member->new( -desc => 'B', -weights => [2] );
$member3 = Bio::Community::Member->new( -desc => 'C', -weights => [3] );
$member4 = Bio::Community::Member->new( -desc => 'D', -weights => [4] );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 87 );
$community1->add_member( $member2,  1 );
$community1->add_member( $member3,  2 );
$community1->add_member( $member4, 10 );

$community2 = Bio::Community->new( -name => 'grassland' );
$community2->add_member( $member1, 25 );
$community2->add_member( $member2, 25 );
$community2->add_member( $member3, 25 );
$community2->add_member( $member4, 25 );

delta_ok $community1->get_rel_ab($member1), 95.9558824;
delta_ok $community1->get_rel_ab($member2),  0.5514706;
delta_ok $community1->get_rel_ab($member3),  0.7352941;
delta_ok $community1->get_rel_ab($member4),  2.7573529;

delta_ok $community2->get_rel_ab($member1), 48.0000000;
delta_ok $community2->get_rel_ab($member2), 24.0000000;
delta_ok $community2->get_rel_ab($member3), 16.0000000;
delta_ok $community2->get_rel_ab($member4), 12.0000000;

$meta = Bio::Community::Meta->new(-communities => [$community1, $community2]);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_rel_ab     => ['<', 20],
), 'Multiple weighted communities';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 2;

$summary = $summary_meta->next_community;
$group = get_group($summary);
$id = $group->id;
is $summary->name, 'Unnamed';
delta_ok $summary->get_rel_ab($member1), 95.9558824;
delta_ok $summary->get_rel_ab($member2),  0.5514706;
delta_ok $summary->get_rel_ab($member3),  0;
delta_ok $summary->get_rel_ab($member4),  0;
delta_ok $summary->get_rel_ab($group)  ,  3.4926470;

$summary = $summary_meta->next_community;
$group = get_group($summary);
is $group->id, $id;
is $summary->name, 'grassland';
delta_ok $summary->get_rel_ab($member1), 48.0000000;
delta_ok $summary->get_rel_ab($member2), 24.0000000;
delta_ok $summary->get_rel_ab($member3), 0;
delta_ok $summary->get_rel_ab($member4), 0;
delta_ok $summary->get_rel_ab($group)  , 28.0000000;

is $summary_meta->next_community, undef;


# Taxonomic summaries

$community1 = Bio::Community::IO->new(
   -file     => test_input_file('qiime_single_community.txt'),
   -taxonomy => Bio::DB::Taxonomy->new( -source => 'list' ),
)->next_community;

$member1  = $community1->get_member_by_id(  2335 );
$member2  = $community1->get_member_by_id(  2841 );
$member3  = $community1->get_member_by_id(  5381 );
$member4  = $community1->get_member_by_id(  1847 );
$member5  = $community1->get_member_by_id( 12154 );
$member6  = $community1->get_member_by_id(  1628 );
$member7  = $community1->get_member_by_id(  3902 );
$member8  = $community1->get_member_by_id(  5676 );
$member9  = $community1->get_member_by_id( 10087 );
$member10 = $community1->get_member_by_id( 12958 );

$member1->weights(  [10] );
$member2->weights(  [ 9] );
$member3->weights(  [ 8] );
$member4->weights(  [ 7] );
$member5->weights(  [ 6] );
$member6->weights(  [ 5] );
$member7->weights(  [ 4] );
$member8->weights(  [ 3] );
$member9->weights(  [ 2] );
$member10->weights( [ 1] );

$community1 = Bio::Community->new();
$community1->add_member($member1 , 1997);
$community1->add_member($member2 ,   18);
$community1->add_member($member3 ,    5);
$community1->add_member($member4 ,    2);
$community1->add_member($member5 ,    2);
$community1->add_member($member6 ,    1);
$community1->add_member($member7 ,    1);
$community1->add_member($member8 ,    1);
$community1->add_member($member9 ,    1);
$community1->add_member($member10,    1);

delta_ok $community1->get_count( $member1), 1997;
delta_ok $community1->get_count( $member2),   18;
delta_ok $community1->get_count( $member3),    5;
delta_ok $community1->get_count( $member4),    2;
delta_ok $community1->get_count( $member5),    2;
delta_ok $community1->get_count( $member6),    1;
delta_ok $community1->get_count( $member7),    1;
delta_ok $community1->get_count( $member8),    1;
delta_ok $community1->get_count( $member9),    1;
delta_ok $community1->get_count($member10),    1;

delta_ok $community1->get_rel_ab( $member1), 97.3067039;
delta_ok $community1->get_rel_ab( $member2),  0.9745288;
delta_ok $community1->get_rel_ab( $member3),  0.3045403;
delta_ok $community1->get_rel_ab( $member4),  0.1392184;
delta_ok $community1->get_rel_ab( $member5),  0.1624215;
delta_ok $community1->get_rel_ab( $member6),  0.0974529;
delta_ok $community1->get_rel_ab( $member7),  0.1218161;
delta_ok $community1->get_rel_ab( $member8),  0.1624215;
delta_ok $community1->get_rel_ab( $member9),  0.2436322;
delta_ok $community1->get_rel_ab($member10),  0.4872644;

$meta = Bio::Community::Meta->new(-communities => [$community1]);


# Taxonomic summary level 1

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 1,
), 'Taxonomic summary (level 1)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Bacteria';
is $member->taxon->node_name, 'k__Bacteria';
delta_ok $summary->get_count($member), 2027;
delta_ok $summary->get_rel_ab($member), 99.6345517;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.3654483;

is $summary->get_member_by_rank(3), undef;

is $summary_meta->next_community, undef;


# Taxonomic summary level 2

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 2,
), 'Taxonomic summary (level 2)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Bacteria; p__Proteobacteria';
is $member->taxon->node_name, 'p__Proteobacteria';
delta_ok $summary->get_count($member), 2002;
delta_ok $summary->get_rel_ab($member), 97.6112442;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'k__Bacteria; p__Firmicutes';
is $member->taxon->node_name, 'p__Firmicutes';
delta_ok $summary->get_count($member), 23;
delta_ok $summary->get_rel_ab($member), 1.860886;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.3654483;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'k__Bacteria; p__Actinobacteria';
is $member->taxon->node_name, 'p__Actinobacteria';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.1624215;

is $summary->get_member_by_rank(5), undef;

is $summary_meta->next_community, undef;


# Taxonomic summary level 6

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 6,
), 'Taxonomic summary (level 6)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae';
is $member->taxon->node_name, 'f__Enterobacteriaceae';
delta_ok $summary->get_count($member), 2002;
delta_ok $summary->get_rel_ab($member), 97.6112442;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Carnobacteriaceae; g__Granulicatella';
is $member->taxon->node_name, 'g__Granulicatella';
delta_ok $summary->get_count($member), 18;
delta_ok $summary->get_rel_ab($member), 0.9745288;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Clostridiales; f__Veillonellaceae; g__Veillonella';
is $member->taxon->node_name, 'g__Veillonella';
delta_ok $summary->get_count($member), 1;
delta_ok $summary->get_rel_ab($member), 0.4872644;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.3654483;

$member = $summary->get_member_by_rank(5);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Lactobacillaceae; g__Lactobacillus';
is $member->taxon->node_name, 'g__Lactobacillus';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.2598744;

$member = $summary->get_member_by_rank(6);
is $member->desc, 'k__Bacteria; p__Actinobacteria; c__Actinobacteria; o__Actinomycetales; f__Actinomycetaceae; g__Actinomyces';
is $member->taxon->node_name, 'g__Actinomyces';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.1624215;

$member = $summary->get_member_by_rank(7);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Enterococcaceae; g__Enterococcus';
is $member->taxon->node_name, 'g__Enterococcus';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.1392184;

is $summary->get_member_by_rank(8), undef;

is $summary_meta->next_community, undef;


# Taxonomic summary level 7

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 7,
), 'Taxonomic summary (level 7)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Enterobacteriales; f__Enterobacteriaceae';
is $member->taxon->node_name, 'f__Enterobacteriaceae';
delta_ok $summary->get_count($member), 2002;
delta_ok $summary->get_rel_ab($member), 97.6112442;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Carnobacteriaceae; g__Granulicatella; s__Granulicatellaelegans';
is $member->taxon->node_name, 's__Granulicatellaelegans';
delta_ok $summary->get_count($member), 18;
delta_ok $summary->get_rel_ab($member), 0.9745288;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Clostridia; o__Clostridiales; f__Veillonellaceae; g__Veillonella';
is $member->taxon->node_name, 'g__Veillonella';
delta_ok $summary->get_count($member), 1;
delta_ok $summary->get_rel_ab($member), 0.4872644;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.3654483;

$member = $summary->get_member_by_rank(5);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Lactobacillaceae; g__Lactobacillus; s__Lactobacillusiners';
is $member->taxon->node_name, 's__Lactobacillusiners';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.2598744;

$member = $summary->get_member_by_rank(6);
is $member->desc, 'k__Bacteria; p__Actinobacteria; c__Actinobacteria; o__Actinomycetales; f__Actinomycetaceae; g__Actinomyces; s__Actinomycesodontolyticus';
is $member->taxon->node_name, 's__Actinomycesodontolyticus';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.1624215;

$member = $summary->get_member_by_rank(7);
is $member->desc, 'k__Bacteria; p__Firmicutes; c__Bacilli; o__Lactobacillales; f__Enterococcaceae; g__Enterococcus; s__Enterococcusfaecalis';
is $member->taxon->node_name, 's__Enterococcusfaecalis';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 0.1392184;

is $summary->get_member_by_rank(8), undef;

is $summary_meta->next_community, undef;


# Taxonomic summaries level 5

$in = Bio::Community::IO->new(
   -file     => test_input_file('qiime_w_greengenes_taxo.txt'),
   -taxonomy => Bio::DB::Taxonomy->new( -source => 'list' ),
);

$community1 = $in->next_community;
$community2 = $in->next_community;
$community3 = $in->next_community;

$meta = Bio::Community::Meta->new(-communities => [$community1, $community2, $community3]);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 5,
), 'Taxonomic summary from multiple communities (level 5)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 3;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 41;
delta_ok $summary->get_rel_ab($member), 50.6172840;
$id1 = $member->id;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales';
is $member->taxon->node_name, 'o__Rickettsiales';
delta_ok $summary->get_count($member), 40;
delta_ok $summary->get_rel_ab($member), 49.3827160;
$id2 = $member->id;

is $summary->get_member_by_rank(3), undef;

$summary = $summary_meta->next_community;

$summary = $summary_meta->next_community;

is $summary_meta->next_community, undef;


# Taxonomic summaries level 4

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity => $meta,
   -merge_dups    => 0,
   -by_tax_level  => 4,
), 'Taxonomic summary from multiple communities (level 4)';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 3;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 41;
delta_ok $summary->get_rel_ab($member), 50.6172840;
$id2 = $member->id;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales';
is $member->taxon->node_name, 'o__Rickettsiales';
delta_ok $summary->get_count($member), 40;
delta_ok $summary->get_rel_ab($member), 49.3827160;
$id1 = $member->id;

is $summary->get_member_by_rank(3), undef;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2';
is $member->taxon->node_name, 'o__E2';
delta_ok $summary->get_count($member), 142;
delta_ok $summary->get_rel_ab($member), 100.0;
$id3 = $member->id;

is $summary->get_member_by_rank(2), undef;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales';
is $member->taxon->node_name, 'o__Rickettsiales';
delta_ok $summary->get_count($member), 76;
delta_ok $summary->get_rel_ab($member), 62.8099174;
is $member->id, $id1;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'Unknown taxonomy';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 43;
delta_ok $summary->get_rel_ab($member), 35.5371901;
is $member->id, $id2;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2';
is $member->taxon->node_name, 'o__E2';
delta_ok $summary->get_count($member), 2;
delta_ok $summary->get_rel_ab($member), 1.6528926;
is $member->id, $id3;

is $summary->get_member_by_rank(4), undef;

is $summary_meta->next_community, undef;


# Merge taxonomic duplicates

$in = Bio::Community::IO->new(
   -file     => test_input_file('qiime_w_silva_taxo_and_dups.txt'),
   -taxonomy => Bio::DB::Taxonomy->new( -source => 'list' ),
);
$community1 = $in->next_community;

$meta = Bio::Community::Meta->new(-communities => [$community1]);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity    => $meta,
   -merge_dups       => 1,
   -identify_dups_by => 'taxon',
), 'Merge taxonomic duplicates';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'Bacteria;Proteobacteria;Betaproteobacteria;Rhodocyclales;Rhodocyclaceae;Uliginosibacterium;Sphingomonas';
is $member->taxon->node_name, 'Sphingomonas';
delta_ok $summary->get_count($member), 27;
delta_ok $summary->get_rel_ab($member), 27;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'Archaea;Euryarchaeota;Halobacteria;Halobacteriales;Miscellaneous';
is $member->taxon->node_name, 'Miscellaneous';
delta_ok $summary->get_count($member), 19;
delta_ok $summary->get_rel_ab($member), 19;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'Bacteria;Proteobacteria;Betaproteobacteria;Rhodocyclales;Rhodocyclaceae';
is $member->taxon->node_name, 'Rhodocyclaceae';
delta_ok $summary->get_count($member), 17;
delta_ok $summary->get_rel_ab($member), 17;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'Eukaryota;Katablepharidophyta;Katablepharidaceae;Leucocryptos;;Leucocryptos';
is $member->taxon->node_name, 'Leucocryptos';
delta_ok $summary->get_count($member), 9;
delta_ok $summary->get_rel_ab($member), 9;

$member = $summary->get_member_by_rank(5);
is $member->desc, 'Bacteria;Proteobacteria;Alphaproteobacteria;Sphingomonadales;Sphingomonadaceae;Sphingobium;Sphingomonas';
is $member->taxon->node_name, 'Sphingomonas';
delta_ok $summary->get_count($member), 7;
delta_ok $summary->get_rel_ab($member), 7;

$member = $summary->get_member_by_rank(6);
is $member->desc, 'Eukaryota;Fungi;Chytridiomycota';
is $member->taxon->node_name, 'Chytridiomycota';
delta_ok $summary->get_count($member), 6.99;
delta_ok $summary->get_rel_ab($member), 6.99;

$member = $summary->get_member_by_rank(7);
is $member->desc, 'Archaea;Crenarchaeota;Miscellaneous';
is $member->taxon->node_name, 'Miscellaneous';
delta_ok $summary->get_count($member), 6.01;
delta_ok $summary->get_rel_ab($member), 6.01;

$member = $summary->get_member_by_rank(8);
is $member->desc, 'Bacteria;Proteobacteria;Alphaproteobacteria;Sphingomonadales;Sphingomonadaceae;Sphingomonas';
is $member->taxon->node_name, 'Sphingomonas';
delta_ok $summary->get_count($member), 6;
delta_ok $summary->get_rel_ab($member), 6;

$member = $summary->get_member_by_rank(9);
is $member->desc, 'Bacteria;Bacteroidetes;Sphingobacteria;Sphingobacteriales;Chitinophagaceae;Sediminibacterium;Flexibacter';
is $member->taxon->node_name, 'Flexibacter';
delta_ok $summary->get_count($member), 1.5;
delta_ok $summary->get_rel_ab($member), 1.5;

$member = $summary->get_member_by_rank(10);
is $member->desc, 'Bacteria;WCHB1-60';
is $member->taxon->node_name, 'WCHB1-60';
delta_ok $summary->get_count($member), 0.5;
delta_ok $summary->get_rel_ab($member), 0.5;

is $summary->get_member_by_rank(11), undef;

is $summary_meta->next_community, undef;


# Merge taxonomic duplicates, then summarize by taxonomy, then group low abundance groups

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity    => $meta,
   -merge_dups       => 1,
   -identify_dups_by => 'taxon',
   -by_tax_level     => 5,
   -by_rel_ab        => ['<=', 6.01],
), 'Multiple summary operations';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'Bacteria;Proteobacteria;Betaproteobacteria;Rhodocyclales;Rhodocyclaceae';
is $member->taxon->node_name, 'Rhodocyclaceae';
delta_ok $summary->get_count($member), 44;
delta_ok $summary->get_rel_ab($member), 44;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'Archaea;Euryarchaeota;Halobacteria;Halobacteriales;Miscellaneous';
is $member->taxon->node_name, 'Miscellaneous';
delta_ok $summary->get_count($member), 19;
delta_ok $summary->get_rel_ab($member), 19;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'Bacteria;Proteobacteria;Alphaproteobacteria;Sphingomonadales;Sphingomonadaceae';
is $member->taxon->node_name, 'Sphingomonadaceae';
delta_ok $summary->get_count($member), 13;
delta_ok $summary->get_rel_ab($member), 13;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'Eukaryota;Katablepharidophyta;Katablepharidaceae;Leucocryptos';
is $member->taxon->node_name, 'Leucocryptos';
delta_ok $summary->get_count($member), 9;
delta_ok $summary->get_rel_ab($member), 9;

$member = $summary->get_member_by_rank(5);
is $member->desc, 'Other <= 6.01 %';
is $member->taxon, undef;
delta_ok $summary->get_count($member), 8.01;
delta_ok $summary->get_rel_ab($member), 8.01;

$member = $summary->get_member_by_rank(6);
is $member->desc, 'Eukaryota;Fungi;Chytridiomycota';
is $member->taxon->node_name, 'Chytridiomycota';
delta_ok $summary->get_count($member), 6.99;
delta_ok $summary->get_rel_ab($member), 6.99;

is $summary->get_member_by_rank(7), undef;

is $summary_meta->next_community, undef;


# Merge description duplicates

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -metacommunity    => $meta,
   -merge_dups       => 1,
   -identify_dups_by => 'desc',
), 'Duplicates by description';

ok $summary_meta = $summarizer->get_summary;
isa_ok $summary_meta, 'Bio::Community::Meta';
is $summary_meta->get_communities_count, 1;

$summary = $summary_meta->next_community;

$member = $summary->get_member_by_rank(1);
is $member->desc, 'Bacteria;Proteobacteria;Betaproteobacteria;Rhodocyclales;Rhodocyclaceae;Uliginosibacterium;Sphingomonas';
delta_ok $summary->get_count($member), 27;

$member = $summary->get_member_by_rank(2);
is $member->desc, 'Archaea;Euryarchaeota;Halobacteria;Halobacteriales;Miscellaneous';
delta_ok $summary->get_count($member), 19;

$member = $summary->get_member_by_rank(3);
is $member->desc, 'Bacteria;Proteobacteria;Betaproteobacteria;Rhodocyclales;Rhodocyclaceae;uncultured;uncultured';
delta_ok $summary->get_count($member), 17;

$member = $summary->get_member_by_rank(4);
is $member->desc, 'Eukaryota;Katablepharidophyta;Katablepharidaceae;Leucocryptos;;Leucocryptos';
delta_ok $summary->get_count($member), 9;

$member = $summary->get_member_by_rank(5);
is $member->desc, 'Bacteria;Proteobacteria;Alphaproteobacteria;Sphingomonadales;Sphingomonadaceae;Sphingobium;Sphingomonas';
delta_ok $summary->get_count($member), 7;

$member = $summary->get_member_by_rank(6);
is $member->desc, 'Eukaryota;Fungi;Chytridiomycota;environmental';
delta_ok $summary->get_count($member), 6.99;

$member = $summary->get_member_by_rank(7);
is $member->desc, 'Archaea;Crenarchaeota;Miscellaneous';
delta_ok $summary->get_count($member), 6.01;

$member = $summary->get_member_by_rank(8);
is $member->desc, 'Bacteria;Proteobacteria;Alphaproteobacteria;Sphingomonadales;Sphingomonadaceae;Sphingomonas;uncultured';
delta_ok $summary->get_count($member), 5;

$member = $summary->get_member_by_rank(9);
is $member->desc, 'Bacteria;Bacteroidetes;Sphingobacteria;Sphingobacteriales;Chitinophagaceae;Sediminibacterium;Flexibacter';
delta_ok $summary->get_count($member), 1.5;

$member = $summary->get_member_by_rank(10);
is $member->desc, 'Bacteria; Proteobacteria; Alphaproteobacteria; Sphingomonadales; Sphingomonadaceae; Sphingomonas';
delta_ok $summary->get_count($member), 1;

$member = $summary->get_member_by_rank(11);
is $member->desc, 'Bacteria;WCHB1-60;unidentified';
delta_ok $summary->get_count($member), 0.5;

is $summary->get_member_by_rank(12), undef;

is $summary_meta->next_community, undef;


done_testing();

exit;


#------------------------------------------------------------------------------#


func get_group ($community) {
   my $group;
   while (my $member = $community->next_member) {
      if ($member->desc =~ m/other/i) {
         $group = $member;
         last;
      }
   }
   return $group;
}


