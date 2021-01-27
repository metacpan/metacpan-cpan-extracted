use Test::More tests => 11;
use Art::World;
use Faker;
use List::Util qw/any/;

my $f = Faker->new;

use_ok 'Art::World::Artwork';

my $artist_name = $f->person_first_name . ' ' . $f->person_last_name;
my $artist = Art::World->new_artist(
  name => $artist_name, id => 1
);

my $munnies= 100;

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

my $artwork = Art::World->new_artwork(
  creator => [ $artist, $homogenic_artist ]  ,
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

can_ok $artwork, 'belongs_to';
can_ok $artwork, 'is_for_sale';
can_ok $artwork, 'is_sold';

my $bool = any { $_ eq $artist_name } map { $_->name } @{ $artwork->creator };
ok $bool, 'One of the artwork creator is ' . $artist_name;


done_testing();
