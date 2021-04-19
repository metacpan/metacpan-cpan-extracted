use Test::More;
use Art::World;
use Art::World::Util;

use Faker;

my $f = Faker->new;

my $place = Art::World->new_place( location => $f->address_city_name, name => 'A Famous Place' );
my $chat = $f->lorem_sentence;
my $t = Art::World::Util->new_time( source => '2020-02-16T08:18:43' );

my $opening_event = Art::World->new_opening(
  place     => $place,
  datetime => $t->datetime,
  name => 'Come See Our Stuff',
  smalltalk => $chat,
  treat     => [ 'Red wine', 'White wine', 'Peanuts', 'Candies' ],
  # missing participant
 );

can_ok $opening_event, 'serve';

diag $opening_event->smalltalk;
diag $opening_event->datetime;
diag $opening_event->place->location;
diag join ', ',  $opening_event->serve;

isa_ok $opening_event, 'Art::World::Art';
ok $opening_event->does( 'Art::World::Event' );
ok $opening_event->does( 'Art::World::Event' );

isa_ok $opening_event->datetime, 'Time::Moment';
isa_ok $opening_event->place, 'Art::World::Place';

# TODO Must test the Invitation role

done_testing;
