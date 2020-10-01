use v5.16;
use Test::More;
use Art::World;
use Faker;

my $f = Faker->new;

use_ok 'Art::World::Artist';

my $artist_name = $f->person_first_name . ' ' . $f->person_last_name;
my $artist = Art::World->new_artist(
  name => $artist_name, id => 1
);

isa_ok $artist, 'Art::World::Agent';
can_ok $artist, 'create';
can_ok $artist, 'participate';
can_ok $artist, 'has_collectors';
can_ok $artist, 'have_idea';

ok $artist->id, 'Artist got an id attr';
is $artist->name, $artist_name, 'Artist got a name attr';
ok $artist->is_underground, 'Artist status not homogenic yet';

# does-ok $artist, Art::Behavior::Crudable;
# Provided by crudable
# can-ok $artist, 'save';

done_testing();
