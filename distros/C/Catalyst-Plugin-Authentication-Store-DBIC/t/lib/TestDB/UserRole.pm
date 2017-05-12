package TestDB::UserRole;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table( 'user_role' );
__PACKAGE__->add_columns( qw/id user role/ );
__PACKAGE__->set_primary_key( qw/id/ );

1;
