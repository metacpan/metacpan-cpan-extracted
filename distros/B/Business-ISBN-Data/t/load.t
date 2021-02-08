my @classes = qw(Business::ISBN::Data);

use Test::More;

foreach my $class ( @classes ) {
	print "bail out! $class did not compile!" unless use_ok( $class );
	}

done_testing();
