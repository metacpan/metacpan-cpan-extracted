#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'DBIx::Table::TestDataGenerator' ) || print "Bail out!\n";
    use_ok( 'DBIx::Table::TestDataGenerator::DBIxSchemaDumper' ) || print "Bail out!\n";
    use_ok( 'DBIx::Table::TestDataGenerator::Tree' ) || print "Bail out!\n";    
}

diag( "Testing DBIx::Table::TestDataGenerator $DBIx::Table::TestDataGenerator::VERSION, Perl $], $^X" );
