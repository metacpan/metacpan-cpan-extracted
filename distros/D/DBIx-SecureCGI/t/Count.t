use t::share;

plan tests => 13;

my $cv;
my $dbh = new_adbh;
my $table = new_table "id $PK, i INT, s VARCHAR(255)";

is_deeply [$dbh->Count("no_such_$table")], [undef];
ok $dbh->err;
like $dbh->errstr, qr/doesn't exist/;

is $dbh->Count($table), 0;
is_deeply [$dbh->Count($table)], [0];
ok !$dbh->err;

$dbh->Insert($table, {i=>1,s=>'one'});
$dbh->Insert($table, {i=>2,s=>'two'});
$dbh->Insert($table, {i=>3,s=>'three'});
$dbh->Insert($table, {i=>30,s=>'three'});
$dbh->Insert($table, {i=>300,s=>'three'});
$dbh->Insert($table, {i=>4,s=>'four'});
$dbh->Insert($table, {i=>5,s=>'five'});

is $dbh->Count($table), 7;
is $dbh->Count($table, {s=>'three'}), 3;
is $dbh->Count($table, {i__gt=>10}),  2;
is $dbh->Count($table, {__order=>'i DESC',__group=>'s'}), 7;
is $dbh->Count($table, {__limit=>3}), 7;
is $dbh->Count($table, {__limit=>0}), 7;
$dbh->Count($table, {__limit=>0}, $cv=AE::cv);
is $cv->recv, 7;

done_testing();
