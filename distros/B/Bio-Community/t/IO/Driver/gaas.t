use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $meta, $community, $community2, $member, $count,
   $taxonomy);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('gaas_compo.txt'),
), 'Format detection';
is $in->format, 'gaas';


# Read GAAS metacommunity

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('gaas_compo.txt'),
   -format => 'gaas',
), 'Read GAAS metacommunity';
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
delta_ok $meta->get_members_count, 1.0; # 100%
is $meta->get_communities_count, 1;
is $meta->get_richness, 3;
$in->close;


# Write BIOM metacommunity with name

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'gaas',
), 'Write GAAS metacommunity with a name';
ok $out->write_metacommunity($meta);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'gaas',
);
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
delta_ok $meta->get_members_count, 1.0;
is $meta->get_communities_count, 1;
is $meta->get_richness, 3;
$in->close;


# Read GAAS format

ok $taxonomy = Bio::DB::Taxonomy->new(
   #-source   => 'entrez',   # read NCBI taxonomy from the web
   -source    => 'flatfile', # read NCBI taxonomy from flatfiles
   -force     => 1,          # re-index file each time
   -nodesfile => test_input_file('taxonomy', 'ncbi_small_nodes.dmp'),
   -namesfile => test_input_file('taxonomy', 'ncbi_small_names.dmp'),
);

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('gaas_compo.txt'),
   -format   => 'gaas',
###   -taxonomy => $taxonomy, # segfault!?
), 'Read GAAS format';
isa_ok $in, 'Bio::Community::IO::Driver::gaas';
is $in->sort_members, -1;
is $in->abundance_type, 'fraction';
is $in->missing_string, 0;
is $in->multiple_communities, 0;
is $in->explicit_ids, 1;
###is $in->taxonomy, $taxonomy;

@methods = qw(
  _next_metacommunity_init _next_community_init next_member _next_community_finish _next_metacommunity_finish
  _write_metacommunity_init _write_community_init write_member _write_community_finish _write_metacommunity_finish)
;
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

@communities = ();
while ($community = $in->next_community) {
   isa_ok $community, 'Bio::Community';
   push @communities, $community;
}
$in->close;

is scalar @communities, 1;
$community = $communities[0];
is $community->get_richness, 3;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus pyogenes phage 315.1';
###is $member->taxon->id, 198538;
delta_ok $community->get_rel_ab($member), 79.1035649011735;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus Pellor';
###is $member->taxon->id, 376852;
delta_ok $community->get_rel_ab($member), 19.6094208626593;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus NI-2490';
###is $member->taxon->id, 376849;
delta_ok $community->get_rel_ab($member), 1.28701423616715;
is $member = $community->get_member_by_rank(4), undef;


# Write GAAS format and re-read it

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'gaas',
), 'Write GAAS format';
ok $out->write_community($community);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => '<'.$output_file,
   -format => 'gaas',
), 'Re-read GAAS format';
ok $community2 = $in->next_community;
is $in->next_community, undef;
$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus pyogenes phage 315.1';
###is $member->taxon->id, 198538;
delta_ok $community->get_rel_ab($member), 79.1035649011735;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus Pellor';
###is $member->taxon->id, 376852;
delta_ok $community->get_rel_ab($member), 19.6094208626593;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus NI-2490';
###is $member->taxon->id, 376849;
delta_ok $community->get_rel_ab($member), 1.28701423616715;
is $member = $community->get_member_by_rank(4), undef;


done_testing();

exit;
