use Test::More;
use Art::World;
use Art::World::Util;

my $artist_name = Art::World::Util->new_person->fake_name;

my $artist = Art::World->new_artist(
  id => 1,
  name => $artist_name,
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

done_testing;
