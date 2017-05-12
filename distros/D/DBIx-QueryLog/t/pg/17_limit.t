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

{
    my $res = capture {
        $dbh->selectrow_hashref(
            'SELECT * FROM user WHERE User = ? LIMIT ? OFFSET ?',
            undef,
            'root', 1, 0,
        );
    };

    like $res, qr/\QSELECT * FROM user WHERE User = 'root' LIMIT 1 OFFSET 0\E/;
}

{
    my $res = capture {
        $dbh->selectrow_arrayref(
            'SELECT * FROM (SELECT * FROM user WHERE User = ? LIMIT ?) AS "user" WHERE User = ? LIMIT ? OFFSET ?',
            undef,
            'root', 1, 'root', 1, 0,
        );
    };

    like $res, qr/\QSELECT * FROM (SELECT * FROM user WHERE User = 'root' LIMIT 1) AS "user" WHERE User = 'root' LIMIT 1 OFFSET 0\E/;
}

done_testing;
