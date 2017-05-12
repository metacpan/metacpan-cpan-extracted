use DBIPR;
use Test::More tests=>2;
use Test::DatabaseRow;

$Test::DatabaseRow::dbh = DBI->connect(qq(dbi:Oracle:), qq(scott/tiger));

trunc;
row_ok(table=>'emp', where => { like => {ename => 'clerk%'}}, results=>0, label=>"raw insert ok");

cursor_insert;
row_ok(table=>'emp', where => { like => {ename => 'clerk%'}}, results=>1000, label=>"raw insert ok");

trunc;
