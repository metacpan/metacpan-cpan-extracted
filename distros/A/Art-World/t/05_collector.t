use Test::More tests => 14;
use Art::World;
use Faker;

my $f = Faker->new;

use_ok 'Art::World::Collector';

my $munnies = 9999;

my $collector1 = Art::World
  ->new_collector(
    name => $f->person_name,
    money => $munnies,
    id => 3
  );

my $collector2 = Art::World
  ->new_collector(
    name => $f->person_name,
    money => $munnies + 1000,
    id => 4
  );


my $homogenic_artist = Art::World->new_artist(
  name => $f->person_name,
  collectors => [ $collector1, $collector2 ]
);

ok $homogenic_artist->is_homogenic, 'Artist status is homogenic since it has collectors';

my $artwork = Art::World->new_artwork(
    creator => [ $homogenic_artist ]  ,
    value => 10_000,
    owner => [ $collector1, $collector2 ]
  );

my $artwork2 = Art::World->new_artwork(
  creator => [ $homogenic_artist ]  ,
  value => 12_000,
  owner => [ $collector2 ]
);


$munnies = 100_000;

my $collector = Art::World
  ->new_collector(
    name => Faker->new->person_name,
    money => $munnies,
    id => 3
  );

isa_ok $collector, 'Art::World::Agent';
can_ok $collector, qw/acquire participate sale/;

ok $collector->money, 'Collector got a money attr';
ok $collector->collection, 'Collector got a collection attr';

is $collector->money, $munnies, 'Collector money value is valid';

ok $collector->does('Art::World::Buyer'), 'Collector does role Buyer';

ok $collector->acquire( $artwork ),
  'Collector added an artwork to their collection';
ok $collector->acquire( $artwork2 ),
  'Collector added a second artwork to their collection';

is $collector->money, 78_000; 'Check collector\s fortune';

foreach (@{ $collector->collection })  {
  isa_ok $_, 'Art::World::Artwork';
}


is scalar @{ $collector->collection }, 2, 'Checked length of collector\'s collection';

done_testing();
