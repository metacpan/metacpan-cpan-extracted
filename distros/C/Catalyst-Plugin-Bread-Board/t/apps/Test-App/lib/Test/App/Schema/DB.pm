package Test::App::Schema::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw[
    Artist
]);

1;

