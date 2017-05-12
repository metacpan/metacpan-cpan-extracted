package # hide from PAUSE
    Schema::Role;

use strict;
use warnings;

use lib './t/lib';

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw[
    PK::Auto
    Core
    FormTools
]);

__PACKAGE__->table('roles');
__PACKAGE__->add_columns(qw[
    film_id
    actor_id
    charater
]);
__PACKAGE__->set_primary_key(qw[
    film_id
    actor_id
]);

__PACKAGE__->belongs_to(film_id  => 'Schema::Film');
__PACKAGE__->belongs_to(actor_id => 'Schema::Actor');

1;
