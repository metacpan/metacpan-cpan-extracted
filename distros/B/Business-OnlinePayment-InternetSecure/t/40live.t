# vim:set syntax=perl:

use Test::More;

BEGIN {
	plan skip_all => 'MERCHANT_ID environment variable not set'
		unless defined $ENV{MERCHANT_ID};
};

BEGIN { plan tests => 1 + 2 };

BEGIN { use_ok('Business::OnlinePayment') };


my $txn = new Business::OnlinePayment 'InternetSecure',
		merchant_id => $ENV{MERCHANT_ID};

$txn->test_transaction(1);

$txn->content(
		action		=> 'Normal Authorization',

		type		=> 'Visa',
		card_number	=> '0000000000000000',
		expiration	=> '2004/07',

		name		=> "Fr\x{e9}d\x{e9}ric Bri\x{e8}re",
		address		=> '123 Nowhere',
		city		=> 'Metropolis',
		state		=> 'QC',
		zip		=> 'A1A 1A1',
		country		=> 'CA',
		phone		=> '123-456-7890',
		email		=> 'fbriere@fbriere.net',

		amount		=> 0.01,
		description	=> 'Test transaction',
	);

$txn->submit;

is($txn->result_code, '2000', 'Result code is ok');
is($txn->cardholder, "Fr\x{e9}d\x{e9}ric Bri\x{e8}re",
	'Cardholder name is encoded properly');

$txn->content(
		action		=> 'Card Authorization',

		type		=> 'Visa',
		card_number	=> '0000000000000000',
		expiration	=> '2014/07',

		name		=> "Slobodan Miskovic",
	);

$txn->submit;

is($txn->result_code, '2000', 'CIMB store succesfull');
