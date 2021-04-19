#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

#my $test_count = 22;
#plan tests => $test_count;

BEGIN {
    use_ok( 'Business::Stripe::WebCheckout' ) || print "Bail out!\n";
}

diag( "Testing Business::Stripe::WebCheckout $Business::Stripe::WebCheckout::VERSION, Perl $], $^X" );

my $stripe_pass = Business::Stripe::WebCheckout->new(
	'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'api-secret'    => 'sk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'success-url'   => 'https://www.example.com/yippee.html',
	'cancel-url'    => 'https://www.example.com/ohdear.html',
);

ok( $stripe_pass->isa( 'Business::Stripe::WebCheckout' ), 'Instantiation' );
ok( $stripe_pass->success,								  'Successful object creation' );

my $stripe_fail = Business::Stripe::WebCheckout->new(
	'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'api-secret'    => 'sk_test_00000000',
	'success-url'   => 'https://www.example.com/yippee.html',
	'cancel-url'    => 'https://www.example.com/ohdear.html',
);

ok( $stripe_fail->isa( 'Business::Stripe::WebCheckout' ), 'Instantiation' );
ok( !$stripe_fail->success,								  'Error during object creation' );


done_testing;