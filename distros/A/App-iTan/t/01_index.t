# -*- perl -*-

# t/01_index.t -- check itan with index

use Test::More tests => 41;

use lib qw(t/);

use testutils;

# initialize db
testutils::initialize();

my $dbh = testutils::test_dbh;
my $sth1 = $dbh->prepare('SELECT * FROM itan ORDER BY tindex ASC');

$sth1->execute();

my $count = 0;
while (my $row = $sth1->fetchrow_hashref()) {
    $count ++;
    
    is($row->{tindex},$count,'Index is ok');
    isnt($row->{tindex},sprintf("%08i",$count),'Itan is encrypted');
    like($row->{imported},qr/^20\d\d\/\d\d\/\d\d\s+\d\d:\d\d$/,'Imported date was set');
    is($row->{used},undef,'Has not been used yet');
    is($row->{valid},1,'Is valid');
}

is($count,5,'5 itans have been imported');

# import again
testutils::run_import(
    "05\t00000005",
    "06\t00000006",
);

my ($valid,$used,$total);
my $sth_countvalid = $dbh->prepare('SELECT SUM(valid),COUNT(used),COUNT(1) FROM itan;');
$sth_countvalid->execute();
($valid,$used,$total) = $sth_countvalid->fetchrow_array();
is($valid,6,'Now 6 valid itans');
is($used,0,'Now 0 used itans');
is($total,6,'Now 6 total itans');

testutils::run_command('get','index' => 5,'memo' => 'testmemo');

$sth_countvalid->execute();
($valid,$used,$total) = $sth_countvalid->fetchrow_array();
is($valid,5,'Now 5 valid itans');
is($used,1,'Now 1 used itans');
is($total,6,'Now 6 total itans');

my $sth_inactive = $dbh->prepare('SELECT * FROM itan WHERE valid = 0');
$sth_inactive->execute();
my $data = $sth_inactive->fetchrow_hashref();
$sth_inactive->finish();

is($data->{tindex},5,'Tan 5 was used');
is($data->{memo},'testmemo','Memo was saved');
like($data->{used},qr/^20\d\d\/\d\d\/\d\d\s+\d\d:\d\d$/,'Memo was saved');

testutils::run_command('reset');

$sth_countvalid->execute();
($valid,$used,$total) = $sth_countvalid->fetchrow_array();
is($valid,0,'Now 0 valid itans');
is($used,1,'Now 1 used itans');
is($total,6,'Now 6 total itans');

# import again
testutils::run_import(
    "05\t00000005",
    "06\t00000006",
);

$sth_countvalid->execute();
($valid,$used,$total) = $sth_countvalid->fetchrow_array();
is($valid,2,'Now 2 valid itans');
is($used,1,'Now 1 used itans');
is($total,8,'Now 8 total itans');


