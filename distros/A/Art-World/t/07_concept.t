use Test::More;
use Art::World;

my $concept = Art::World->new_abstraction(
    idea => 'Strange idea',
    process => 'Step 1',
    file => 'Database reference',
  );

is $concept->idea, 'Strange idea', 'Concept got the right attribute';
ok $concept->does('Art::World::Concept'), 'Abstraction does role Concept';

done_testing;
