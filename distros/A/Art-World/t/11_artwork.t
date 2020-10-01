use v5.16;
use Test::More;
use Art::World;
use Data::Printer;
use Faker;
use List::Util qw/any/;

my $f = Faker->new;

use_ok 'Art::World::Artwork';

my $artist_name = $f->person_first_name . ' ' . $f->person_last_name;
my $artist = Art::World->new_artist(
  name => $artist_name, id => 1
);

my $collectors = [ $f->person_name, $f->person_name ];

my $homogenic_artist = Art::World->new_artist(
  name => $f->person_name,
  collectors => $collectors
);


my $artwork = Art::World->new_artwork(
  creator => [ $artist, $homogenic_artist ]  ,
  value => 10_000,
  owner => $f->person_name );

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
