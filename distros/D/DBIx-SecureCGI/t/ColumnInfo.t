use t::share;

plan tests => 17;

ok my $dbh = new_adbh {PrintError=>0};
ok my $table = new_table "id $PK, i INT";
ok my $table2 = new_table "i INT";
ok my $table3 = new_table "id $PK, i INT";

my $info = $dbh->ColumnInfo($table);
ok $info, 'sync';
is $dbh->ColumnInfo($table), $info, 'sync cached';
is 0+@$info, 2;
is $info->[0]{Field}, 'id';

ok !$dbh->ColumnInfo($table2), 'err';
ok $dbh->err;
like $dbh->errstr, qr/primary key/;

my $cv;
$dbh->ColumnInfo($table3, $cv = AE::cv);
$info = $cv->recv;
ok $info, 'async';
$dbh->ColumnInfo($table3, $cv = AE::cv);
is $cv->recv, $info, 'async cached';
ok !$dbh->err;
$dbh->ColumnInfo($table2, $cv = AE::cv);
ok !$cv->recv, 'err';
ok $dbh->err;
like $dbh->errstr, qr/primary key/;

done_testing();
