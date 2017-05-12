package My::Entity::CD;
use Moo;
BEGIN { extends 'DBIx::EAV::Entity' }

__PACKAGE__->attribute('name');

1;
