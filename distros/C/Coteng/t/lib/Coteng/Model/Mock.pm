package Coteng::Model::Mock;
use strict;
use warnings;

use Class::Accessor::Lite::Lazy (
    rw => [qw(
        id
        name
        delete_fg
    )],
    new => 1,
);

1;
