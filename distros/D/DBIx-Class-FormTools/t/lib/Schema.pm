package # hide from PAUSE
    Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw[
    Film
    Actor
    Location
    Role
    Director
]);

1;
