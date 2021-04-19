use Test::More;
use Art::World;
use Art::World::Util;

my $agent = Art::World->new_agent(
  name => Art::World::Util->new_person->fake_name );
can_ok $agent, qw/participate networking/;

my $artist_1 = Art::World->new_artist(
  id => 1, name => Art::World::Util->new_person->fake_name );
my $artist_2 = Art::World->new_artist(
  id => 2, name => Art::World::Util->new_person->fake_name );
my $curator_1 = Art::World->new_curator(
  id => 3, reputation => 100, name => Art::World::Util->new_person->fake_name );

my $peoples = [ $artist_1, $artist_2, $curator_1 ];

can_ok $curator_1, 'networking';

is $curator_1->reputation, 100, 'Initial Curator reputation';
is $artist_1->reputation, 0,  'Initial Artist reputation';
is $artist_2->reputation, 0,  'Another initial Artist reputation';

$curator_1->networking( $peoples );

is $curator_1->reputation, 110, 'Curator reputation increased';
is $artist_1->reputation, 60, 'Artist reputation increased';
is $artist_2->reputation, 60, 'Artist reputation increased';

$curator_1->bump_fame(-101);

is $curator_1->reputation, 9, 'Basic calculation on the fame';

$curator_1->networking( $peoples );

is $curator_1->reputation, 15, 'Curator reputation increased';
is $artist_1->reputation, 396, 'Artist reputation increased';
is $artist_2->reputation, 396, 'Artist reputation increased';

$curator_1->bump_fame;

is $curator_1->reputation, 16, 'Default bump';

done_testing;
