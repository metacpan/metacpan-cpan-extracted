use Test::More tests => 6;
use Art::World;
use feature qw( postderef );

my $aw = Art::World->new_playground;
ok $aw, 'The world is created';

my $art_concept = Art::World->new_idea(
  discourse => 'I have idead. Too many ideas. I store them in a file.',
  file => [],
  idea => 'idea',
  process => [],
  project => 'project',
  time => 5,
);


ok $art_concept->does('Art::World::Abstraction'), 'Art does role Abstraction';
is $art_concept->idea, 'idea';
is $art_concept->file->[0], 'idea', 'Idea got correctly added to the file';

$art_concept->idea('demotivated');

is $art_concept->file->[1], 'demotivated', 'Second idea correctly got added to the file';
ok scalar $art_concept->file->@* eq 2, 'We have a couple of ideas in the file';

done_testing;
