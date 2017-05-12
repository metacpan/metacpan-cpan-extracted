package TestAppDBIC::Model::DBIC;

use base 'DBIx::Class';
use FindBin;

__PACKAGE__->load_components(qw/Core DB/);

my $db_file = "$FindBin::Bin/tmp/session.db";
__PACKAGE__->connection("dbi:SQLite:$db_file");

1;
