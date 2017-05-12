use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', undef, undef);

my $ret = $dbh->do('INSERT INTO my_table VALUES (?)', undef, 1);
is $ret, '0E0', 'do';

my @row = $dbh->selectrow_array('SELECT * FROM my_table');
is @row, 0, 'selectrow_array';

for my $method (qw/selectrow_arrayref selectrow_hashref/) {
    my $row = $dbh->$method('SELECT * FROM my_table');
    is $row, undef, $method;
}

my $rows;
$rows = $dbh->selectcol_arrayref('SELECT * FROM my_table', {});
is_deeply $rows, [], 'selectcol_arrayref';

$rows = $dbh->selectall_arrayref('SELECT * FROM my_table', {});
is_deeply $rows, [], 'selectall_arrayref (slice:ARRAY)';

$rows = $dbh->selectall_arrayref('SELECT * FROM my_table', { Slice => {} });
is_deeply $rows, [], 'selectall_arrayref (slice:HASH)';

$rows = $dbh->selectall_arrayref('SELECT * FROM my_table', { Slice => \{ 1 => 'id' } });
is_deeply $rows, [], 'selectall_arrayref (slice:REF+HASH)';

$rows = $dbh->selectall_hashref('SELECT * FROM my_table', 'id');
is_deeply $rows, {}, 'selectall_hashref';

done_testing;

