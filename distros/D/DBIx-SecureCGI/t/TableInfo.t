use t::share;

plan tests => 28;

# $tables: scalar/array
# err: bad table name
# err: one of $tables is bad
# TableInfo sync/async

ok my $dbh = new_adbh;
ok my $table1 = new_table "id $PK, i INT";
ok my $table2 = new_table "d DATETIME";
ok my $table3 = new_table "id $PK, s VARCHAR(255)";

is $dbh->TableInfo($table1), $dbh->SecureCGICache;
is $dbh->TableInfo([$table3]), $dbh->SecureCGICache;
is scalar keys %{ $dbh->SecureCGICache }, 2;

is scalar keys %{ $dbh->SecureCGICache({}) }, 0;
ok $dbh->TableInfo([$table1,$table3]);
is scalar keys %{ $dbh->SecureCGICache }, 2;

ok !$dbh->TableInfo, 'err';
ok $dbh->err;
like $dbh->errstr, qr/bad tables:/;
ok !$dbh->TableInfo([$table1,$table2,$table3]), 'err';
ok $dbh->err;
like $dbh->errstr, qr/primary key:/;

my $cv;
$dbh->SecureCGICache({});
$dbh->TableInfo($table1, $cv = AE::cv);
is $cv->recv, $dbh->SecureCGICache;
$dbh->TableInfo([$table3], $cv = AE::cv);
is $cv->recv, $dbh->SecureCGICache;
is scalar keys %{ $dbh->SecureCGICache }, 2;

$dbh->SecureCGICache({});
is scalar keys %{ $dbh->SecureCGICache }, 0;
$dbh->TableInfo([$table1,$table3], $cv = AE::cv);
ok $cv->recv;
is scalar keys %{ $dbh->SecureCGICache }, 2;

$dbh->TableInfo(undef, $cv = AE::cv);
ok !$cv->recv, 'err';
ok $dbh->err;
like $dbh->errstr, qr/bad tables:/;
$dbh->TableInfo([$table1,$table2,$table3], $cv = AE::cv);
ok !$cv->recv, 'err';
ok $dbh->err;
like $dbh->errstr, qr/primary key:/;


done_testing;
