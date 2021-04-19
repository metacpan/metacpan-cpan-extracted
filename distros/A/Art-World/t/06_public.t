use Test::More;
use Art::World;
use Art::World::Util;



my $public = Art::World
  ->new_public(
    name => Art::World::Util->new_person->fake_name,
    id => 3
  );

isa_ok $public, 'Art::World::Public';
isa_ok $public, 'Art::World::Agent';
can_ok $public, 'visit';
can_ok $public, 'participate';

done_testing;
