# -*- perl -*-

# t/03_noindex.t -- check itan without index

use Test::More tests => 5;

use lib qw(t/);

use testutils;

# initialize db
unlink testutils::test_db();

my $dbh = testutils::test_dbh;

testutils::run_import(
    "0\t00000001",
    "0\t00000002",
    "0\t00000003",
);

my $sth_count = $dbh->prepare('SELECT COUNT(*) FROM itan WHERE valid = 1');
$sth_count->execute();
is ($sth_count->fetchrow_array(),3,'Imported 3 itans');

testutils::run_command('get','next' => 1,'memo' => 'testmemo');

$sth_count->execute();
is ($sth_count->fetchrow_array(),2,'2 itans still active');
$sth_count->finish;

my $sth_inactive = $dbh->prepare('SELECT * FROM itan WHERE valid = 0');
$sth_inactive->execute();
my $data = $sth_inactive->fetchrow_hashref();
$sth_inactive->finish();

is($data->{tindex},1,'Tan 1 was used');
is($data->{memo},'testmemo','Memo was saved');
like($data->{used},qr/^20\d\d\/\d\d\/\d\d\s+\d\d:\d\d$/,'Memo was saved');