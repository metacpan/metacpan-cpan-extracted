use Test::More;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'get_header';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with no arguments to new
{
my $package_details = $class->new();
isa_ok( $package_details, $class );

# header that should exist
is( $package_details->$method('intended_for'), "My private CPAN" );
is( $package_details->header->$method('intended_for'), "My private CPAN" );

# header that shouldn't exist
stderr_like
	{ $package_details->$method('Cat') }
	qr/No such header/,
	"My private CPAN";

stderr_like
	{ $package_details->header->$method('Cat') }
	qr/No such header/,
	"My private CPAN";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with some arguments to new
{
my $param = 'Cat';
my $value = 'Buster';

my $package_details = $class->new(
	$param => $value,
	);
isa_ok( $package_details, $class );
ok( $package_details->header_exists($param), "Header $param exists" );

can_ok( $package_details, $method );
can_ok( $package_details->header, $method );
is( $package_details->$method($param), $value );
is( $package_details->header->$method($param), $value );
}

done_testing();
