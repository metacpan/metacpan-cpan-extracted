package DCAUTSchema::Result::DCAUT;

use base qw/DBIx::Class::Core/;
 
__PACKAGE__->load_components( qw( AlwaysUpdate ) );
__PACKAGE__->table('dcaut');
__PACKAGE__->add_columns(qw/id/);
__PACKAGE__->set_primary_key('id');

1;