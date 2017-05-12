#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use DBX::Simple;

unlink 'db.sqlt';
my $dbh = DBX::Simple->open;
$dbh->do ("create table test (id integer, label)");
is ($dbh->insert ("insert into test (id, label) values (?, ?)", 10, 'test'), 1);
is ($dbh->insert ("insert into test (id, label) values (?, ?)", 20, 'foo'), 2);

is ($dbh->get ("select label from test where id=?", 20), 'foo');
my @rows = $dbh->select ("select * from test");
is (scalar @rows, 2);
is ($rows[0]->[1], 'test');

is ($dbh->do ("delete from test where id=?", 10), 1);
my $rows = $dbh->select ("select * from test");
is (scalar @$rows, 1);
is ($rows->[0]->[1], 'foo');

my $iter = $dbh->iterate ("select * from test");
my $row = $iter->();
is ($row->[1], 'foo');
$row = $iter->();
is ($row, undef);

done_testing ();

