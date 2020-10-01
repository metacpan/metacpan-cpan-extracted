use v5.16;
use Test::More;
use Art::World;
use Faker;

my $f = Faker->new;

use_ok 'Art::World::Collector';

my $collectors = [ $f->person_name, $f->person_name ];

my $homogenic_artist = Art::World->new_artist(
    name => $f->person_name,
    collectors => $collectors
   );

ok $homogenic_artist->is_homogenic, 'Artist status is homogenic since it has collectors';

my $munnies= 100;

my $collector = Art::World
        ->new_collector(
            name => Faker->new->person_name,
            money => $munnies,
            id => 3
           );

isa_ok $collector, 'Art::World::Agent';
can_ok $collector, 'acquire';
can_ok $collector, 'participate';

ok $collector->money, 'Collector got a money attr';
ok $collector->collection, 'Collector got a collection attr';

is $collector->money, $munnies, 'Collector money value is valid';

ok $collector->does('Art::World::Buyer'), 'Collector does role Buyer';

done_testing();
