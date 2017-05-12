use strict;
use warnings;
use Test::Requires qw(DBD::Pg Test::PostgreSQL);
use Test::More;
use Test::PostgreSQL;
use t::Util;
use DBIx::QueryLog ();
use DBI;

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

my $res = capture {
    $dbh->selectrow_hashref(<< 'SQL', undef, 'root');
SELECT * FROM
    user
WHERE
    User = ?
SQL
};

like $res, qr/SELECT \* FROM\s+user\s+WHERE\s+User = 'root'/ms;

done_testing;
