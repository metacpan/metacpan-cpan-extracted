use Test::More;
use Art::World;
use Art::World::Util;
use lib 't/lib';
use Test::Art::World;

my $artist = Art::World->new_artist(
  name => Art::World::Util->new_person->fake_name, id => 1
);

my $munnies= 100;

my $collector1 = Art::World
   ->new_collector(
     name => Art::World::Util->new_person->fake_name,
     money => $munnies,
     id => 3
   );

my $collector2 = Art::World
  ->new_collector(
    name => Art::World::Util->new_person->fake_name,
    money => $munnies + 1000,
    id => 4
  );

my $homogenic_artist = Art::World->new_artist(
  name => Art::World::Util->new_person->fake_name,
  collectors => [ $collector1, $collector2 ]
);

my $artwork = Art::World->new_artwork(
  creator => [ $artist, $homogenic_artist ],
  title => 'Naked City',
  value => 10_000,
  owner => [ $collector1, $collector2 ]
);

is $artwork->value, 10_000, 'The Artwork got a price';
is $artwork->title, 'Naked City', 'The Artwork got a title';

ok $artwork->does('Art::World::Showable'), 'Artwork does role Showable';
ok $artwork->does('Art::World::Collectionable'), 'Artwork does role Collectionable';
ok $artwork->value, 'Artwork got a value attribute';
ok $artwork->owner, 'Artwork got a value attribute';

can_ok $artwork, 'is_for_sale';
can_ok $artwork, 'is_sold';

my $taw = Test::Art::World->new;

ok $taw->is_artist_creator( $homogenic_artist, $artwork ),
  'One of the artwork creator is ' . $homogenic_artist->name;

my $collector3 = Art::World
   ->new_collector(
     name => Art::World::Util->new_person->fake_name,
     money => $munnies + 2000,
     id => 4
   );

$collector3->acquire( $artwork );

ok $taw->is_artist_creator( $homogenic_artist, $artwork ),
  'One of the artwork creator is ' . $homogenic_artist->name . ' even after it got acquired by a collector';

done_testing;

