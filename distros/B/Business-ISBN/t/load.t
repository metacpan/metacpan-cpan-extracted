BEGIN { @classes = map { "Business::ISBN$_" } '',  '10', '13' }

use Test::More tests => scalar @classes;
	
foreach my $class ( @classes )
	{
	print "Bail out!\n" unless use_ok( $class );
	}
