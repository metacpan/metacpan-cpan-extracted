package TestAppDBICSchema::Schema;

use strict;
use base 'DBIx::Class::Schema';
use FindBin;

my $db_file = "$FindBin::Bin/tmp/session.db";
__PACKAGE__->connection("dbi:SQLite:$db_file");

__PACKAGE__->load_namespaces;

1;
