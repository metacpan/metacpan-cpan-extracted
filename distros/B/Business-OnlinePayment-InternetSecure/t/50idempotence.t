# vim:set syntax=perl encoding=utf-8:

# get_remap_fields() used to be destructive (via remap_fields), and thus
# to_xml couldn't be called by itself.

use Test::More tests => 1 + 1;

BEGIN { use_ok('Business::OnlinePayment') };

use constant TRANSACTION =>
	(
		action		=> 'Normal Authorization',

		card_number	=> '5111-1111-1111-1111',
		expiration	=> '0704',

		name		=> "Fr\x{e9}d\x{e9}ric Bri\x{e8}re",

		amount		=> 13.95,
	);


my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

$txn->content(TRANSACTION);

is($txn->to_xml, $txn->to_xml, 'idempotence');

