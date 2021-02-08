use Test::More;

@classes = qw(
	CPAN::PackageDetails
	CPAN::PackageDetails::Header
	CPAN::PackageDetails::Entries
	CPAN::PackageDetails::Entry
	);

foreach my $class ( @classes ) {
	BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );
	}

done_testing();
