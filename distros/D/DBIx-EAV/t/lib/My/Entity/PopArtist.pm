package My::Entity::PopArtist;

use Moo;
BEGIN { extends 'My::Entity::Artist' }

__PACKAGE__->attribute('pop_name');

1;
