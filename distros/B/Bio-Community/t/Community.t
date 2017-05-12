use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $community2, $community3, $member1, $member2, $member3, $member4,
   $member5, $iters);
my (%ids, %refs_1, %refs_2, %rel_abs, %abs_abs, %members);
my  @members;


# Bare object

ok $community = Bio::Community->new( -name => 'simple', -use_weights => 0 );

isa_ok $community, 'Bio::Root::RootI';
isa_ok $community, 'Bio::Community';


# Add 3 members to a community

ok $community = Bio::Community->new( -use_weights => 0 ), 'Add members';
is $community->get_members_count, 0;

$member1 = Bio::Community::Member->new( -id => 1, -weights => [3] );
ok $community->add_member( $member1 );
is $community->get_members_count, 1;

$member2 = Bio::Community::Member->new( -id => 2 );
ok $community->add_member( $member2, 23 );
is $community->get_members_count, 24;

$member3 = Bio::Community::Member->new( -id => 3, -weights => [2,7] );
ok $community->add_member( $member3, 4 );
is $community->get_members_count, 28;

is $community->get_count($member2), 23;
is $community->get_count($member3), 4;
is $community->get_count($member1), 1;


# Ranks

is $community->get_rank($member2), 1, 'Ranks';
is $community->get_rank($member3), 2;
is $community->get_rank($member1), 3;

is $community->get_member_by_rank(1)->id, 2;
is $community->get_member_by_rank(2)->id, 3;
is $community->get_member_by_rank(3)->id, 1;
is $community->get_member_by_rank(4), undef;


# Retrieve members

is $community->get_member_by_id(2)->id, 2, 'Get members';
isa_ok $community->get_member_by_id(2), 'Bio::Community::Member';

while (my $member = $community->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
   $refs_1{$member} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];

is $community->get_richness, 3;

while (my $member = $community->next_member) {
   $refs_2{$member} = undef;
}
is_deeply [sort keys %refs_1], [sort keys %refs_2], 'Same objects reference';

%ids = ();
ok @members = @{$community->get_all_members};
for my $member (@members) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];


# Remove a member from the community

is $community->remove_member( $member2, 5 ), 5, 'Remove members';
is $community->get_members_count, 23;
is $community->get_members_abundance, 23;

is $community->remove_member( $member2 ), 18; # remove all of it
is $community->get_members_count, 5;
is $community->get_members_abundance, 5;

is $community->remove_member( $member2 ), 0; # remove already removed member

is $community->get_member_by_id(2), undef;
is $community->get_count($member2), 0;

@members = ();
%ids = ();
ok @members = @{$community->get_all_members};
for my $member (@members) {
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 3];

is $community->get_richness, 2;

is $community->name, 'Unnamed';
ok $community->name('ocean sample 3');
is $community->name, 'ocean sample 3';

is $community->use_weights, 0;

is $community->get_count($member3), 4;
is $community->get_count($member1), 1;
is $community->get_count($member2), 0;

is $community->get_rank($member3), 1;
is $community->get_rank($member1), 2;
is $community->get_rank($member2), undef;

is $community->get_member_by_rank(1)->id, 3;
is $community->get_member_by_rank(2)->id, 1;
is $community->get_member_by_rank(3), undef;

for my $member (@{$community->get_all_members}) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
is_deeply \%rel_abs, { 1 => 20, 3 => 80 };

ok $community->use_weights(1);
is $community->use_weights, 1;

is $community->get_member_by_rank(1)->id, 1;
is $community->get_member_by_rank(2)->id, 3;


# Relative abundance

for my $member (@{$community->get_all_members}) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
delta_ok $rel_abs{1}, 53.846153846154;
delta_ok $rel_abs{3}, 46.1538461538463;


# Absolute abundance

ok $community->set_members_abundance(+1.634e5), 'Absolute abundance';
is $community->get_members_abundance, 1.634e5;

for my $member (@{$community->get_all_members}) {
   $abs_abs{$member->id} = $community->get_abs_ab($member);
}
delta_ok $abs_abs{1}, 87984.6153846157;
delta_ok $abs_abs{3}, 75415.3846153849;


# Named iterators

ok $community = Bio::Community->new(), 'Iterator';
ok $community->add_member($member1);
ok $community->add_member($member2);
ok $community->add_member($member3);

ok $community2 = Bio::Community->new();
ok $community2->add_member($member3);
ok $member4 = Bio::Community::Member->new( -id => 'asdf' );
ok $community2->add_member($member4);

ok $community3 = Bio::Community->new();
ok $community3->add_member( Bio::Community::Member->new( -id => 3) );
ok $member5 = Bio::Community::Member->new();
ok $community3->add_member($member5);

$iters = 0;
while (my $memberA = $community->next_member('iterA')) {
   last if $iters >= 30; # prevent infinite loops
   while (my $memberB = $community->next_member('iterB')) {
      $iters++;
      last if $iters >= 30;
   }
}
is $iters, 9; # 3 members * 3 members


done_testing();

exit;
