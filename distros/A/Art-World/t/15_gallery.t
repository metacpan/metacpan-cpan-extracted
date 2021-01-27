use Test::More tests => 7;
use Art::World;
use Faker;

my $f = Faker->new;

use_ok 'Art::World::Gallery';

my $gallerist = $f->person_name;

my $gallery = Art::World->new_gallery(
  space => 1000,
  exhibition => [ 1, 2 ],
  owner => $gallerist,
  money => 10_000_000 );

ok $gallery->does('Art::World::Exhibit'), 'Gallery does role Exhibit';
ok $gallery->exhibition, 'Gallery got an exhibition attribute';
ok $gallery->owner, 'Gallery got an owner';

$gallery->serve;

#ok $gallery->does('Art::Collectionable');
can_ok $gallery, 'acquire';
can_ok $gallery, 'serve';
can_ok $gallery, 'sale';



done_testing();
