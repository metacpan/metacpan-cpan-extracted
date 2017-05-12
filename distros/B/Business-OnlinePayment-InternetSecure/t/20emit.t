# vim:set syntax=perl encoding=utf-8:

use Test::More tests => 4 + 3;

BEGIN { use_ok('Business::OnlinePayment') };
BEGIN { use_ok('Business::OnlinePayment::InternetSecure') };
BEGIN { use_ok('XML::Simple', qw(xml_in)) };
BEGIN { use_ok('Encode') };

use charnames ':full';	# Why doesn't this work with use_ok?

use constant TRANSACTIONS => (
	{
		_test		=> 0,

		action		=> 'Normal Authorization',

		type		=> 'Visa',
		card_number	=> '4111 1111 1111 1111',
		expiration	=> '2004-07',
		cvv2		=> '000',

		name		=> "Fr\N{LATIN SMALL LETTER E WITH ACUTE}d\N{LATIN SMALL LETTER E WITH ACUTE}ric Bri\N{LATIN SMALL LETTER E WITH GRAVE}re",
		company		=> '',
		address		=> '123 Street',
		city		=> 'Metropolis',
		state		=> 'ZZ',
		zip		=> 'A1A 1A1',
		country		=> 'CA',
		phone		=> '(555) 555-1212',
		email		=> 'fbriere@fbriere.net',

		amount		=> undef,
		currency	=> 'USD',
		taxes		=> 'HST',

		description => [
				{
				amount		=> 9.99,
				quantity	=> 5,
				sku		=> 'a:001',
				description	=> 'Some product',
				},
				{
				amount		=> 5.65,
				description	=> 'Shipping',
				taxes		=> 'GST PST',
				},
				{
				amount		=> 10.00,
				description	=> 'Some HST example',
				taxes		=> [ 'GST', 'PST' ],
				},
				],
	},
	{
		_test		=> 1,

		action		=> 'Normal Authorization',

		card_number	=> '5111-1111-1111-1111',
		expiration	=> '7/2004',

		name		=> "\x{201c}Fr\x{e9}d\x{e9}ric Bri\x{e8}re\x{201d}",

		amount		=> 12.95,
		description	=> "Box o' goodies",
		currency	=> 'USD',
		taxes		=> 'GST',
	},
	{
		_test		=> -1,

		action		=> 'Normal Authorization',

		card_number	=> '5111-1111-1111-1111',
		expiration	=> '0704',

		name		=> "Fr\x{e9}d\x{e9}ric Bri\x{e8}re",

		amount		=> 13.95,
	},
);


my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

foreach (TRANSACTIONS) {
	$txn->test_transaction(delete $_->{_test});
	$txn->content(%$_);

	my $data = do {
		# Work around bug #17687
		local $/ = '';
		scalar <DATA>;
	};

	is_deeply(
		xml_in($txn->to_xml),
		xml_in($data)
	);
}


__DATA__
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<TranxRequest>
  <MerchantNumber>0000</MerchantNumber>
  <xxxCard_Number>4111111111111111</xxxCard_Number>
  <xxxCCMonth>07</xxxCCMonth>
  <xxxCCYear>2004</xxxCCYear>
  <CVV2>000</CVV2>
  <CVV2Indicator>1</CVV2Indicator>
  <Products>9.99::5::a 001::Some product::{USD}{HST}|5.65::1::::Shipping::{USD}{GST}{PST}|10.00::1::::Some HST example::{USD}{GST}{PST}</Products>
  <xxxName>Frédéric Brière</xxxName>
  <xxxCompany></xxxCompany>
  <xxxAddress>123 Street</xxxAddress>
  <xxxCity>Metropolis</xxxCity>
  <xxxProvince>ZZ</xxxProvince>
  <xxxPostal>A1A 1A1</xxxPostal>
  <xxxCountry>CA</xxxCountry>
  <xxxPhone>(555) 555-1212</xxxPhone>
  <xxxEmail>fbriere@fbriere.net</xxxEmail>
  <xxxShippingName></xxxShippingName>
  <xxxShippingCompany></xxxShippingCompany>
  <xxxShippingAddress></xxxShippingAddress>
  <xxxShippingCity></xxxShippingCity>
  <xxxShippingProvince></xxxShippingProvince>
  <xxxShippingPostal></xxxShippingPostal>
  <xxxShippingCountry></xxxShippingCountry>
  <xxxShippingPhone></xxxShippingPhone>
  <xxxShippingEmail></xxxShippingEmail>
</TranxRequest>

<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<TranxRequest>
  <MerchantNumber>0000</MerchantNumber>
  <xxxCard_Number>5111111111111111</xxxCard_Number>
  <xxxCCMonth>07</xxxCCMonth>
  <xxxCCYear>2004</xxxCCYear>
  <CVV2></CVV2>
  <CVV2Indicator>0</CVV2Indicator>
  <Products>12.95::1::::Box o' goodies::{USD}{GST}{TEST}</Products>
  <xxxName>?Frédéric Brière?</xxxName>
  <xxxCompany></xxxCompany>
  <xxxAddress></xxxAddress>
  <xxxCity></xxxCity>
  <xxxProvince></xxxProvince>
  <xxxPostal></xxxPostal>
  <xxxCountry></xxxCountry>
  <xxxPhone></xxxPhone>
  <xxxEmail></xxxEmail>
  <xxxShippingName></xxxShippingName>
  <xxxShippingCompany></xxxShippingCompany>
  <xxxShippingAddress></xxxShippingAddress>
  <xxxShippingCity></xxxShippingCity>
  <xxxShippingProvince></xxxShippingProvince>
  <xxxShippingPostal></xxxShippingPostal>
  <xxxShippingCountry></xxxShippingCountry>
  <xxxShippingPhone></xxxShippingPhone>
  <xxxShippingEmail></xxxShippingEmail>
</TranxRequest>

<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<TranxRequest>
  <MerchantNumber>0000</MerchantNumber>
  <xxxCard_Number>5111111111111111</xxxCard_Number>
  <xxxCCMonth>07</xxxCCMonth>
  <xxxCCYear>2004</xxxCCYear>
  <CVV2></CVV2>
  <CVV2Indicator>0</CVV2Indicator>
  <Products>13.95::1::::::{CAD}{TESTD}</Products>
  <xxxName>Frédéric Brière</xxxName>
  <xxxCompany></xxxCompany>
  <xxxAddress></xxxAddress>
  <xxxCity></xxxCity>
  <xxxProvince></xxxProvince>
  <xxxPostal></xxxPostal>
  <xxxCountry></xxxCountry>
  <xxxPhone></xxxPhone>
  <xxxEmail></xxxEmail>
  <xxxShippingName></xxxShippingName>
  <xxxShippingCompany></xxxShippingCompany>
  <xxxShippingAddress></xxxShippingAddress>
  <xxxShippingCity></xxxShippingCity>
  <xxxShippingProvince></xxxShippingProvince>
  <xxxShippingPostal></xxxShippingPostal>
  <xxxShippingCountry></xxxShippingCountry>
  <xxxShippingPhone></xxxShippingPhone>
  <xxxShippingEmail></xxxShippingEmail>
</TranxRequest>

