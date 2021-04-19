#!perl
use 5.006;
use strict;
use warnings;
use HTTP::Tiny;
use Test::More tests => 5;
use JSON::PP;

BEGIN {
    use_ok( 'Business::Stripe::WebCheckout' ) || print "Bail out!\n";
}

# diag( "Testing Business::Stripe::WebCheckout $Business::Stripe::WebCheckout::VERSION, Perl $], $^X" );

my $http = HTTP::Tiny->new(
    'timeout'   => 6,
);

ok( $http->isa('HTTP::Tiny'),                          'HTTP::Tiny installed OK');

my $stripe = Business::Stripe::WebCheckout->new(
    'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    'api-secret'    => 'sk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    'success-url'   => 'https://www.example.com/yippee.html',
    'cancel-url'    => 'https://www.example.com/ohdear.html',
    'url'           => 'https://www.boddison.com/cgi-bin/cpan/Business-Stripe-WebCheckout-test.pl',
);

ok( $stripe->isa( 'Business::Stripe::WebCheckout' ),  'Instantiation to test server' );
ok( $stripe->success,                                 'Successful object creation to test server' );


$stripe->add_product(
	'id'			=> 1,
	'name'			=> 'Live Test',
	'description'	=> 'Mock call to test live connection',
	'price'			=> 100,
	'qty',			=> 1,
);

ok( $stripe->success,								  'Test added to Trolley' );

 done_testing;

__END__

# Server detects make as suspicious and blocks requests!
# This will be cured in a later release

my $response = $http->get('https://www.boddison.com/cgi-bin/home.pl');
SKIP: {
    skip "No connection to testing server", 5 unless $response->{'success'};
	
	my $get_intent;
	$get_intent = $stripe->get_intent;
	
	ok( $stripe->success,		'get_intent successful' );
	SKIP: {
		skip "Didn't get a successful return value", 5 unless $stripe->success;
	    my $intent = decode_json($get_intent);
	
	    is( $intent->{'id'}, 'cs_test_fyfsdX4siw4JKBsc6l5dcp742cb8eT6CgfwcB5ue9b9qIVanpyxOq7WQ',                    'Correct test checkout ID retrieved by get_intent');
	    is( $intent->{'payment_intent'}, 'pi_1EUmyo2xh8fd4drhUuJXu9m0',                                             'Correct test payment intent retrieved by intent');
	    
	    my $intent_id = $stripe->get_intent_id;
	    
	    is( $intent_id, 'cs_test_fyfsdX4siw4JKBsc6l5dcp742cb8eT6CgfwcB5ue9b9qIVanpyxOq7WQ',                         'Correct test checkout ID retrieved by get_intent_id');
	    
	    my $ids = $stripe->get_ids;
	    
	    is( $ids, 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000:pi_1EUmyo2xh8fd4drhUuJXu9m0',   'Correct IDs retrieved by get_ids');
	    
	    my $checkout = $stripe->checkout;
	    
	    ok( $checkout =~ /var stripe = Stripe/,                                                                     'Checkout returns HTML' );
	    
	    diag "Carried out live tests of success state as connected to test server";
	}
}

# Test getting a fail response from the test server

$stripe = Business::Stripe::WebCheckout->new(
    'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    'api-secret'    => 'sk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    'success-url'   => 'https://www.example.com/yippee.html',
    'cancel-url'    => 'https://www.example.com/ohdear.html',
    'url'           => 'https://www.boddison.com/cgi-bin/cpan/Business-Stripe-WebCheckout-test.pl',
    'api-test-fail'	=> 1,
);

ok( $stripe->isa( 'Business::Stripe::WebCheckout' ),  'Instantiation of fail test to test server' );
ok( $stripe->success,                                 'Successful object creation of fail test to test server' );


SKIP: {
    skip "No connection to testing server", 8 unless $response->{'success'};

 #   my $intent = $stripe->get_intent;
    
    ok( !$stripe->success,			'Unsuccessful get_intent as expected' );

    ok( $stripe->error, 			'Error message set by get_intent');
    
    my $intent_id = $stripe->get_intent_id;
    
    ok( !$stripe->success,			'Unsuccessful get_intent_id as expected' );

    ok( $stripe->error, 			'Error message set by get_intent_id');
    
    my $ids = $stripe->get_ids;
    
    ok( !$stripe->success,			'Unsuccessful get_ids as expected' );

    ok( $stripe->error, 			'Error message set by get_ids');
    
    my $checkout = $stripe->checkout;
    
    ok( !$stripe->success,			'Unsuccessful checkout as expected' );

    ok( $stripe->error, 			'Error message set by checkout');
    
    diag "Carried out live tests of fail state as connected to test server";
}

done_testing;
