#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

ok $dbh->do('CREATE TABLE tbl1 (u UNION(num INTEGER, str VARCHAR))') == 0, 'Create union table';
ok $dbh->do("INSERT INTO tbl1 VALUES (1), ('two'), ('three')") == 3,       'Insert values';

my $sth = $dbh->prepare('SELECT * FROM tbl1');
$sth->execute;

my $row = $sth->fetchall_arrayref;

TODO: {

    local $TODO = "$^O doesn't work yet. :(" if $^O eq 'darwin';

    is $row->[0]->[0], 1;
    is $row->[1]->[0], 'two';
    is $row->[2]->[0], 'three';

}

ok !$dbh->do('INSERT INTO tbl1 VALUES (true), (false)'), 'Fail insert bool data';

ok $dbh->errstr, 'Failed to insert bool data';

done_testing;
