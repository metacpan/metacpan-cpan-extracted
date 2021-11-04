package SecondSchemaWith::Result::Beverage;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('beverage');
__PACKAGE__->add_columns(qw(id type));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( 'mugs' => 'SecondSchemaWith::Result::Mug',
   'beverage' );

1;
