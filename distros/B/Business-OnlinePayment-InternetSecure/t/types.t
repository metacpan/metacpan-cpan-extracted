# vim:set syntax=perl encoding=utf-8:

# Check for case-insensitivity and CC support in type

use constant TYPES => ('Visa', 'viSa', 'CC');

use Test::More tests => 1 + TYPES;

BEGIN { use_ok('Business::OnlinePayment') };

my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

foreach my $type (TYPES) {
	$txn->content(
		action		=> 'Normal Authorization',
		type		=> $type,

		card_number	=> '5111-1111-1111-1111',
		exp_date	=> '0704',

		amount		=> 13.95,
	);

	# This will fail if type is not recognized
	$txn->to_xml;

	pass("type: $type");
}

