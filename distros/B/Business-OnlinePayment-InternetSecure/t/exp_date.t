# vim:set syntax=perl encoding=utf-8:

# Check for backwards-compatible support for exp_date

use Test::More tests => 2 + 1;

BEGIN { use_ok('Business::OnlinePayment') };
BEGIN { use_ok('XML::Simple', qw(xml_in)) };

my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

$txn->content(
		action		=> 'Normal Authorization',

		card_number	=> '5111-1111-1111-1111',
		exp_date	=> '0704',

		amount		=> 13.95,
	);

is_deeply( xml_in($txn->to_xml), xml_in(<<__EOF__) );
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<TranxRequest>
  <MerchantNumber>0000</MerchantNumber>
  <xxxCard_Number>5111111111111111</xxxCard_Number>
  <xxxCCMonth>07</xxxCCMonth>
  <xxxCCYear>2004</xxxCCYear>
  <CVV2></CVV2>
  <CVV2Indicator>0</CVV2Indicator>
  <Products>13.95::1::::::{CAD}</Products>
  <xxxName></xxxName>
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

__EOF__

