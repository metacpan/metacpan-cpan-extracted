package MySchema::Result::Kitten;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

__PACKAGE__->table('kitten');

__PACKAGE__->add_columns(
    kitten_id => { data_type => 'integer', is_auto_increment => 1},
    name => { data_type => 'text', is_nullable => 0 },
    cuteness => { data_type => 'int', is_nullable => 0, default_value => 5 },
    fluffiness => { data_type => 'int', is_nullable => 0, default_value => 5 },
);

__PACKAGE__->set_primary_key( 'kitten_id' );


1;

