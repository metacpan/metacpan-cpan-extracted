use Test::More;
use Art::World;
use Art::World::Util;

SKIP: {
    skip 'The Place is not yet implemented', 1;

my $place = Art::World->new_place( space => 4000 );

# artist, collector, critic, curator, director, public

my @agents = map {
  Art::World->new_artist(
    id => $_,
    name => Art::World::Util->new_person->fake_name
  )} (1..100);

=head1

ok $gallery->does('Art::World::Exhibit'), 'Gallery does role Exhibit';
ok $gallery->exhibition, 'Gallery got an exhibition attribute';
ok $gallery->owner, 'Gallery got an owner';

$gallery->serve;

#ok $gallery->does('Art::Collectionable');
can_ok $gallery, 'acquire';
can_ok $gallery, 'serve';
can_ok $gallery, 'sale';

Also, we should test that during an event, the Artworks, who got a size, can
enter the Place

=cut

}

done_testing;
