# $Id: test_or_live.t 1903 2006-09-26 21:21:40Z comdog $

use Test::More 'no_plan';

my $class = "Business::US::USPS::WebTools";

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my $webtools = $class->new( {
	UserID   => 'fake_user',
	Password => "this won't work",
	Testing  => 1,
	} );
	
ok( $webtools->_testing, "I think I'm testing" );

is( ! $webtools->_live, 1, "I don't think I'm live!" );
is( $webtools->_api_host, "testing.shippingapis.com", "Testing host is right" );
is( $webtools->_api_path, "/ShippingAPITest.dll", "Testing path is right" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my $webtools = $class->new( {
	UserID   => 'fake_user',
	Password => "this won't work",
	Testing => 0,
	} );
	
ok( $webtools->_live, "I think I'm live" );

is( ! $webtools->_testing, 1, "I don't think I'm testing!" );
is( $webtools->_api_host, "production.shippingapis.com", "Live host is right" );
is( $webtools->_api_path, "/ShippingAPI.dll", "Testing path is right" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Passing empty hash
{
my $webtools = $class->new( {
	UserID   => 'fake_user',
	Password => "this won't work",
	} );
	
ok( $webtools->_live, "I think I'm live" );

is( ! $webtools->_testing, 1, "I don't think I'm testing!" );
is( $webtools->_api_host, "production.shippingapis.com", "Live host is right" );
is( $webtools->_api_path, "/ShippingAPI.dll", "Testing path is right" );
}
