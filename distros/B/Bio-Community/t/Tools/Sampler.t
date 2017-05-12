use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::Sampler
);


my ($member1, $member2, $member3, $even_comm, $uneven_comm, $sampler, $rand_member,
    $rand_comm, $rand_comm2, $count);
my %descs;

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );


SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::Randist');


# Bare object

ok $sampler = Bio::Community::Tools::Sampler->new(), 'Bare object';
isa_ok $sampler, 'Bio::Community::Tools::Sampler';
throws_ok { $sampler->get_rand_member } qr/EXCEPTION.*community/msi;


# Even community

$even_comm = Bio::Community->new();
$even_comm->add_member( $member1, 1);
$even_comm->add_member( $member2, 1);
$even_comm->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $even_comm,
   -seed      => 12537409,
), 'Even community';
isa_ok $sampler, 'Bio::Community::Tools::Sampler';

%descs = ();
$count = 999;
for (1 .. $count) {
   ok $rand_member = $sampler->get_rand_member;
   isa_ok $rand_member, 'Bio::Community::Member';
   $descs{$rand_member->desc}++;
}

cmp_ok( $descs{'A'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'A'}, '<=', 366 );
cmp_ok( $descs{'B'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'B'}, '<=', 366 );
cmp_ok( $descs{'C'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'C'}, '<=', 366 );


# Uneven community

$uneven_comm = Bio::Community->new();
$uneven_comm->add_member( $member1, 100);
$uneven_comm->add_member( $member2, 10);
$uneven_comm->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $uneven_comm,
   -seed      => 72904653,
), 'Uneven community';

%descs = ();
$count = 1000;
for (1 .. $count) {
   ok $rand_member = $sampler->get_rand_member;
   isa_ok $rand_member, 'Bio::Community::Member';
   $descs{$rand_member->desc}++;
}

cmp_ok( $descs{'A'}, '>=',  500 ); # should be 1000
cmp_ok( $descs{'A'}, '<=', 1500 );
cmp_ok( $descs{'B'}, '>=',   50 ); # should be  100
cmp_ok( $descs{'B'}, '<=',  150 );
cmp_ok( $descs{'C'}, '>=',    4 ); # should be   10
cmp_ok( $descs{'C'}, '<=',   16 );

ok $rand_comm = $sampler->get_rand_community($count);

isa_ok $rand_comm, 'Bio::Community';
cmp_ok( $rand_comm->get_count($member1), '>=',  500 ); # should be 1000
cmp_ok( $rand_comm->get_count($member1), '<=', 1500 );
cmp_ok( $rand_comm->get_count($member2), '>=',   50 ); # should be  100
cmp_ok( $rand_comm->get_count($member2), '<=',  150 );
cmp_ok( $rand_comm->get_count($member3), '>=',    4 ); # should be   10
cmp_ok( $rand_comm->get_count($member3), '<=',   16 );


# Re-using same object

ok $sampler->community($even_comm), 'Re-use same Sampler';

%descs = ();
$count = 999;
for (1 .. $count) {
   ok $rand_member = $sampler->get_rand_member;
   isa_ok $rand_member, 'Bio::Community::Member';
   $descs{$rand_member->desc}++;
}

cmp_ok( $descs{'A'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'A'}, '<=', 366 );
cmp_ok( $descs{'B'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'B'}, '<=', 366 );
cmp_ok( $descs{'C'}, '>=', 300 ); # should be 333
cmp_ok( $descs{'C'}, '<=', 366 );


# Zero members

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $uneven_comm,
   -seed      => 72904653,
), 'Zero members';

$count = 0;
ok $rand_comm = $sampler->get_rand_community($count);
is scalar @{$rand_comm->get_all_members}, 0;


# Operate at max count (without replacement)

$uneven_comm = Bio::Community->new( );
for my $i (1..1000) {
   $uneven_comm->add_member( Bio::Community::Member->new(), $i*10);
}
$uneven_comm->add_member( Bio::Community::Member->new(), 1);

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $uneven_comm,
), 'Max count';
ok $rand_comm = $sampler->get_rand_community($uneven_comm->get_members_count);

TODO: {
   local $TODO = 'Need to implement Sampler without replacement';
   is $rand_comm->get_richness, $uneven_comm->get_richness;
}


# Operate close to max count (without replacement)

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $uneven_comm,
   -seed      => 46285024,
), 'Close to max count';
ok $rand_comm = $sampler->get_rand_community($uneven_comm->get_members_count);

ok $sampler = Bio::Community::Tools::Sampler->new(
   -community => $uneven_comm,
   -seed      => 314235333,
);
ok $rand_comm2 = $sampler->get_rand_community($uneven_comm->get_members_count - 1);

is $rand_comm2->get_richness, $rand_comm->get_richness;


### TODO: same with replacement



}

done_testing();

exit;
