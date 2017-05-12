package # hide from PAUSE
    Schema::Location;

use strict;
use warnings;

use lib './t/lib';

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw[
    PK::Auto
    Core
    FormTools
]);

__PACKAGE__->table('locations');
__PACKAGE__->add_columns(qw[
    id
    name
]);
__PACKAGE__->set_primary_key('id');

1;
