package TestAppCDBI::Model::CDBI;

use base 'Class::DBI';
use FindBin;

my $db_file = "$FindBin::Bin/tmp/session.db";
__PACKAGE__->connection("dbi:SQLite:$db_file");

1;
