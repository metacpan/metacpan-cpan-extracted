use Test::More;
use Art::World;

my $concept = Art::World->new_idea(
    idea => 'Strange idea',
    process => [],
    file => [],
  );

is $concept->idea, 'Strange idea', 'Concept got the right attribute';
is $concept->file->[0], 'Strange idea', 'Concept got the right attribute';
ok $concept->does('Art::World::Abstraction'), 'Concept does role Abstraction';

done_testing;
