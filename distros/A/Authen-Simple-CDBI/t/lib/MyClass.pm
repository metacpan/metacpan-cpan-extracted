package MyClass;

use strict;
use warnings;
use base 'Class::DBI';

__PACKAGE__->table('users');
__PACKAGE__->columns( Primary   => qw[username] );
__PACKAGE__->columns( Essential => qw[password] );
__PACKAGE__->connection('dbi:SQLite:dbname=t/var/database.db');

1;
