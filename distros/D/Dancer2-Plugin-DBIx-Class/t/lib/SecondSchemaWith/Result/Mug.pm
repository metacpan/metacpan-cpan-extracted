package SecondSchemaWith::Result::Mug;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('mug');
__PACKAGE__->add_columns(qw(id color size_in_oz beverage));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'beverage' => 'SecondSchemaWith::Result::Beverage',
   'beverage' );

1;
