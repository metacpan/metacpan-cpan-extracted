package t::lib::Test;

use Test::More;
use DBR;
use DBR::Util::Logger;
use DBR::Config::ScanDB;
use DBR::Config::SpecLoader;
use DBR::Config::Schema;
use File::Path;
use DBR::Sandbox;

our @EXPORT = qw(connect_ok setup_schema_ok);
our $VERSION = '1';

use base 'Exporter';

# Delete temporary files
sub clean {
	#unlink( 'test-subject-db.sqlite' );
	#unlink( 'test-config-db.sqlite'  );
}

# Clean up temporary test files both at the beginning and end of the
# test script.
BEGIN { clean() }
END   { clean() }

sub connect_ok {
        my $attr = { @_ };
        my $dbfile = delete $attr->{dbfile} || ':memory:';
        my @params = ( "dbi:SQLite:dbname=$dbfile", '', '' );
        if ( %$attr ) {
            push @params, $attr;
        }
        my $dbh = DBI->connect( @params );
        Test::More::isa_ok( $dbh, 'DBI::db' );
        return $dbh;
}

sub setup_schema_ok{
    my $testid = shift;
    my $dbr = DBR::Sandbox->provision( schema => $testid, quiet => 1 );
    
    Test::More::ok( $dbr, 'Setup Schema' );
    return $dbr;
}

1;
