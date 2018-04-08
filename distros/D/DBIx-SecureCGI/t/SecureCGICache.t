use lib 't';
use share;

plan tests => 20;

ok my $dbh = new_dbh;
ok my $dbh2 = new_dbh;
isnt $dbh, $dbh2;

ok my $cache = $dbh->SecureCGICache;
ok my $cache2 = $dbh2->SecureCGICache;
isnt $cache, $cache2;
is   $dbh->SecureCGICache, $cache;
isnt $dbh->SecureCGICache, $cache2;

my $table = new_table "id $PK";
my $table2 = new_table "id $PK";

$dbh->ColumnInfo($table);
is $dbh->SecureCGICache, $cache;
ok $cache->{$table};
ok !$cache2->{$table};

is $dbh2->SecureCGICache($cache), $cache;
$dbh2->ColumnInfo($table2);
ok $cache->{$table2};
ok $dbh->SecureCGICache->{$table};
ok $dbh->SecureCGICache->{$table2};
ok $dbh2->SecureCGICache->{$table};
ok $dbh2->SecureCGICache->{$table2};
is $dbh->SecureCGICache->{$table2}, $dbh2->SecureCGICache->{$table2};

$dbh->SecureCGICache({});
ok !$dbh->SecureCGICache->{$table};
ok $dbh2->SecureCGICache->{$table};

done_testing();
