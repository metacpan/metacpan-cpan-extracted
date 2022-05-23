package FirstSchemaWith::Result::Human;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('human');
__PACKAGE__->add_columns(qw(id name));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many('cars' => 'FirstSchemaWith::Result::Car', 'human');
1;
