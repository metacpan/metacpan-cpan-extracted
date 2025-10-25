#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

ok $dbh->do('CREATE TABLE tbl1 (u UNION(num INTEGER, str VARCHAR))') == 0, 'Create table';
ok $dbh->do("INSERT INTO tbl1 VALUES (1), ('two'), ('three')") == 3,       'Insert values';

my $rows = $dbh->selectall_arrayref('SELECT * FROM tbl1');

TODO: {

    local $TODO = "$^O doesn't work yet. :(" if $^O eq 'darwin';

    is $rows->[0]->[0], 1;
    is $rows->[1]->[0], 'two';
    is $rows->[2]->[0], 'three';

}

ok !$dbh->do('INSERT INTO tbl1 VALUES (true), (false)'), 'Fail insert bool data';

ok $dbh->errstr, 'Failed to insert bool data';

done_testing;
