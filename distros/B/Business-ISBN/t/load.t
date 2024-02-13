use Test::More;

my @classes = (
	'Business::ISBN',
	map { "Business::ISBN$_" } '',  '10', '13'
	);


foreach my $class ( @classes ) {
	BAIL_OUT("Bail out! $class could not be loaded: $@")
		unless use_ok( $class );
	}

diag( "Business::ISBN::Data version: " . Business::ISBN::Data->VERSION );
diag( "Business::ISBN::Data location: " . $INC{'Business/ISBN/Data.pm'} );

done_testing();
