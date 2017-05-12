use Test::More 'no_plan';

use Carp;

$SIG{__DIE__} = \&Carp::confess;

use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'AUTOLOAD';

use_ok( $class );
can_ok( $class, $method );

$|++;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Something that I know will work through AUTOLOAD
{
my $package_details = $class->new;
isa_ok( $package_details, $class );

my $auto_method = 'url';
can_ok( $package_details, $auto_method );
ok( eval { $package_details->$auto_method() }, 
	"Calling $method works just fine" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Add a new header from the top. It should dispatch to the right delegate
{
my $package_details = $class->new;
isa_ok( $package_details, $class );

my $auto_method = 'Cat';
my $value       = 'Buster';
can_ok( $package_details, 'set_header' );
$package_details->set_header( $auto_method, $value );

can_ok( $package_details, 'header_exists' );
ok( $package_details->header_exists( $auto_method ), 
	"Non-standard header $auto_method added from top level" );

can_ok( $package_details, $auto_method );
is( $package_details->$auto_method(), $value, 
	"Calling $method works just fine after add_header from top level" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Add a new header from the delegate
{
my $package_details = $class->new;
isa_ok( $package_details, $class );

my $header = $package_details->header;
isa_ok( $header, $package_details->header_class );

my $auto_method = 'Cat';
my $value       = 'Buster';
can_ok( $header, 'set_header' );
$header->set_header( $auto_method, $value );

can_ok( $header, 'header_exists' );
ok( $header->header_exists( $auto_method ), 
	"Non-standard header $auto_method added from header class" );

can_ok( $header, $auto_method );
is( $header->$auto_method(), $value, 
	"Calling $auto_method works just fine after add_header from header class" );
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Something that I know will fail through AUTOLOAD
{
my $package_details = $class->new;
isa_ok( $package_details, $class );

my $auto_method = 'yo_mama';
ok( ! $package_details->can($auto_method), "Can't $auto_method, and that's good!" );

stderr_like
	{ eval { $package_details->$auto_method() } }
	qr/No such method/,
	"AUTOLOAD carps for bad method $auto_method";
}
