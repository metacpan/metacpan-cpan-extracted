#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Amibroker::OLE::Interface'); }
#
# Checking with right parameters
#
my $obj1 = Amibroker::OLE::Interface->new(
    { dbpath => 'C:\TradingTools\Amibroker5.90.1\InOutData' } );
isa_ok( $obj1, 'Amibroker::OLE::Interface' );

my $obj2 = Amibroker::OLE::Interface->new(
    { verbose => 1, dbpath => 'C:\TradingTools\Amibroker5.90.1\InOutData' } );
isa_ok( $obj2, 'Amibroker::OLE::Interface' );

#
# Wrong parameters passed
#
eval { my $obj3 = Amibroker::OLE::Interface->new( { test => 1 } ); };
pass('Not accepting wrong parameters') if ($@);

my $ret1 = $obj1->start_amibroker_engine();
is( $ret1, 1, 'Amibroker engine started...working' );
SKIP: {
# I wrote this test to test the working functionality of run_analysis method in my system
# the path of apx_file and it contents varies between different users.
# I just used a test apx_file and tested with a symbol 'ABIRLANUVO-I' present in my amibroker database
    skip 'database specific test', 1;
    my $ret = $obj1->run_analysis(
        {
            action => 2,
            symbol => 'ABIRLANUVO-I',
            apx_file =>
'C:\BabuDevProjects\AmiBackTester\OPTLogs\20150914-142242\ABIRLANUVO-5-Minute-ATR-BASIC.apx',
            result_file => 'C:\Users\CYBROZ\Desktop\errors_15\results.csv'
        }
    );
    is( $ret, 1, 'Amibroker backtest working' );
}
my $ret2 = $obj1->shutdown_amibroker_engine();
is( $ret1, 1, 'Amibroker engine Successfully Shutdown' );

done_testing();
