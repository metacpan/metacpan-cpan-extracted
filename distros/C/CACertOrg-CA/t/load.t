BEGIN { @classes = qw( CACertOrg::CA ) }

use Test::More tests => scalar @classes;
	
foreach my $class ( @classes ) {
	print "Bail out!\n" unless use_ok( $class );
	}
