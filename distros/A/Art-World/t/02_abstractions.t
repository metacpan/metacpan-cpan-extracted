use v5.16;
use Test::More;
use Art::World;
use Faker;

my $aw = Art::World->new_playground;
ok $aw, 'The world is created';

my $art_concept = Art::World->new_abstraction(
  idea => 'idea',
  process => 'process',
  file => 'file',
  discourse => 'discourse',
  time => 'time',
  project => 'project'
);

ok $art_concept->does('Art::World::Concept'), 'Art does role Concept';

done_testing;
