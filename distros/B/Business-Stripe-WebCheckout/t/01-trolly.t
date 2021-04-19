#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 25;

#my $test_count = 22;
#plan tests => $test_count;

BEGIN {
    use_ok( 'Business::Stripe::WebCheckout' ) || print "Bail out!\n";
}

# diag( "Testing Business::Stripe::WebCheckout $Business::Stripe::WebCheckout::VERSION, Perl $], $^X" );

my $stripe = Business::Stripe::WebCheckout->new(
	'api-public'    => 'pk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'api-secret'    => 'sk_test_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
	'success-url'   => 'https://www.example.com/yippee.html',
	'cancel-url'    => 'https://www.example.com/ohdear.html',
);

is( scalar( $stripe->list_products ), 0,			 'Empty Trolley' );

$stripe->add_product(
	'id'          => 'A',
	'name'        => 'One',
	'description' => 'Test One',
	'qty'         => 1,
	'price'       => 100,
);

is( scalar( $stripe->list_products ), 1,           											'First product added to Trolley' );
ok( $stripe->get_product(($stripe->list_products)[0])->{'id'} 				eq 'A',			'Correct Product A ID' );
ok( $stripe->get_product(($stripe->list_products)[0])->{'name'} 			eq 'One',  		'Correct Product A Name' );
ok( $stripe->get_product(($stripe->list_products)[0])->{'description'} 		eq 'Test One',	'Correct Product A Description' );
ok( $stripe->get_product(($stripe->list_products)[0])->{'qty'} 				eq '1',			'Correct Product A Quantity' );
ok( $stripe->get_product(($stripe->list_products)[0])->{'price'} 			eq '100',		'Correct Product A Price' );

$stripe->add_product(
	'id'          => 'B',
	'name'        => 'Two',
	'description' => 'Test Two',
	'qty'         => 2,
	'price'       => 200,
);

is( scalar( $stripe->list_products ), 2,           											'Second product added to Trolley' );
ok( $stripe->get_product(($stripe->list_products)[1])->{'id'} 				eq 'B',			'Correct Product B ID' );
ok( $stripe->get_product(($stripe->list_products)[1])->{'name'} 			eq 'Two',  		'Correct Product B Name' );
ok( $stripe->get_product(($stripe->list_products)[1])->{'description'} 		eq 'Test Two',	'Correct Product B Description' );
ok( $stripe->get_product(($stripe->list_products)[1])->{'qty'} 				eq '2',			'Correct Product B Quantity' );
ok( $stripe->get_product(($stripe->list_products)[1])->{'price'} 			eq '200',		'Correct Product B Price' );

$stripe->add_product(
	'id'          => 'C',
	'name'        => 'Three',
	'description' => 'Test Three',
	'qty'         => 3,
	'price'       => 300,
);

is( scalar( $stripe->list_products ), 3,           											'Third product added to Trolley' );
ok( $stripe->get_product(($stripe->list_products)[2])->{'id'} 				eq 'C',			'Correct Product C ID' );
ok( $stripe->get_product(($stripe->list_products)[2])->{'name'} 			eq 'Three',  	'Correct Product C Name' );
ok( $stripe->get_product(($stripe->list_products)[2])->{'description'} 		eq 'Test Three','Correct Product C Description' );
ok( $stripe->get_product(($stripe->list_products)[2])->{'qty'} 				eq '3',			'Correct Product C Quantity' );
ok( $stripe->get_product(($stripe->list_products)[2])->{'price'} 			eq '300',		'Correct Product C Price' );

$stripe->delete_product('B');

ok( $stripe->success,           															'Product removed from Trolley' );
is( scalar( $stripe->list_products ), 2,           											'Product count correct after removal' );

$stripe->delete_product('B');

ok( !$stripe->success,           															'Cannot remove product from Trolley that isn\'t there' );

$stripe->delete_product('A');

ok( $stripe->success,           															'Another product removed from Trolley' );
is( scalar( $stripe->list_products ), 1,           											'Product count again correct after removal' );
