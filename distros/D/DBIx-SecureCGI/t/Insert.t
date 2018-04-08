use lib 't';
use share;

plan tests => 10;

my $cv;
my $dbh = new_adbh {PrintError=>0};
my $table = new_table "id $PK, i int";

ok !$dbh->Insert("no_such_$table", {i=>10});
like $dbh->errstr, qr/doesn't exist/;

is $dbh->Insert($table, {i=>10}), 1;
is $dbh->Insert($table, {i=>10}), 2;
is $dbh->Insert($table, {id=>10}), 10;
ok !$dbh->Insert($table, {id=>10});
like $dbh->errstr, qr/Duplicate/;

$dbh->Insert($table, {i=>10}, $cv = AE::cv);
is $cv->recv, 11;
$dbh->Insert($table, {id=>10}, $cv = AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/Duplicate/;

done_testing();
