#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok('DataWarehouse::Fact')       || print "Bail out!\n";
    use_ok('DataWarehouse::Dimension')  || print "Bail out!\n";
    use_ok('DataWarehouse::Aggregate')  || print "Bail out!\n";
    use_ok('DataWarehouse::ETL')        || print "Bail out!\n";
}

diag("Testing Perl-Data-Warehouse-Toolkit $DataWarehouse::Fact::VERSION, Perl $], $^X");
