use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community;
use Bio::Community::Member;
use Bio::Community::IO;

use_ok($_) for qw(
    Bio::Community::Meta
);

my ($meta, $community1, $community2, $community3, $community_all,
    $member, $member1, $member2, $member3                        );

my %ids;


# Bare object

ok $meta = Bio::Community::Meta->new( ), 'Bare object';
isa_ok $meta, 'Bio::Root::RootI';
isa_ok $meta, 'Bio::Community::Meta';

is $meta->name, '';
is $meta->identify_members_by, 'id';
is $meta->next_community, undef;

is_deeply [sort(map {ref $_}   @{$meta->get_all_communities})], [];
is_deeply [sort(map {$_->name} @{$meta->get_all_communities})], [];

is $meta->get_communities_count, 0;

is_deeply [sort(map {ref $_}   @{$meta->get_all_members})], [];
is_deeply [sort(map {$_->id}   @{$meta->get_all_members})], [];

is $meta->get_richness, 0;


# Basic metacommunity

$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );

$community1 = Bio::Community->new( -name => 'GOM' );
$community1->add_member( $member1, 10);
$community1->add_member( $member2, 10);
#community1->add_member( $member3,  0);

$community2 = Bio::Community->new( -name => 'BBC' );
#community2->add_member( $member1,   0);
$community2->add_member( $member2,  10);
$community2->add_member( $member3, 100);

$community3 = Bio::Community->new( -name => 'SAR' );
$community3->add_member( $member1, 25);
#community3->add_member( $member2,  0);
#community3->add_member( $member3,  0);

ok $meta = Bio::Community::Meta->new(
   -communities => [$community1],
   -name        => 'oceanic provinces'
), 'Basic metacommunity';
is $meta->name, 'oceanic provinces';
ok $meta->name('marine regions');
is $meta->name, 'marine regions';

is $meta->next_community->name, 'GOM';
is $meta->next_community, undef;

is_deeply [sort(map {ref $_}   @{$meta->get_all_communities})], ['Bio::Community'];
is_deeply [sort(map {$_->name} @{$meta->get_all_communities})], ['GOM'];

is $meta->get_communities_count, 1;

is_deeply [sort(map {ref $_}   @{$meta->get_all_members})], [('Bio::Community::Member')x2];
is_deeply [sort(map {$_->id}   @{$meta->get_all_members})], [1, 2];

is $meta->get_richness, 2;

is $meta->get_members_count, 20;


# Add communities

ok $meta->add_communities([$community2, $community3]), 'Add communities';

is $meta->next_community->name, 'GOM';
is $meta->next_community->name, 'BBC';
is $meta->next_community->name, 'SAR';
is $meta->next_community, undef;

is_deeply [sort(map {ref $_}   @{$meta->get_all_communities})], [('Bio::Community')x3];
is_deeply [sort(map {$_->name} @{$meta->get_all_communities})], ['BBC', 'GOM', 'SAR'];

is $meta->get_communities_count, 3;

is_deeply [sort(map {ref $_}  @{$meta->get_all_members})], [('Bio::Community::Member')x3];
is_deeply [sort(map {$_->id}  @{$meta->get_all_members})], [1, 2, 3];

is $meta->get_richness, 3;

is $meta->get_members_count, 155;


# Generate a metacommunity

ok $community_all = $meta->get_metacommunity, 'Metacommunity';
isa_ok $community_all, 'Bio::Community';

ok $member = $community_all->get_member_by_rank(1);
is $member->id, 3;
is $community_all->get_count($member), 100;
ok $member = $community_all->get_member_by_rank(2);
is $member->id, 1;
is $community_all->get_count($member), 35;
ok $member = $community_all->get_member_by_rank(3);
is $member->id, 2;
is $community_all->get_count($member), 20;
is $community_all->get_member_by_rank(4), undef;


# Remove communities

ok $meta->remove_community($community2), 'Remove communities';

is $meta->next_community->name, 'GOM';
is $meta->next_community->name, 'SAR';
is $meta->next_community, undef;

is_deeply [sort(map {ref $_}   @{$meta->get_all_communities})], [('Bio::Community')x2];
is_deeply [sort(map {$_->name} @{$meta->get_all_communities})], ['GOM', 'SAR'];

is $meta->get_community_by_name('SAR')->name, 'SAR';
is $meta->get_community_by_name('BBC'), undef;
is $meta->get_community_by_name('GOM')->name, 'GOM';

is $meta->get_communities_count, 2;

is_deeply [sort(map {ref $_}  @{$meta->get_all_members})], [('Bio::Community::Member')x2];
is_deeply [sort(map {$_->id}  @{$meta->get_all_members})], [1, 2];

is $meta->get_richness, 2;

is $meta->get_members_count, 45;


# Merging communities from different sources

$community1 = Bio::Community::IO->new(
   -file => test_input_file('to_merge_1.qiime'),
)->next_community;

$community2 = Bio::Community::IO->new(
   -file => test_input_file('to_merge_2.qiime'),
)->next_community;

ok $meta = Bio::Community::Meta->new( -identify_members_by => 'desc' ), 'Merging';
is $meta->identify_members_by, 'desc';

ok $meta->add_communities([$community1, $community2]);

# m5	m6
# 123	0	k__Bacteria;p__Bacteroidetes
# 527	0	k__Bacteria;p__Proteobacteria
# 91	446	k__Bacteria;p__Firmicutes
# 195	69	k__Bacteria;p__Actinobacteria
# 0	87	k__Archaea

ok $community1 = $meta->next_community;

$member = $community1->get_member_by_rank(1);
is $member->desc, 'k__Bacteria;p__Proteobacteria';
$ids{$member->desc} = $member->id;
is $community1->get_count($member), 527;
$member = $community1->get_member_by_rank(2);
is $member->desc, 'k__Bacteria;p__Actinobacteria';
$ids{$member->desc} = $member->id;
is $community1->get_count($member), 195;
$member = $community1->get_member_by_rank(3);
is $member->desc, 'k__Bacteria;p__Bacteroidetes';
$ids{$member->desc} = $member->id;
is $community1->get_count($member), 123;
$member = $community1->get_member_by_rank(4);
is $member->desc, 'k__Bacteria;p__Firmicutes';
$ids{$member->desc} = $member->id;
is $community1->get_count($member), 91;
is $community1->get_member_by_rank(5), undef;

ok $community2 = $meta->next_community;

$member = $community2->get_member_by_rank(1);
is $member->desc, 'k__Bacteria;p__Firmicutes';
is $ids{$member->desc}, $member->id;
is $community2->get_count($member), 446;
$member = $community2->get_member_by_rank(2);
is $member->desc, 'k__Archaea';
is $community2->get_count($member), 87;
$member = $community2->get_member_by_rank(3);
is $member->desc, 'k__Bacteria;p__Actinobacteria';
is $community2->get_count($member), 69;
is $community2->get_member_by_rank(4), undef;

is $meta->next_community, undef;


done_testing();

exit;
