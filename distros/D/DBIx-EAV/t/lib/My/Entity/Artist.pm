package My::Entity::Artist;

use Moo;
BEGIN { extends 'DBIx::EAV::Entity' }

__PACKAGE__->attribute('name');
__PACKAGE__->attribute({ name => 'birth_date', type => 'datetime' });
__PACKAGE__->attribute('description:text');
__PACKAGE__->attribute('rating:int');
__PACKAGE__->many_to_many('CD');


sub uc_name {
    uc shift->get('name');
}

1;
