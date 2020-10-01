use v5.16;
use Test::More;
use Faker;
use Art::World;

my $f = Faker->new;

my $public = Art::World
  ->new_public(
    name => Faker->new->person_name,
    id => 3
  );

isa_ok $public, 'Art::World::Public';
isa_ok $public, 'Art::World::Agent';
can_ok $public, 'visit';
can_ok $public, 'participate';

done_testing();
