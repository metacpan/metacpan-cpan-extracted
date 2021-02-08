use Test::More;
use warnings;

my $class = 'CPAN::PackageDetails';
use_ok( $class );
use_ok( "${class}::Entries" );

my $packages = $class->new(
	allow_packages_only_once => 0,
	);
isa_ok( $packages, $class );

chomp( my @bad_versions = <DATA> );

foreach my $v ( @bad_versions ) {
	my( $parsed, $alpha, $warning ) = $packages->entries->_parse_version( $v );
	ok( defined $warning, "version string [$v] gives a warning from _parse_version" );

	my $w;
	local $SIG{__WARN__} = sub { $w = join "\n", @_ };

	$packages->add_entry(
		package_name => 'Foo::Bar',
		version      => $v,
		path         => "/Foo-Bar-$v",
		);

	like( $w, qr/^add_entry has a problem/, "version string [$v] gives a warning from add_entry" )
	}

done_testing();

__END__
0.56yuot
out
Buster

123.00_001_001
