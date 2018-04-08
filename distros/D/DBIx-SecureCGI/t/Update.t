use lib 't';
use share;

plan tests => 18;

my $cv;
my $dbh = new_adbh {PrintError=>0};
my $table = new_table "id $PK, i int";

ok $dbh->Insert($table, {i=>1});
ok $dbh->Insert($table, {i=>2});

ok !$dbh->Update("no_such_$table", {i=>10});
like $dbh->errstr, qr/doesn't exist/;

ok !$dbh->Update($table, {i=>10});
like $dbh->errstr, qr/empty WHERE/;

ok !$dbh->Update($table, {i=>10,__force=>0});
like $dbh->errstr, qr/empty WHERE/;

is $dbh->Update($table, {i=>10,__force=>1}), 2;
is $dbh->Count($table, {i=>10}), 2;

ok !$dbh->Update($table, {i=>20,__limit=>1});
like $dbh->errstr, qr/empty WHERE/;

is $dbh->Update($table, {i=>20,__limit=>1,__force=>1}), 1;
is $dbh->Count($table, {i=>10}), 1;

is $dbh->Update($table, {i=>1,id=>5}), '0E0';
is $dbh->Update($table, {i=>1,id=>1}), 1;
is $dbh->Update($table, {i=>2,i__eq=>1}), 1;

is_deeply [$dbh->Select($table)], [{id=>1,i=>2},{id=>2,i=>10}];

done_testing();
