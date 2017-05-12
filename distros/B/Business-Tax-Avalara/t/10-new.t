#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Business::Tax::Avalara;


# Create an object to communicate with Avalara.
my $avalara_gateway = Business::Tax::Avalara->new(
	customer_code  => 'XXXX',
	company_code   => 'XXXX',
	user_name      => 'XXXX',
	password       => 'XXXX',
	origin_address =>
	{
		line_1      => '1313 Mockingbird Lane',
		postal_code => '98765',
	},
);

isa_ok(
	$avalara_gateway,
	'Business::Tax::Avalara',
	'Object returned by Business::Tax::Avalara->new()',
);