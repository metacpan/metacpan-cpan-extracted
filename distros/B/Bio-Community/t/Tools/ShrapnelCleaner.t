use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community;
use Bio::Community::Meta;

use_ok($_) for qw(
    Bio::Community::Tools::ShrapnelCleaner
);


my ($cleaner, $meta, $community1, $community2, $member1, $member2, $member3,
    $member4, $member5, $member6);


$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$member6 = Bio::Community::Member->new( -id => 6 );


# Two communities

$community1 = Bio::Community->new( -name => 'community1' );
$community1->add_member( $member1,   1);
$community1->add_member( $member2,   1);
$community1->add_member( $member3,   5);
$community1->add_member( $member4,   1);
$community1->add_member( $member5, 125);

$community2 = Bio::Community->new( );
$community2->add_member( $member1,   1);
$community2->add_member( $member3, 100);
$community2->add_member( $member6,   4);

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );


# Basic cleaner object

ok $cleaner = Bio::Community::Tools::ShrapnelCleaner->new( );
isa_ok $cleaner, 'Bio::Community::Tools::ShrapnelCleaner';
throws_ok { $cleaner->clean } qr/EXCEPTION.*metacommunity/msi;

# Cleaner with default

ok $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
   -metacommunity => $meta,
), 'Default';
ok $cleaner->clean;

is $community1->get_count($member1),   1;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   1;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   4;


# Cleaner with specified count threshold

ok $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
   -metacommunity   => $meta,
   -count_threshold => 5,
), 'Specified count threshold';
ok $cleaner->clean;

is $community1->get_count($member1),   1;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   1;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   0;


# Cleaner with specified prevalence threshold

ok $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
   -metacommunity        => $meta,
   -prevalence_threshold => 2,
), 'Specified prevalence threshold';
ok $cleaner->clean;

is $community1->get_count($member1),   1;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   1;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   0;


# Cleaner with specified prevalence threshold

ok $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
   -metacommunity        => $meta,
   -count_threshold      => 2,
   -prevalence_threshold => 2,
), 'Specified count and prevalence thresholds';
ok $cleaner->clean;

is $community1->get_count($member1),   0;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   0;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   0;


done_testing();

exit;
