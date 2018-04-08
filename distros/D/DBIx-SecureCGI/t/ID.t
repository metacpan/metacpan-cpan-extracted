use lib 't';
use share;

plan tests => 12;

my $cv;
my $dbh = new_adbh;
my $table = new_table "id $PK, i INT, s VARCHAR(255)";

is_deeply [$dbh->ID("no_such_$table")], [undef];
ok $dbh->err;
like $dbh->errstr, qr/doesn't exist/;

is_deeply [$dbh->ID($table)], [];
ok !$dbh->err;

$dbh->Insert($table, {i=>1,s=>'one'});
$dbh->Insert($table, {i=>2,s=>'two'});
$dbh->Insert($table, {i=>3,s=>'three'});
$dbh->Insert($table, {i=>30,s=>'three'});
$dbh->Insert($table, {i=>300,s=>'three'});
$dbh->Insert($table, {i=>4,s=>'four'});
$dbh->Insert($table, {i=>5,s=>'five'});

is_deeply [$dbh->ID($table)],                       [1..7];
is_deeply [$dbh->ID($table, {s=>'three'})],         [3..5];
is_deeply scalar $dbh->ID($table, {s=>'three'}),    3;
is_deeply [$dbh->ID($table, {__order=>'i DESC',__group=>'s'})],     [5,4,7,6,3,2,1];
is_deeply [$dbh->ID($table, {__order=>'i DESC',__limit=>3})],       [5,4,7];
is_deeply [$dbh->ID($table, {__order=>'i DESC',__limit=>[2,4]})],   [7,6,3,2];

$dbh->ID($table, {__order=>'i DESC',__limit=>[2,4]}, $cv=AE::cv);
is_deeply [$cv->recv], [7,6,3,2];

done_testing();
