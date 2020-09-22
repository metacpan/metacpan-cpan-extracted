use v5.16;
use Test::More;
use Art::Wildlife;
use Faker;

my $f = Faker->new;

use_ok 'Art::Wildlife::Collector';
my $collectors = [ $f->person_name, $f->person_name ];

my $homogenic_artist = Art::Wildlife->new_artist(
    name => $f->person_name,
    collectors => $collectors
   );

ok $homogenic_artist->is_homogenic, 'Artist status is homogenic since it has collectors';

my $munnies= 100;

my $collector = Art::Wildlife
        ->new_collector(
            name => Faker->new->person_name,
            money => $munnies,
            id => 3
           );

isa_ok $collector, 'Art::Wildlife::Agent';
can_ok $collector, 'acquire';
can_ok $collector, 'participate';

ok $collector->money, 'Collector got a money attr';
ok $collector->collection, 'Collector got a collection attr';

is $collector->money, $munnies, 'Collector money value is valid';

ok $collector->does('Art::Wildlife::Buyer'), 'Collector does role Buyer';

done_testing();
