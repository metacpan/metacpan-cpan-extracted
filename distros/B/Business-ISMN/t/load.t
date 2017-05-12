use Test::More 0.95;

my @classes = qw(Business::ISMN Business::ISMN::Data);

foreach my $class ( @classes ) {
	use_ok( $class ) or BAILOUT();
	}

done_testing();
