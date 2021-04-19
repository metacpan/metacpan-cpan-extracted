use Test::More;
use Art::World;
use Art::World::Util;

my $p = Art::World::Util->new_person;

my $gallerist = $p->fake_name;

my $gallery = Art::World->new_gallery(
  exhibition => [ 1, 2 ],
  owner => $gallerist,
  money => 10_000_000,
  name => 'Richer Gallery',
  space => 1000 );

ok $gallery->does('Art::World::Exhibit'), 'Gallery does role Exhibit';
ok $gallery->exhibition, 'Gallery got an exhibition attribute';
ok $gallery->owner, 'Gallery got an owner';

#ok $gallery->does('Art::Collectionable');
can_ok $gallery, 'acquire';
#can_ok $gallery, 'serve';
can_ok $gallery, 'pay';

done_testing;
