BEGIN {
	@classes = qw(Business::ISBN::Data);
	}

use Test::More tests => scalar @classes;
	
foreach my $class ( @classes )
	{
	print "bail out! $class did not compile!" unless use_ok( $class );
	}
