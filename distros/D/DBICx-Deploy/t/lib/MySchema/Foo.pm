package MySchema::Foo;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('foo');
__PACKAGE__->add_columns(
  'id',
  { data_type => 'INTEGER', is_nullable => 0, size => undef, 
    is_auto_increment => 1, },
  'value',
  { data_type => 'TEXT', is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key('id');

1;
