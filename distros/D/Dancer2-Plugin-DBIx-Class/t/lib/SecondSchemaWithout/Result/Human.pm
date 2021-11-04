package SecondSchemaWithout::Result::Human;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('human');
__PACKAGE__->add_columns(qw(id name birthdate));
__PACKAGE__->set_primary_key('id');

1;
