use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Meta;

use_ok($_) for qw(
    Bio::Community::Tools::Transformer
);


my ($transformer, $meta, $transformed, $community, $community1, $community2,
    $member1, $member2, $member3, $member4, $member5, $member6);


# Build a metacommunity

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$member6 = Bio::Community::Member->new( -id => 6 );
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$community1->add_member( $member4, 4);
$community1->add_member( $member5, 5);

$community2 = Bio::Community->new( -name => 'community2' );
$member6 = Bio::Community::Member->new( -id => 6 );
$community2->add_member( $member1, 2014);
$community2->add_member( $member3, 1057);
$community2->add_member( $member6, 2514);

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );


# Basic transformer object

ok $transformer = Bio::Community::Tools::Transformer->new( );
isa_ok $transformer, 'Bio::Community::Tools::Transformer';
throws_ok { $transformer->get_transformed_meta } qr/EXCEPTION.*metacommunity/msi;


# Identity transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'identity',
), 'Identity';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'identity';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
is $transformed->get_members_count  , 15;
is $transformed->get_count($member1),  1;
is $transformed->get_count($member2),  2;
is $transformed->get_count($member3),  3;
is $transformed->get_count($member4),  4;
is $transformed->get_count($member5),  5;
is $transformed->get_count($member6),  0;

$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
is $transformed->get_members_count  , 5585;
is $transformed->get_count($member1), 2014;
is $transformed->get_count($member2),    0;
is $transformed->get_count($member3), 1057;
is $transformed->get_count($member4),    0;
is $transformed->get_count($member5),    0;
is $transformed->get_count($member6), 2514;


# Binary transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'binary',
), 'Binary';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'binary';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
is $transformed->get_members_count  , 5;
is $transformed->get_count($member1), 1;
is $transformed->get_count($member2), 1;
is $transformed->get_count($member3), 1;
is $transformed->get_count($member4), 1;
is $transformed->get_count($member5), 1;
is $transformed->get_count($member6), 0;


$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
is $transformed->get_members_count  , 3;
is $transformed->get_count($member1), 1;
is $transformed->get_count($member2), 0;
is $transformed->get_count($member3), 1;
is $transformed->get_count($member4), 0;
is $transformed->get_count($member5), 0;
is $transformed->get_count($member6), 1;


# Relative transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'relative',
), 'Relative';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'relative';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
is $transformed->get_members_count  , 100;
is $transformed->get_count($member1), $transformed->get_rel_ab($member1);
is $transformed->get_count($member2), $transformed->get_rel_ab($member2);
is $transformed->get_count($member3), $transformed->get_rel_ab($member3);
is $transformed->get_count($member4), $transformed->get_rel_ab($member4);
is $transformed->get_count($member5), $transformed->get_rel_ab($member5);
is $transformed->get_count($member6), $transformed->get_rel_ab($member6);


$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
is $transformed->get_members_count  , 100;
is $transformed->get_count($member1), $transformed->get_rel_ab($member1);
is $transformed->get_count($member2), $transformed->get_rel_ab($member2);
is $transformed->get_count($member3), $transformed->get_rel_ab($member3);
is $transformed->get_count($member4), $transformed->get_rel_ab($member4);
is $transformed->get_count($member5), $transformed->get_rel_ab($member5);
is $transformed->get_count($member6), $transformed->get_rel_ab($member6);


# Hellinger transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'hellinger',
), 'Hellinger';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'hellinger';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
delta_ok $transformed->get_members_count  , 8.38233234744176;
delta_ok $transformed->get_count($member1), 1;
delta_ok $transformed->get_count($member2), 1.41421356237310;
delta_ok $transformed->get_count($member3), 1.73205080756888;
delta_ok $transformed->get_count($member4), 2;
delta_ok $transformed->get_count($member5), 2.23606797749979;
delta_ok $transformed->get_count($member6), 0;

$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
delta_ok $transformed->get_members_count  , 127.528952305538;
delta_ok $transformed->get_count($member1), 44.877611344633749;
delta_ok $transformed->get_count($member2), 0;
delta_ok $transformed->get_count($member3), 32.511536414017719;
delta_ok $transformed->get_count($member4), 0;
delta_ok $transformed->get_count($member5), 0;
delta_ok $transformed->get_count($member6), 50.139804546886701;


# Chord transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'chord',
), 'Chord';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'chord';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
delta_ok $transformed->get_members_count  , 0.272727272727273;
delta_ok $transformed->get_count($member1), 0.0181818181818182;
delta_ok $transformed->get_count($member2), 0.0363636363636364;
delta_ok $transformed->get_count($member3), 0.0545454545454545;
delta_ok $transformed->get_count($member4), 0.0727272727272727;
delta_ok $transformed->get_count($member5), 0.0909090909090909;
delta_ok $transformed->get_count($member6), 0;

$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
delta_ok $transformed->get_members_count  , 4.85920867025514e-04;
delta_ok $transformed->get_count($member1), 1.75227327876345e-04;
delta_ok $transformed->get_count($member2), 0;
delta_ok $transformed->get_count($member3), 9.19638955140499e-05;
delta_ok $transformed->get_count($member4), 0;
delta_ok $transformed->get_count($member5), 0;
delta_ok $transformed->get_count($member6), 2.18729643635120e-04;


done_testing();

exit;
