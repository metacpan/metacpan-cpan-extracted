use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $meta, $community, $community2, $community3,
   $member, $count, $taxonomy);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
), 'Format detection';
is $in->format, 'generic';


# Read generic metacommunity

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
   -format => 'generic',
), 'Read generic metacommunity';
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
delta_ok $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;


# Write generic metacommunity with name

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write generic metacommunity with a name';
ok $out->write_metacommunity($meta);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'generic',
);
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
delta_ok $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;


# Read generic format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
   -format => 'generic',
), 'Read generic format';
isa_ok $in, 'Bio::Community::IO::Driver::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is $in->multiple_communities, 1;
is $in->explicit_ids, 0;

@methods = qw(
  _next_metacommunity_init _next_community_init next_member _next_community_finish _next_metacommunity_finish
  _write_metacommunity_init _write_community_init write_member _write_community_finish _write_metacommunity_finish)
;
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
delta_ok $community->get_count($member), 241;
is $member = $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
delta_ok $community2->get_count($member), 1023.9;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
delta_ok $community2->get_count($member), 334;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
delta_ok $community2->get_count($member), 123;
is $community2->get_member_by_rank(4), undef;


# Write generic format

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write generic format';
ok $out->write_community($community);
ok $out->write_community($community2);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'generic',
), 'Re-read generic format';

ok $community = $in->next_community;
ok $member = $community->get_member_by_rank(1);
is $member->desc, 'Streptococcus';
delta_ok $community->get_count($member), 241;
is $member = $community->get_member_by_rank(2), undef;

ok $community2 = $in->next_community;
ok $member = $community2->get_member_by_rank(1);
is $member->desc, 'Goatpox virus';
delta_ok $community2->get_count($member), 1023.9;
ok $member = $community2->get_member_by_rank(2);
is $member->desc, 'Streptococcus';
delta_ok $community2->get_count($member), 334;
ok $member = $community2->get_member_by_rank(3);
is $member->desc, 'Lumpy skin disease virus';
delta_ok $community2->get_count($member), 123;
is $community2->get_member_by_rank(4), undef;

is $in->next_community, undef;

$in->close;


# Read QIIME summarized OTU table (Silva taxonomy)

ok $taxonomy = Bio::DB::Taxonomy->new(
   -source   => 'silva',
   -taxofile => test_input_file('taxonomy', 'silva_SSURef_108_tax_silva_trunc.fasta'),
);

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('qiime_w_silva_taxo_L2.txt'),
   -format   => 'generic',
   -taxonomy => $taxonomy,
), 'Read summarized QIIME file (Silva taxonomy)';

is $in->taxonomy, $taxonomy;

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'FI.5m';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'RI.5m';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, 'TR.5m';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community->get_count($member), 0.5514950166;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $member->taxon->node_name, 'Euryarchaeota';
delta_ok $community->get_count($member), 0.2342192691;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community->get_count($member), 0.2142857143;
is $community->get_member_by_rank(4), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community2->get_count($member), 0.9536354057;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community2->get_count($member), 0.0463645943;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community3->get_count($member), 0.5804511278;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $member->taxon->node_name, 'Euryarchaeota';
delta_ok $community3->get_count($member), 0.4;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community3->get_count($member), 0.0195488722;
is $community3->get_member_by_rank(4), undef;


# Read QIIME summarized OTU table (on-the-fly taxonomy)

ok $taxonomy = Bio::DB::Taxonomy->new(
   -source   => 'list',
);

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('qiime_w_silva_taxo_L2.txt'),
   -format   => 'generic',
   -taxonomy => $taxonomy,
), 'Read summarized QIIME file (on-the-fly taxonomy)';

is $in->taxonomy, $taxonomy;

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'FI.5m';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'RI.5m';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, 'TR.5m';

is $in->next_community, undef;

$in->close;

is $taxonomy->get_num_taxa, 7; # 6 really, but 7 is ok.

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community->get_count($member), 0.5514950166;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $member->taxon->node_name, 'Euryarchaeota';
delta_ok $community->get_count($member), 0.2342192691;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community->get_count($member), 0.2142857143;
is $community->get_member_by_rank(4), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community2->get_count($member), 0.9536354057;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community2->get_count($member), 0.0463645943;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $member->taxon->node_name, 'Proteobacteria';
delta_ok $community3->get_count($member), 0.5804511278;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $member->taxon->node_name, 'Euryarchaeota';
delta_ok $community3->get_count($member), 0.4;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $member->taxon->node_name, 'Viridiplantae';
delta_ok $community3->get_count($member), 0.0195488722;
is $community3->get_member_by_rank(4), undef;


# Write QIIME summarized OTU table

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write summarized QIIME file';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'generic',
), 'Re-read summarized QIIME file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'FI.5m';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'RI.5m';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, 'TR.5m';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
delta_ok $community->get_count($member), 0.5514950166;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
delta_ok $community->get_count($member), 0.2342192691;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
delta_ok $community->get_count($member), 0.2142857143;
is $community->get_member_by_rank(4), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
delta_ok $community2->get_count($member), 0.9536354057;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
delta_ok $community2->get_count($member), 0.0463645943;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
delta_ok $community3->get_count($member), 0.5804511278;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
delta_ok $community3->get_count($member), 0.4;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
delta_ok $community3->get_count($member), 0.0195488722;
is $community3->get_member_by_rank(4), undef;


done_testing();

exit;
