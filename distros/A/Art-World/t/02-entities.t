use v5.32;
use Test::More;
use Art::Wildlife;
use Art;
use Data::Printer;
use Faker;

my $f = Faker->new;

# use-ok 'Art::World';
# my $aw = Art::World.new;
# isa-ok $aw, "Art::World";

use_ok 'Art::Wildlife::Agent';
use_ok 'Art::Wildlife::Artist';
use_ok 'Art::Wildlife::Collector';
# use-ok 'Art::Entities::Artwork';

my $agent = Art::Wildlife->new_agent( name => $f->person_name, id => 1 );

# does-ok $agent, Art::Behavior::Crudable;

my $artist_name = $f->person_first_name . ' ' . $f->person_last_name;

my $artist = Art::Wildlife->new_artist( name => $artist_name, id => 2 );

isa_ok $artist, 'Art::Wildlife::Agent';
can_ok $artist, 'create';
can_ok $artist, 'has_collectors';
can_ok $artist, 'have_idea';

is $artist->name, $artist_name, 'The artist got a name attr';

# can-ok $artist, 'save';
# does-ok $artist, Art::Behavior::Crudable;

# my $artwork = Art::Entities::Artwork.new;
# does-ok $artwork, Art::Behavior::Collectionable;
# can-ok $artwork, 'belong-to';
# can-ok $artwork, 'for-sale';

my $munnies= 100;

my $collector = Art::Wildlife
        ->new_collector(
            name => Faker->new->person_name,
            money => $munnies,
            id => 3
           );

isa_ok $collector, 'Art::Wildlife::Agent';
can_ok $collector, 'acquire';

ok $collector->money, 'Collector got a money attr';
ok $collector->collection, 'Collector got a collection attr';

is $collector->money, $munnies, 'Collector money value is valid';

ok $collector->does('Art::Wildlife::Buyer'), 'Collector does role Buyer';

my $art_abstraction = Art->new_abstract;
ok $art_abstraction->does('Art::Abstractions'), 'Art does role Abstractions';

done_testing();
