use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

my $res = capture {
    $dbh->do(<< 'SQL', undef, 'foo');
SELECT * FROM
    sqlite_master
WHERE
    name = ?
SQL
};

like $res, qr/SELECT \* FROM\s+sqlite_master\s+WHERE\s+name = 'foo'/, 'SQL';

done_testing;
