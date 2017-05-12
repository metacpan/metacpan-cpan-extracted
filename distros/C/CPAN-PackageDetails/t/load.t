BEGIN {
	@classes = qw(
		CPAN::PackageDetails
		CPAN::PackageDetails::Header
		CPAN::PackageDetails::Entries
		CPAN::PackageDetails::Entry
		);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}
