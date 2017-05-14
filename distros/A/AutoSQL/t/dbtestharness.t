use strict;
use lib 't/lib';
use DBTestHarness;
$AutoCode::Root::DEBUG=1;
my $harness=DBTestHarness->new(
    -user => 'root',
    -dbname=>'',
    -drop_during_destroy=> -1
);

$harness->create_test_db;

