use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;
use Bio::Community::Meta;

use_ok($_) for qw(
    Bio::Community::Meta::Beta
);

my ($beta, $meta, $community1, $community2, $community3, $name1, $name2, $name3,
    $average, $distances);


# Identical communities

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 1 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 1 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );


# Basic object

$beta = Bio::Community::Meta::Beta->new( -metacommunity => $meta );
isa_ok $beta, 'Bio::Community::Meta::Beta';


# Get/set type of beta diversity

is $beta->type('euclidean'), 'euclidean';
delta_ok $beta->get_beta, 0;

is $beta->type('shared'), 'shared';
delta_ok $beta->get_beta, 100;


# Test all metrics

ok $beta = Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'euclidean' );
isa_ok $beta, 'Bio::Community::Meta::Beta';

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0, 'Identical communities';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'euclidean'     )->get_beta, 0; # synonym for euclidean
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 100;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 0;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0;


# Communities with all members shared and 0% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.4438603, 'Communities with all members shared and 0% permuted';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0.7046154;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.3523078;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3138566;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.3523077;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.2259613;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.0000000;


# Communities with all members shared and 100% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.4619764, 'Communities with all members shared and 100% permuted';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0.7312821;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.3656410;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3266667;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.3656410;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.2447829;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.5000000;


# Other communities with all members shared and 100% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.4552674, 'Other Communities with all members shared and 100% permuted';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0.7179487;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.3589744;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3219226;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.3589744;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.2377248;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.5000000;


# Communities with all members shared and 66% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.4507392, 'Communities with all members shared and 66% permuted';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0.7179487;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.3589744;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3187207;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.3589744;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.2330194;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 100.00000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 66.666667;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.3333333;


# Equally rich communities with some shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.4972609, 'Equally rich communities with some shared members';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 0.8584615;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.3523077;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3516165;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.4292308;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.2836025;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.5000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.3333333;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 66.666666;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.3333333;


# Unequally rich communities with some shared members (0% permuted)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 52 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 48 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.5576910, 'Unequally rich communities with some shared members (0% permuted)';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 1.0184615;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.4323077;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.3943471;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.5092308;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.3943384;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.6000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.4285714;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 66.666666;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 0.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.3333333;


# Other unequally rich communities with some shared members (90% permuted)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 10), 270 );
$community1->add_member( Bio::Community::Member->new(-id => 1 ),  90 );
$community1->add_member( Bio::Community::Member->new(-id => 2 ),  30 );
$community1->add_member( Bio::Community::Member->new(-id => 3 ),  10 );
$community1->add_member( Bio::Community::Member->new(-id => 4 ),   3 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 53 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 52 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 49 );
$community2->add_member( Bio::Community::Member->new(-id => 7), 48 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 47 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.7433693, 'Unequally rich communities with some shared members (90 % permuted)';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 1.4951719;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.6699752;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.5256415;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 0.7475860;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 0.8527229;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 0.5000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 0.3333333;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 80.000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, 80.000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 0.5200000;


# Communities with no shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 4), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 0.9337472, 'Communities with no shared members';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 2.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 0.6923077;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 0.6602589;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 0.0000000;
is       Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, undef;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 1.0000000;


# Maximum distance (no shared members)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 100 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '2-norm'        )->get_beta, 1.4142136, 'Maximum distance';
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => '1-norm'        )->get_beta, 2.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'hellinger'     )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'morisita-horn' )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'jaccard'       )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'sorensen'      )->get_beta, 1.0000000;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'shared'        )->get_beta, 0.0000000;
is       Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'permuted'      )->get_beta, undef;
delta_ok Bio::Community::Meta::Beta->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_beta, 1.0000000;


# Distance between all pairs

$community3 = Bio::Community->new( -name => 'sample3' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 100 );

$name1 = $community1->name;
$name2 = $community2->name;
$name3 = $community3->name;

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2, $community3] );

ok $beta = Bio::Community::Meta::Beta->new(
   -metacommunity => $meta,
   -type          => 'hellinger',
), 'All pairwise distances';
ok( ($average, $distances) = $beta->get_all_beta );
delta_ok $average, 0.6005191;
delta_ok $distances->{$name1}->{$name2}, 0.6614378;
delta_ok $distances->{$name2}->{$name1}, 0.6614378;
delta_ok $distances->{$name1}->{$name3}, 0.7071068;
delta_ok $distances->{$name3}->{$name1}, 0.7071068;
delta_ok $distances->{$name2}->{$name3}, 0.4330127;
delta_ok $distances->{$name3}->{$name2}, 0.4330127;


done_testing();

exit;
