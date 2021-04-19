use Test::More;
use Art::World;
use Art::World::Util;

use constant {
  INITIAL_ARTIST_REPUTATION => 1,
  INITIAL_CURATOR_REPUTATION => 100,
  INITIAL_MANAGER_REPUTATION => 200,
};

my $manager = Art::World->new_director(
  id => 111,
  reputation => INITIAL_MANAGER_REPUTATION,
  name => Art::World::Util->new_person->fake_name );
my $artist_1 = Art::World->new_artist(
  id => 2,
  reputation => INITIAL_ARTIST_REPUTATION,
  name => Art::World::Util->new_person->fake_name );
my $curator_1 = Art::World->new_curator(
  id => 3,
  reputation => INITIAL_CURATOR_REPUTATION,
  name => Art::World::Util->new_person->fake_name );

my $peoples = [ $manager, $artist_1, $curator_1 ];

$manager->networking( $peoples );

is $manager->reputation, 220, "Check that the manager reputation wasn't increased with the super-manager-bump after networking";
is $artist_1->reputation, 126, "Artist acquired a serious reputation thanks to the influence of the institution manager";
is $curator_1->reputation, 720, "Curator acquired a serious reputation thanks to the influence of the institution manager";

my $artist_2 = Art::World->new_artist(
  id => 4,
  reputation => INITIAL_ARTIST_REPUTATION,
  name => Art::World::Util->new_person->fake_name );

my $bumped_reputation = $artist_2->bump_fame( $artist_1->reputation );
is $bumped_reputation, 127, "The artist got it's reputation bumped by another artist";
my $networked_reputation = $manager->influence( $artist_2->reputation );
is $networked_reputation, 635, "The manager can influence() an artist reputation";

done_testing;
