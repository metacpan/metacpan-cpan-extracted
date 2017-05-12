use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use Test::mysqld;
use t::Util;
use DBIx::QueryLog ();
use DBI qw(:sql_types);

my $mysqld = t::Util->setup_mysqld
    or plan skip_all => $Test::mysqld::errstr || 'failed setup_mysqld';

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'mysql'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

DBIx::QueryLog->begin;

my $res = capture {
    my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ? OR User = ? OR User = ? OR User = ?');
    $sth->bind_param(1, 1, SQL_INTEGER);
    $sth->bind_param(2, 'root', SQL_CHAR);
    $sth->bind_param(3, 'xaicron');
    $sth->bind_param(4, 2, { TYPE => SQL_INTEGER });
    $sth->execute;
};

like $res, qr/SELECT \* FROM user WHERE User = 1 OR User = 'root' OR User = 'xaicron' OR User = 2/;

done_testing;
