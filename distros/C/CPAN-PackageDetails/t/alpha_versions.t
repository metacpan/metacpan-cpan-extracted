use Test::More;

my $class = 'CPAN::PackageDetails';
use_ok( $class );
use_ok( "${class}::Entries" );

my $packages = $class->new(
	allow_packages_only_once => 0,
	disallow_alpha_versions  => 1,
	);
isa_ok( $packages, $class );
ok( $packages->disallow_alpha_versions, 'disallow_alpha_versions is true' );

my @alpha_versions = qw( 1.00_001 1.23_01 8.89_002 );
my @good_versions  = qw( 1 1.23 1.2.3 );

foreach my $v ( @alpha_versions ) {
	my( $parsed, $alpha, $warning ) = $packages->entries->_parse_version( $v );
	ok( $alpha, "version string [$v] is an alpha version" );

	my $w;
	local $SIG{__WARN__} = sub { $w = join "\n", @_ };

	my $rc = eval { $packages->add_entry(
		package_name => 'Foo::Bar',
		version      => $v,
		path         => "/Foo-Bar-$v",
		) };

	ok( ! defined $rc, "Return value is not defined for [$v]" );
	}

foreach my $v ( @good_versions ) {
	my( $parsed, $alpha, $warning ) = $packages->entries->_parse_version( $v );
	ok( ! $alpha, "version string [$v] is not an alpha version" );

	my $rc = eval { $packages->add_entry(
		package_name => 'Foo::Bar',
		version      => $v,
		path         => "/Foo-Bar-$v",
		) };

	ok( defined $rc, "Return value is defined for [$v]" );
	}

done_testing();
