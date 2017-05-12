use t::share;

plan tests => 10;

my $cv;
my $dbh = new_adbh {PrintError=>0};
my $table = new_table "id $PK, i int";

ok !$dbh->InsertIgnore("no_such_$table", {i=>10});
like $dbh->errstr, qr/doesn't exist/;

ok $dbh->InsertIgnore($table, {i=>10});
ok $dbh->InsertIgnore($table, {i=>10});
ok $dbh->InsertIgnore($table, {id=>10});
ok $dbh->InsertIgnore($table, {id=>10});
ok !$dbh->err;

$dbh->InsertIgnore($table, {i=>10}, $cv = AE::cv);
ok $cv->recv;
$dbh->InsertIgnore($table, {id=>10}, $cv = AE::cv);
ok $cv->recv;
ok !$dbh->err;

done_testing();
