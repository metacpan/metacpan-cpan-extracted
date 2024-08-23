#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::Address' );

my $Address = Business::TrueLayer::Address->new(
	{
		"address_line1" => "1 Hardwick St",
		"city" => "London",
		"state" => "London",
		"zip" => "EC1R 4RB",
		"country_code" => "GB"
	}
);

isa_ok(
    $Address,
    'Business::TrueLayer::Address',
);

is( $Address->address_line1,'1 Hardwick St','->address_line1' );
is( $Address->city,'London','->city' );
is( $Address->state,'London','->state' );
is( $Address->zip,'EC1R 4RB','->zip' );
is( $Address->country_code,'GB','->country_code' );

done_testing();
