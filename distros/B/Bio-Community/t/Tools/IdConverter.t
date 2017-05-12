use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::IdConverter
);


my ($meta1, $meta2, $community1, $community2, $member1, $member2, $member3, $count, $converter);

my %info;


# Basic cleaner object

ok $converter = Bio::Community::Tools::IdConverter->new( ), 'Basic object';
isa_ok $converter, 'Bio::Community::Tools::IdConverter';
throws_ok { $converter->get_converted_meta } qr/EXCEPTION.*metacommunity/msi;


# Test ID conversion to cluster ID representative

$member1 = Bio::Community::Member->new( -id => 187144 );
$member2 = Bio::Community::Member->new( -id => 563209 );
$member3 = Bio::Community::Member->new( -id => 310677 );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity => $meta1,
   -cluster_file  => test_input_file('gg_99_otu_map.txt'),
), 'From cluster ID representative file';

ok $meta2 = $converter->get_converted_meta;
isa_ok $meta2, 'Bio::Community::Meta';
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}
is_deeply \%info, { '187144' => 1, '355095' => 5 };

isnt $meta1, $meta2;


# Test ID conversion to taxonomic ID representative

$member1 = Bio::Community::Member->new( -id => 340 );
$member2 = Bio::Community::Member->new( -id => 345 );
$member3 = Bio::Community::Member->new( -id => 344 );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity  => $meta1,
   -taxassign_file => test_input_file('rep_set_tax_assignments.txt'),
), 'From taxonomic assignment file';

ok $meta2 = $converter->get_converted_meta;
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}
is_deeply \%info, { '1042485' => 5, '219826' => 1 };

isnt $meta1, $meta2;


# Test ID conversion to BLAST best similarity

$member1 = Bio::Community::Member->new( -id => 'OTU_4'   );
$member2 = Bio::Community::Member->new( -id => 'OTU_12'  );
$member3 = Bio::Community::Member->new( -id => 'OTU_324' );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity => $meta1,
   -blast_file    => test_input_file('blast_tab_usearch.txt'),
), 'From BLAST file';

warnings_like { $meta2 = $converter->get_converted_meta }
        [qr/Multiple entries found/i, qr/Keeping original/i];

ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}
is_deeply \%info, { 'JN647692.1.1869' => 1, '655879' => 2, 'OTU_324' => 3 };

isnt $meta1, $meta2;


# Test ID conversion to member description

$member1 = Bio::Community::Member->new( -id => 1, -desc => 'OTU_4'   );
$member2 = Bio::Community::Member->new( -id => 2, -desc => 'OTU_12'  );
$member3 = Bio::Community::Member->new( -id => 3, -desc => 'OTU_324' );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity     => $meta1,
   -member_attr       => 'desc',
), 'From member description';

ok $meta2 = $converter->get_converted_meta;
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}

is_deeply \%info, { 'OTU_4' => 1, 'OTU_12' => 2, 'OTU_324' => 3 };

isnt $meta1, $meta2;


# Test appending

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity     => $meta1,
   -member_attr       => 'desc',
   -conversion_method => 'append',
), 'Append';

ok $meta2 = $converter->get_converted_meta;
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}

is_deeply \%info, { '1_OTU_4' => 1, '2_OTU_12' => 2, '3_OTU_324' => 3 };


# Test prepending, using a specified separator

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity        => $meta1,
   -member_attr          => 'desc',
   -conversion_method    => 'prepend',
   -conversion_separator => ' / ',
), 'Customized prepend';

ok $meta2 = $converter->get_converted_meta;
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}

is_deeply \%info, { 'OTU_4 / 1' => 1, 'OTU_12 / 2' => 2, 'OTU_324 / 3' => 3 };


# Test conversion to invalid member attribute

ok $converter = Bio::Community::Tools::IdConverter->new(
   -metacommunity => $meta1,
   -member_attr  => 'XXXX',
), 'From invalid attribute';

throws_ok { $converter->get_converted_meta } qr/Invalid member attribute/i;


done_testing();

exit;
