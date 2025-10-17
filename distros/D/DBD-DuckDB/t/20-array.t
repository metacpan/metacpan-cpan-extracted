#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

ok $dbh->do(q{CREATE TABLE array_table (id INTEGER, arr INTEGER[3])}) == 0, 'Create array table';

ok $dbh->do(q{INSERT INTO array_table VALUES (10, [1, 2, 3]), (20, [4, 5, 6])}) == 2, 'Insert data';

SCOPE: {

    my $sth = $dbh->prepare('SELECT * FROM array_table WHERE id = ?');
    $sth->execute(10);

    my $row = $sth->fetchrow_hashref;
    is_deeply($row->{arr}, [1, 2, 3]);

}

SCOPE: {

    my $sth = $dbh->prepare('SELECT * FROM array_table WHERE id = $1');
    $sth->execute(20);

    my $row = $sth->fetchrow_hashref;
    is_deeply($row->{arr}, [4, 5, 6]);

}

done_testing;
