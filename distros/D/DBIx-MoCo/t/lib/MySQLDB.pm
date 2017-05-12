package MySQLDB;
use strict;
use warnings;
use base qw(DBIx::MoCo::DataBase);

__PACKAGE__->dsn("dbi:mysql:dbname=mysql");
__PACKAGE__->username('root');

1;
