use lib 't';
use share;

plan tests => 15;

my $cv;
my $dbh = new_adbh;
my $table = new_table "id $PK, i INT, s VARCHAR(255)";

is_deeply [$dbh->Select("no_such_$table")], [undef];
ok $dbh->err;
like $dbh->errstr, qr/doesn't exist/;

is $dbh->Select($table), undef;
is_deeply [$dbh->Select($table)], [];
ok !$dbh->err;

$dbh->Insert($table, {i=>1,s=>'one'});
$dbh->Insert($table, {i=>2,s=>'two'});
$dbh->Insert($table, {i=>3,s=>'three'});
$dbh->Insert($table, {i=>30,s=>'three'});
$dbh->Insert($table, {i=>300,s=>'three'});
$dbh->Insert($table, {i=>4,s=>'four'});
$dbh->Insert($table, {i=>5,s=>'five'});
my @R = (
    undef,
    { id => 1, i => 1, s => 'one' },
    { id => 2, i => 2, s => 'two' },
    { id => 3, i => 3, s => 'three' },
    { id => 4, i => 30, s => 'three' },
    { id => 5, i => 300, s => 'three' },
    { id => 6, i => 4, s => 'four' },
    { id => 7, i => 5, s => 'five' },
);

is_deeply scalar $dbh->Select($table), {id=>1,i=>1,s=>'one'};
is(()=$dbh->Select($table), 7);

is_deeply [$dbh->Select($table, {s=>'three'})], [@R[3,4,5]];
is_deeply [$dbh->Select($table, {i__gt=>10})],  [@R[4,5]];
is_deeply [$dbh->Select($table, {s__like=>['t%','f%']})],  [];
is_deeply [$dbh->Select($table, {s__like=>['t%','%ee']})],  [@R[3,4,5]];
is_deeply [$dbh->Select($table, {__limit=>0})], [];
is_deeply [$dbh->Select($table, {__group=>'s',__order=>'id DESC',__limit=>[1,3]})],
    [map {$a={%$_}; $a->{__count} = $a->{s} eq 'three' ? 3 : 1; $a} @R[6,3,2]];

$dbh->Select($table, {__limit=>2}, $cv=AE::cv);
is_deeply [$cv->recv], [@R[1,2]];

done_testing();
