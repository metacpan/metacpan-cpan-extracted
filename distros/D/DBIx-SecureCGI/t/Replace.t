use lib 't';
use share;

plan tests => 7;

my $cv;
my $dbh = new_adbh {PrintError=>0};
my $table = new_table "id $PK, i int";

ok $dbh->Insert($table, {i=>10});
ok $dbh->Insert($table, {i=>20});

ok !$dbh->Replace("no_such_$table", {id=>1,i=>11});
like $dbh->errstr, qr/doesn't exist/;

ok $dbh->Replace($table, {id=>1,i=>11});
$dbh->Replace($table, {id=>2,i=>21}, $cv=AE::cv);
ok $cv->recv;

is_deeply [$dbh->Select($table)], [{id=>1,i=>11},{id=>2,i=>21}];


done_testing();
