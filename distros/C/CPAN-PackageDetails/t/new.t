use Test::More 'no_plan';

my $class  = 'CPAN::PackageDetails';
my $method = 'new';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with no arguments to new
{
my $package_details = $class->$method();
isa_ok( $package_details, $class );

my @instance_methods = qw(header entries header_class entries_class entry_class);
foreach my $method ( @instance_methods )
	{
	can_ok( $package_details, $method );
	}

# should have the two major components
isa_ok( $package_details->header,  $package_details->header_class );
isa_ok( $package_details->entries, $package_details->entries_class );

# should be able to see the defaults
can_ok( $package_details, 'default_headers' );
my %hash = $package_details->default_headers;
foreach my $default ( keys %hash )
	{
	can_ok( $package_details, $default );
	is( $package_details->$default(), $hash{$default}, 
		"Right default value for $default" );
	}
}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with some arguments to new
{
my $url   = 'http://localhost:8088/index.html';
my $param = 'url';

my $package_details = $class->$method(
	$param => $url,
	);
isa_ok( $package_details, $class );

can_ok( $package_details, $param );
is( $package_details->$param(), $url );
}
