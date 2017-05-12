package CD::SQLite;
use base qw(Class::DBI::SQLite);
__PACKAGE__->set_db('Main', 'dbi:SQLite:dbname=t/db', '', '', { RaiseError => 1, AutoCommit => 1 });

END { unlink "t/db" }

1;
