#!perl -w

use strict;
use lib q(test_lib);

use Config::Properties;
use Test::Unit::TestRunner;
use Test::Unit::TestSuite;
use Test::Unit::HarnessUnit;
use IO::File;

use DBI; 
use DB::Introspector;
use DB::Introspector::TableTest;
use DB::Introspector::RelInspectTest;
use DB::IntrospectorTest;

use constant PROPERTIES_FILE => 'introspector.properties'; 

use vars qw( @TESTS );

@TESTS = qw(
    DB::IntrospectorTest
    DB::Introspector::TableTest
    DB::Introspector::RelInspectTest
);

my $properties_fh = new IO::File('<'.PROPERTIES_FILE())
    || die("properties file ".PROPERTIES_FILE() ." couldn't be opened");

my $properties = new Config::Properties();
$properties->load($properties_fh);

foreach my $dbname ( DB::Introspector->registered_drivers ) {
    # first check properties file for default params

    my $properties_prefix = "introspector.$dbname.connection";
    
    my $dbh;
    eval {
        $dbh = DBI->connect(
            $properties->getProperty($properties_prefix.'.datasource'),
            $properties->getProperty($properties_prefix.'.username'),
            $properties->getProperty($properties_prefix.'.password'), 
            {
            PrintError => 0,
            AutoCommit => 0,
            RaiseError => 1
            });
    };

    unless($dbh) {
        print STDERR "\nCould not establish connection for $dbname\n";
        next;
    }

    foreach my $test_class (@TESTS) {
        Test::Unit::TestRunner->new
                              ->do_run($test_class->new("test", $dbh)->suite);
    }

    $dbh->disconnect();
}

print "\n";
