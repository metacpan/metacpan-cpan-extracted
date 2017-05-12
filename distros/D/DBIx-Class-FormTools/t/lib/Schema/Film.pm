package # hide from PAUSE
    Schema::Film;

use strict;
use warnings;

use lib './t/lib';

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw[
    PK::Auto
    Core
    FormTools
]);

__PACKAGE__->table('films');
__PACKAGE__->add_columns(qw[
    id
    title
    length
    comment
    location_id
    director_id
]);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('director_id' => 'Schema::Director');

__PACKAGE__->belongs_to(location => 'Schema::Location', 'location_id');
__PACKAGE__->has_many(roles => 'Schema::Role', 'film_id');


1;
