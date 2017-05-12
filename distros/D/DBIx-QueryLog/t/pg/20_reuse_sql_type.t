use strict;
use warnings;
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI qw(:sql_types);

my $pg = t::Util->setup_postgresql
    or plan skip_all => $Test::PostgreSQL::errstr || 'failed setup_postgresql';

my $dbh = DBI->connect(
    $pg->dsn(dbname => 'test'), '', '',
    {
        AutoCommit => 1,
        RaiseError => 1,
    },
) or die $DBI::errstr;

DBIx::QueryLog->begin;

my @res = split "\n", capture {
    my $sth = $dbh->prepare('SELECT * FROM user WHERE User = ? OR User = ?');
    $sth->bind_param(1, 1, { TYPE => SQL_CHAR });
    $sth->bind_param(2, 'root', SQL_CHAR);
    $sth->execute;
    $sth->execute(3, 'dummy');
};

like $res[0], qr/SELECT \* FROM user WHERE User = '1' OR User = 'root'/;
like $res[1], qr/SELECT \* FROM user WHERE User = '3' OR User = 'dummy'/;

done_testing;
