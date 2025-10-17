#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

use DBD::DuckDB::Constants qw(:duckdb_types);

my $dbh = connect_ok;

ok $dbh->do('CREATE TABLE people (id INTEGER, name VARCHAR, active BOOLEAN)') == 0, 'Create table';

SCOPE: {

    my $appender = $dbh->x_duckdb_appender('people');

    for (my $i = 1; $i <= 1_000; $i++) {

        $appender->append($i,      DUCKDB_TYPE_INTEGER);
        $appender->append('Larry', DUCKDB_TYPE_VARCHAR);
        $appender->append(\1,      DUCKDB_TYPE_BOOLEAN);

        $appender->end_row or BAIL_OUT($appender->error);

    }

    for (my $i = 1_001; $i <= 2_000; $i++) {
        $appender->append_row(id => $i, name => 'Larry', active => 1);
    }

    $appender->destroy;

    my $sth = $dbh->prepare('SELECT * FROM people');
    $sth->execute;

    my $rows = $sth->fetchall_arrayref;
    is @{$rows}, 2_000;

}

done_testing;
