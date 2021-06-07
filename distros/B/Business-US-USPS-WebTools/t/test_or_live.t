use Test::More 0.98;

my $class = "Business::US::USPS::WebTools";

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest testing => sub {
	my $webtools = $class->new( {
		UserID   => 'fake_user',
		Password => "this won't work",
		Testing  => 1,
		} );

	ok( $webtools->_testing, "I think I'm testing" );

	is( ! $webtools->_live, 1, "I don't think I'm live!" );
	is( $webtools->_api_host, "stg-production.shippingapis.com", "Testing host is right" );
	is( $webtools->_api_path, "/ShippingAPI.dll", "Testing path is right" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest not_testing => sub {
	my $webtools = $class->new( {
		UserID   => 'fake_user',
		Password => "this won't work",
		Testing => 0,
		} );

	ok( $webtools->_live, "I think I'm live" );

	is( ! $webtools->_testing, 1, "I don't think I'm testing!" );
	is( $webtools->_api_host, "production.shippingapis.com", "Live host is right" );
	is( $webtools->_api_path, "/ShippingAPI.dll", "Testing path is right" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Passing empty hash
subtest empty => sub {
	my $webtools = $class->new( {
		UserID   => 'fake_user',
		Password => "this won't work",
		} );

	ok( $webtools->_live, "I think I'm live" );

	is( ! $webtools->_testing, 1, "I don't think I'm testing!" );
	is( $webtools->_api_host, "production.shippingapis.com", "Live host is right" );
	is( $webtools->_api_path, "/ShippingAPI.dll", "Testing path is right" );
	};

done_testing();
