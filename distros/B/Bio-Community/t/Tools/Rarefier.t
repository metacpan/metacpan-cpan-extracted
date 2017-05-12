use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Meta;

BEGIN {
    test_begin(-requires_module => 'Math::GSL::RNG');
}

use_ok($_) for qw(
    Bio::Community::Tools::Rarefier
);


my ($rarefier, $meta, $community1, $community2, $community3, $average, $representative,
   $member1 , $member2 , $member3 , $member4 , $member5 , $member6 , $member7 , $member8 , $member9 , $member10,
   $member11, $member12, $member13, $member14, $member15, $member16, $member17, $member18, $member19, $member20,
   $member21, $member22, $member23, $member24, $member25, $member26, $member27, $member28, $member29, $member30,
   $member31, $member32, $member33, $member34, $member35, $member36, $member37, $member38, $member39, $member40,
   $member41, $member42, $member43);

my $epsilon1 = 20;
my $epsilon2 = 1.5;
my $epsilon3 = 0.4;


# Community with 1500.8 counts

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$community1->add_member( $member1, 301.8);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 299);


# Community with 5585 counts

$community2 = Bio::Community->new( -name => 'community2' );
$member6 = Bio::Community::Member->new( -id => 6 );
$community2->add_member( $member1, 2014);
$community2->add_member( $member3, 1057);
$community2->add_member( $member6, 2514);


# Other members
$member7  = Bio::Community::Member->new( -id => 7 );
$member8  = Bio::Community::Member->new( -id => 8 );
$member9  = Bio::Community::Member->new( -id => 9 );
$member10 = Bio::Community::Member->new( -id => 10 );
$member11 = Bio::Community::Member->new( -id => 11 );
$member12 = Bio::Community::Member->new( -id => 12 );
$member13 = Bio::Community::Member->new( -id => 13 );
$member14 = Bio::Community::Member->new( -id => 14 );
$member15 = Bio::Community::Member->new( -id => 15 );
$member16 = Bio::Community::Member->new( -id => 16 );
$member17 = Bio::Community::Member->new( -id => 17 );
$member18 = Bio::Community::Member->new( -id => 18 );
$member19 = Bio::Community::Member->new( -id => 19 );
$member20 = Bio::Community::Member->new( -id => 20 );
$member21 = Bio::Community::Member->new( -id => 21 );
$member22 = Bio::Community::Member->new( -id => 22 );
$member23 = Bio::Community::Member->new( -id => 23 );
$member24 = Bio::Community::Member->new( -id => 24 );
$member25 = Bio::Community::Member->new( -id => 25 );
$member26 = Bio::Community::Member->new( -id => 26 );
$member27 = Bio::Community::Member->new( -id => 27 );
$member28 = Bio::Community::Member->new( -id => 28 );
$member29 = Bio::Community::Member->new( -id => 29 );
$member30 = Bio::Community::Member->new( -id => 30 );
$member31 = Bio::Community::Member->new( -id => 31 );
$member32 = Bio::Community::Member->new( -id => 32 );
$member33 = Bio::Community::Member->new( -id => 33 );
$member34 = Bio::Community::Member->new( -id => 34 );
$member35 = Bio::Community::Member->new( -id => 35 );
$member36 = Bio::Community::Member->new( -id => 36 );
$member37 = Bio::Community::Member->new( -id => 37 );
$member38 = Bio::Community::Member->new( -id => 38 );
$member39 = Bio::Community::Member->new( -id => 39 );
$member40 = Bio::Community::Member->new( -id => 40 );
$member41 = Bio::Community::Member->new( -id => 41 );
$member42 = Bio::Community::Member->new( -id => 42 );
$member43 = Bio::Community::Member->new( -id => 43 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );


# Basic rarefier object

ok $rarefier = Bio::Community::Tools::Rarefier->new( ), 'Bare object';
isa_ok $rarefier, 'Bio::Community::Tools::Rarefier';
throws_ok { $rarefier->get_repr_meta } qr/EXCEPTION.*metacommunity/msi;


# Normalizer with sample size of zero

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 10,
   -sample_size     => 0,
   -seed            => 12537409,
), 'Sample size 0';

is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_repr_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 10;
isnt $rarefier->threshold, 0.001;
cmp_ok $rarefier->threshold, '<', 1;
is $rarefier->sample_size, 0;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 0;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 0;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 0;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 0;


# Normalizer with sample size of zero (and inf repetitions)

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 'inf',
   -sample_size     => 0,
   -seed            => 12537409,
), 'Sample size 0 (inf)';

is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_repr_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 'inf';
isnt $rarefier->threshold, 0.001;
cmp_ok $rarefier->threshold, '<', 1;
is $rarefier->sample_size, 0;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 0;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 0;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 0;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 0;


# Normalizer with some repetitions

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 10,
   -sample_size     => 1000,
   -verbose         => 1,
   -seed            => 12537409,
), 'Specified repetitions';

is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_repr_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 10;
isnt $rarefier->threshold, 0.001;
cmp_ok $rarefier->threshold, '<', 1;
is $rarefier->sample_size, 1000;
is $rarefier->verbose, 1;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Normalizer with one repetitions

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 1,
   -sample_size     => 1000,
   -seed            => 12537409,
), 'Single repetition';

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
delta_ok $average->get_members_count, 1000;

my $compo1 = {
   1 => $average->get_count($member1),
   2 => $average->get_count($member2),
   3 => $average->get_count($member3),
   4 => $average->get_count($member4),
   5 => $average->get_count($member5),
};

$rarefier->sample_size(1000);

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
delta_ok $average->get_members_count, 1000;

my $compo2 = {
   1 => $average->get_count($member1),
   2 => $average->get_count($member2),
   3 => $average->get_count($member3),
   4 => $average->get_count($member4),
   5 => $average->get_count($member5),
};

isnt $compo1->{1}, $compo2->{1}; # reusing same Rarefier & seed leads to different numbers
isnt $compo1->{2}, $compo2->{2};
isnt $compo1->{3}, $compo2->{3};
isnt $compo1->{4}, $compo2->{4};
isnt $compo1->{5}, $compo2->{5};


# Assume an infinity of bootstrap repetitions (and reusing previous object)

ok $rarefier->num_repetitions('inf'), 'Infinite repetitions';
is $rarefier->verbose(0), 0;

is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_repr_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 'inf';
is $rarefier->verbose, 0;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Same thing, but silently dropping communities that have a low count

ok $rarefier->drop(1), 'Drop option';
ok $rarefier->sample_size(2000);

is $rarefier->get_avg_meta->get_communities_count, 1;
is $rarefier->get_repr_meta->get_communities_count, 1;

is $rarefier->sample_size, 2000;
is $rarefier->drop, 1;

is $rarefier->get_avg_meta->get_community_by_name('community1'), undef;
is $rarefier->get_repr_meta->get_community_by_name('community1'), undef;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
delta_ok $average->get_members_count, 2000;


# Normalizer with manually specified threshold

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity => $meta,
   -threshold     => 1E-3,
   -sample_size   => 1000,
   -seed          => 12537409,
), 'Specified threshold';
is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_repr_meta->get_communities_count, 2;

cmp_ok $rarefier->num_repetitions, '>=', 3;
is $rarefier->threshold, 0.001;
is $rarefier->sample_size, 1000;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $average->get_count($member6), $epsilon2;


# Normalizer with automatic sample size and repetitions overriding threshold

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -threshold       => 1E-3,
   -num_repetitions => 10,
   -seed            => 12537409,
), 'Automatic sample size';
is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_avg_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 10;
isnt $rarefier->threshold, 0.001;
cmp_ok $rarefier->threshold, '<', 1;
is $rarefier->sample_size, 1500;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 1500;
delta_within $average->get_count($member1), 301, $epsilon1;
delta_within $average->get_count($member2), 300, $epsilon1;
delta_within $average->get_count($member3), 300, $epsilon1;
delta_within $average->get_count($member4), 300, $epsilon1;
delta_within $average->get_count($member5), 299, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 1500;
delta_within $average->get_count($member1), 540.9, $epsilon1;
delta_within $average->get_count($member3), 283.9, $epsilon1;
delta_within $average->get_count($member6), 675.2, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $average->get_count($member6), $epsilon2;


# Normalizer with sample that should exclude some members from representative

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 50,
   -sample_size     => 4,
   -seed            => 12537409,
), 'Representative communities';
is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_avg_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 50;
isnt $rarefier->threshold, 0.00001;
cmp_ok $rarefier->threshold, '<', 10;
is $rarefier->sample_size, 4;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 4;
delta_ok $average->get_richness, 5;
delta_within $average->get_count($member1), 0.803, $epsilon3;
delta_within $average->get_count($member2), 0.800, $epsilon3;
delta_within $average->get_count($member3), 0.800, $epsilon3;
delta_within $average->get_count($member4), 0.800, $epsilon3;
delta_within $average->get_count($member5), 0.797, $epsilon3;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 4;
cmp_ok $representative->get_richness, '<=', 4; # statistically, one member should disappear
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 4;
delta_ok $average->get_richness, 3;
delta_within $average->get_count($member1), 1.44 , $epsilon3;
delta_within $average->get_count($member3), 0.757, $epsilon3;
delta_within $average->get_count($member6), 1.801, $epsilon3;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 4;
cmp_ok $representative->get_richness, '<=', 3;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Normalizer with sample that should exclude some members from representative

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 50,
   -sample_size     => 4,
   -seed            => 12537409,
), 'More representative communities';
is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_avg_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 50;
isnt $rarefier->threshold, 0.1;
cmp_ok $rarefier->threshold, '<', 10;
is $rarefier->sample_size, 4;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 4;
delta_ok $average->get_richness, 5;
delta_within $average->get_count($member1), 0.803, $epsilon3;
delta_within $average->get_count($member2), 0.800, $epsilon3;
delta_within $average->get_count($member3), 0.800, $epsilon3;
delta_within $average->get_count($member4), 0.800, $epsilon3;
delta_within $average->get_count($member5), 0.797, $epsilon3;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 4;
cmp_ok $representative->get_richness, '<=', 4;  # statistically, one member should disappear
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community2');
isa_ok $average, 'Bio::Community';
is $average->name, 'community2';
delta_ok $average->get_members_count, 4;
delta_ok $average->get_richness, 3;
delta_within $average->get_count($member1), 1.44 , $epsilon3;
delta_within $average->get_count($member3), 0.757, $epsilon3;
delta_within $average->get_count($member6), 1.801, $epsilon3;

$representative = $rarefier->get_repr_meta->get_community_by_name('community2');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community2';
delta_ok $representative->get_members_count, 4;
cmp_ok $representative->get_richness, '<=', 3;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Representative of a specific average community

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.1);
$average->add_member( $member2, 1.2);
$average->add_member( $member3, 0.8);
$average->add_member( $member4, 0.9);

delta_ok $average->get_richness, 4;
delta_ok $average->get_members_count, 4;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 4;
delta_ok $representative->get_richness, 4;
delta_ok $representative->get_count($member1), 1;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 1;
delta_ok $representative->get_count($member4), 1;


# Representative of an average community (one extra using rounded)

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.2);
$average->add_member( $member2, 0.7);
$average->add_member( $member3, 0.6);
$average->add_member( $member4, 0.5);

delta_ok $average->get_richness, 4;
delta_ok $average->get_members_count, 3;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 3;
delta_ok $representative->get_richness, 3;
delta_ok $representative->get_count($member1), 1;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 1;
delta_ok $representative->get_count($member4), 0;


# Representative of an average community (missing one count using rounded)

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 2.3);
$average->add_member( $member2, 2.2);
$average->add_member( $member3, 2.1);
$average->add_member( $member4, 0.4);

delta_ok $average->get_richness, 4;
delta_ok $average->get_members_count, 7;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 7;
delta_ok $representative->get_richness, 4;
delta_ok $representative->get_count($member1), 2;
delta_ok $representative->get_count($member2), 2;
delta_ok $representative->get_count($member3), 2;
delta_ok $representative->get_count($member4), 1;


# Representative of an average community (missing one count using rounded)

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.471);
$average->add_member( $member2, 1.040);
$average->add_member( $member3, 0.246);
$average->add_member( $member4, 0.243);

delta_ok $average->get_richness, 4;
delta_ok $average->get_members_count, 3;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 3;
delta_ok $representative->get_richness, 2;
delta_ok $representative->get_count($member1), 2;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 0;
delta_ok $representative->get_count($member4), 0;


# Representative of an average community (missing two counts using rounded)

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 90.70);
$average->add_member( $member2,  5.10);
$average->add_member( $member3,  1.10);
$average->add_member( $member4,  0.50);
$average->add_member( $member5,  0.43);
$average->add_member( $member6,  0.42);
$average->add_member( $member7,  0.41);
$average->add_member( $member8,  0.39);
$average->add_member( $member9,  0.38);
$average->add_member( $member10, 0.37);
$average->add_member( $member11, 0.20);

delta_ok $average->get_richness, 11;
delta_ok $average->get_members_count, 100;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 100;
delta_ok $representative->get_richness, 6;
delta_ok $representative->get_count($member1), 91;
delta_ok $representative->get_count($member2),  5;
delta_ok $representative->get_count($member3),  1;
delta_ok $representative->get_count($member4),  1;
delta_ok $representative->get_count($member5),  1;
delta_ok $representative->get_count($member6),  1;


# Representative of an average community (4 extras using rounded)

ok $rarefier = Bio::Community::Tools::Rarefier->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1743.71);
$average->add_member( $member2,   93.73);
$average->add_member( $member3,   21.10);
$average->add_member( $member4,   18.13);
$average->add_member( $member5,   15.43);
$average->add_member( $member6,   11.93);
$average->add_member( $member7,   10.78);
$average->add_member( $member8,   10.06);
$average->add_member( $member9,    9.85);
$average->add_member( $member10,   9.68);
$average->add_member( $member11,   6.84);
$average->add_member( $member12,   5.11);
$average->add_member( $member13,   4.56);
$average->add_member( $member14,   4.25);
$average->add_member( $member15,   3.26);
$average->add_member( $member16,   2.48);
$average->add_member( $member17,   1.97);
$average->add_member( $member18,   1.85);
$average->add_member( $member19,   1.81);
$average->add_member( $member20,   1.67);
$average->add_member( $member21,   1.66);
$average->add_member( $member22,   1.65);
$average->add_member( $member23,   1.45);
$average->add_member( $member24,   0.98);
$average->add_member( $member25,   0.98);
$average->add_member( $member26,   0.95);
$average->add_member( $member27,   0.93);
$average->add_member( $member28,   0.91);
$average->add_member( $member29,   0.89);
$average->add_member( $member30,   0.88);
$average->add_member( $member31,   0.88);
$average->add_member( $member32,   0.88);
$average->add_member( $member33,   0.87);
$average->add_member( $member34,   0.86);
$average->add_member( $member35,   0.85);
$average->add_member( $member36,   0.85);
$average->add_member( $member37,   0.80);
$average->add_member( $member38,   0.78);
$average->add_member( $member39,   0.78);
$average->add_member( $member40,   0.78);
$average->add_member( $member41,   0.75);
$average->add_member( $member42,   0.73);
$average->add_member( $member43,   0.71);

delta_ok $average->get_richness, 43;
delta_ok $average->get_members_count, 2000;

ok $representative = $rarefier->_calc_repr($average);

delta_ok $representative->get_members_count, 2000;
delta_ok $representative->get_richness, 43;
delta_ok $representative->get_count($member1 ), 1744;
delta_ok $representative->get_count($member2 ),   94;
delta_ok $representative->get_count($member3 ),   21;
delta_ok $representative->get_count($member4 ),   18;
delta_ok $representative->get_count($member5 ),   15;
delta_ok $representative->get_count($member6 ),   12;
delta_ok $representative->get_count($member7 ),   11;
delta_ok $representative->get_count($member8 ),   10;
delta_ok $representative->get_count($member9 ),   10;
delta_ok $representative->get_count($member10),   10;
delta_ok $representative->get_count($member11),    7;
delta_ok $representative->get_count($member12),    5;
delta_ok $representative->get_count($member13),    4; # rounded is 5
delta_ok $representative->get_count($member14),    4;
delta_ok $representative->get_count($member15),    3;
delta_ok $representative->get_count($member16),    2;
delta_ok $representative->get_count($member17),    2;
delta_ok $representative->get_count($member18),    2;
delta_ok $representative->get_count($member19),    2;
delta_ok $representative->get_count($member20),    1; # rounded is 2
delta_ok $representative->get_count($member21),    1; # rounded is 2
delta_ok $representative->get_count($member22),    1; # rounded is 2
delta_ok $representative->get_count($member23),    1;
delta_ok $representative->get_count($member24),    1;
delta_ok $representative->get_count($member25),    1;
delta_ok $representative->get_count($member26),    1;
delta_ok $representative->get_count($member27),    1;
delta_ok $representative->get_count($member28),    1;
delta_ok $representative->get_count($member29),    1;
delta_ok $representative->get_count($member30),    1;
delta_ok $representative->get_count($member31),    1;
delta_ok $representative->get_count($member32),    1;
delta_ok $representative->get_count($member33),    1;
delta_ok $representative->get_count($member34),    1;
delta_ok $representative->get_count($member35),    1;
delta_ok $representative->get_count($member36),    1;
delta_ok $representative->get_count($member37),    1;
delta_ok $representative->get_count($member38),    1;
delta_ok $representative->get_count($member39),    1;
delta_ok $representative->get_count($member40),    1;
delta_ok $representative->get_count($member41),    1;
delta_ok $representative->get_count($member42),    1;
delta_ok $representative->get_count($member43),    1;


# Using weights should yield same results since we operate on counts (not relative abundance)

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1, -weights => [8] );
$member2 = Bio::Community::Member->new( -id => 2, -weights => [3] );
$member3 = Bio::Community::Member->new( -id => 3, -weights => [15] );
$member4 = Bio::Community::Member->new( -id => 4, -weights => [7] );
$member5 = Bio::Community::Member->new( -id => 5, -weights => [2] );
$community1->add_member( $member1, 301);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 299);

$community3 = Bio::Community->new( -name => 'community3' );
$member6 = Bio::Community::Member->new( -id => 10 );
$community3->add_member( $member1, 2014);
$community3->add_member( $member3, 1057);
$community3->add_member( $member6, 2514);

$meta = Bio::Community::Meta->new( -communities => [$community1, $community3] );

ok $rarefier = Bio::Community::Tools::Rarefier->new(
   -metacommunity   => $meta,
   -num_repetitions => 10,
   -sample_size     => 1000,
   -seed            => 12537409,
);

is $rarefier->get_avg_meta->get_communities_count, 2;
is $rarefier->get_avg_meta->get_communities_count, 2;

is $rarefier->num_repetitions, 10;
isnt $rarefier->threshold, 0.1;
cmp_ok $rarefier->threshold, '<', 1;
is $rarefier->sample_size, 1000;

$average = $rarefier->get_avg_meta->get_community_by_name('community1');
isa_ok $average, 'Bio::Community';
is $average->name, 'community1';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community1');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community1';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $rarefier->get_avg_meta->get_community_by_name('community3');
isa_ok $average, 'Bio::Community';
is $average->name, 'community3';
delta_ok $average->get_members_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $rarefier->get_repr_meta->get_community_by_name('community3');
isa_ok $representative, 'Bio::Community';
is $representative->name, 'community3';
delta_ok $representative->get_members_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;



done_testing();

exit;
