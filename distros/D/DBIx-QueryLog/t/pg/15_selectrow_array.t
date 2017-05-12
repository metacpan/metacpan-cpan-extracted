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

for my $method (qw/selectrow_array selectrow_arrayref selectall_arrayref/) {
    subtest $method => sub {
        my $res = capture {
            $dbh->$method(
                'SELECT * FROM user WHERE User = ?', undef, 'root'
            );
        };

        like $res, qr/SELECT \* FROM user WHERE User = 'root'/;
        done_testing;
    };
}

done_testing;
