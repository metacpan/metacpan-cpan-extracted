use strict;
use warnings;
use lib './lib';
use DBI;
use DBD::Crate;
use Test::More;
use Data::Dumper;

if (!$ENV{CRATE_HOST}) {
    plan skip_all => 'You need to set $ENV{CRATE_HOST} to run tests';
}

my $dbh = DBI->connect( 'dbi:Crate:' . $ENV{CRATE_HOST} );
my $sth;
my $blob_table = "crate_test_blob_tbl";
my $string = "some unique data here";

{ ##start with deleting if exists
    $dbh->do("drop blob table $blob_table");
    my $ret = $dbh->do("create blob table $blob_table clustered into 2 shards with (number_of_replicas='0-all')");
    ok($ret);
}

my $hash = $dbh->crate_blob_insert($blob_table, $string) or fail($dbh->errstr);
ok($hash);

my $data = $dbh->crate_blob_get($blob_table, $hash) or fail($dbh->errstr);
ok($data);
is($data, $string);

my $ret = $dbh->crate_blob_delete($blob_table, $hash);
ok($ret);
ok(!$dbh->errstr);

##try to delete again
$ret = $dbh->crate_blob_delete($blob_table, $hash);
ok(!$ret);
ok($dbh->errstr);
is($dbh->err, 404);

{
    ok $dbh->do("drop blob table $blob_table");
}

done_testing(10);
