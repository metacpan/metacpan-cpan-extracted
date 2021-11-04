package FirstSchemaWith::Result::Session;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('session');
__PACKAGE__->add_columns(qw(id created_at session_key));
__PACKAGE__->set_primary_key('id');

1;
