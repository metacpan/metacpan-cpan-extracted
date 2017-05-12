# vim:set syntax=perl:

use constant FIELDS => qw(
			result_code authorization error_message
			receipt_number order_number
			date
			card_type
			avs_code cvv2_response
			total_amount tax_amounts
			);

use constant RESULTS => (
				{
					is_success	=> 1,
					result_code	=> '2000',
					authorization	=> 'T00000',
					error_message	=> undef,
					receipt_number	=> '1096019995.5012',
					order_number	=> 0,
					date		=> '2003/12/17 09:59:58',
					card_type	=> undef,
					avs_code	=> undef,
					cvv2_response	=> undef,
					total_amount	=> 3.88,
					tax_amounts	=> { GST => 0.25 },
					uuid		=> 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
					guid		=> 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
				},
				{
					is_success	=> 0,
					result_code	=> '98e05',
					authorization	=> undef,
					error_message	=> 'Real error message',
					receipt_number	=> '1096021915.5853',
					order_number	=> 729,
					date		=> '2003/12/17 10:31:58',
					card_type	=> 'Visa',
					avs_code	=> undef,
					cvv2_response	=> undef,
					total_amount	=> 3.88,
					tax_amounts	=> { GST => 0.25,
								PST => 0.27 },
					uuid		=> undef,
					guid		=> undef,
				},
			);


use Test::More tests => 1 + scalar(RESULTS) * (1 + 1 + scalar(FIELDS));

BEGIN { use_ok('Business::OnlinePayment') };



my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

$/ = '';
foreach my $results (RESULTS) {
	my $xml = <DATA>;
	$txn->parse_response($xml);

	is($txn->server_response, $xml, 'server_response');

	if ($results->{is_success}) {
		ok($txn->is_success, 'expecting success');
	} else {
		ok(!$txn->is_success, 'expecting failure');
	}

	foreach (FIELDS) {
		no strict 'refs';
		is_deeply($txn->$_, $results->{$_}, $_);
	}
}


__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<TranxResponse>
  <MerchantNumber>4994</MerchantNumber>
  <ReceiptNumber>1096019995.5012</ReceiptNumber>
  <SalesOrderNumber>0</SalesOrderNumber>
  <xxxName>John Smith</xxxName>
  <Date>2003/12/17 09:59:58</Date>
  <CardType>Test Card Number</CardType>
  <Page>2000</Page>
  <ApprovalCode>T00000</ApprovalCode>
  <Verbiage>Test Approved</Verbiage>
  <TotalAmount>3.88</TotalAmount>
  <Products>
    <product>
      <code>001</code>
      <description>Test Product 1</description>
      <quantity>1</quantity>
      <price>3.10</price>
      <subtotal>3.10</subtotal>
      <flags>
        <flag>{USD}</flag>
	<flag>{GST}</flag>
	<flag>{TEST}</flag>
      </flags>
    </product>
    <product>
      <code>010</code>
      <description>Test Product 2</description>
      <quantity>1</quantity>
      <price>0.20</price>
      <subtotal>0.20</subtotal>
      <flags>
	<flag>{GST}</flag>
	<flag>{TEST}</flag>
      </flags>
    </product>
    <product>
      <code>020</code>
      <description>Test Product 3</description>
      <quantity>1</quantity>
      <price>0.33</price>
      <subtotal>0.33</subtotal>
      <flags>
	<flag>{GST}</flag>
	<flag>{TEST}</flag>
      </flags>
    </product>
    <product>
      <code>GST</code>
      <description>Canadian GST Charged</description>
      <quantity>1</quantity>
      <price>0.25</price>
      <subtotal>0.25</subtotal>
      <flags>
        <flag>{TAX}</flag>
	<flag>{CALCULATED}</flag>
      </flags>
    </product>
  </Products>
  <DoubleColonProducts>3.10::1::001::Test Product 1::{USD}{GST}{TEST}|0.20::1::010::Test Product 2::{GST}{TEST}|0.33::1::020::Test Product 3::{GST}{TEST}|0.25::1::GST::Canadian GST Charged::{TAX}{CALCULATED}</DoubleColonProducts>
  <AVSResponseCode />
  <CVV2ResponseCode />
  <GUID>f81d4fae-7dec-11d0-a765-00a0c91e6bf6</GUID>
</TranxResponse>

<?xml version="1.0" encoding="UTF-8"?>
<TranxResponse>
  <MerchantNumber>4994</MerchantNumber>
  <ReceiptNumber>1096021915.5853</ReceiptNumber>
  <SalesOrderNumber>729</SalesOrderNumber>
  <xxxName>John Smith</xxxName>
  <Date>2003/12/17 10:31:58</Date>
  <CardType>VI</CardType>
  <Page>98e05</Page>
  <ApprovalCode />
  <Verbiage>Incorrect Card Number - Please Retry</Verbiage>
  <Error>Real error message</Error>
  <TotalAmount>3.88</TotalAmount>
  <Products>
    <product>
      <code>001</code>
      <description>Test Product 1</description>
      <quantity>1</quantity>
      <price>3.10</price>
      <subtotal>3.10</subtotal>
      <flags>
        <flag>{USD}</flag>
	<flag>{GST}</flag>
	<flag>{PST}</flag>
      </flags>
    </product>
    <product>
      <code>010</code>
      <description>Test Product 2</description>
      <quantity>1</quantity>
      <price>0.20</price>
      <subtotal>0.20</subtotal>
      <flags>
	<flag>{GST}</flag>
	<flag>{PST}</flag>
      </flags>
    </product>
    <product>
      <code>020</code>
      <description>Test Product 3</description>
      <quantity>1</quantity>
      <price>0.33</price>
      <subtotal>0.33</subtotal>
      <flags>
	<flag>{GST}</flag>
	<flag>{PST}</flag>
      </flags>
    </product>
    <product>
      <code>GST</code>
      <description>Canadian GST Charged</description>
      <quantity>1</quantity>
      <price>0.25</price>
      <subtotal>0.25</subtotal>
      <flags>
        <flag>{TAX}</flag>
	<flag>{CALCULATED}</flag>
      </flags>
    </product>
    <product>
      <code>PST</code>
      <description>PST Charged</description>
      <quantity>1</quantity>
      <price>0.27</price>
      <subtotal>0.27</subtotal>
      <flags>
        <flag>{TAX}</flag>
	<flag>{CALCULATED}</flag>
      </flags>
    </product>
  </Products>
  <DoubleColonProducts>3.10::1::001::Test Product 1::{USD}{GST}{PST}|0.20::1::010::Test Product 2::{GST}{PST}|0.33::1::020::Test Product 3::{GST}{PST}|0.25::1::GST::Canadian GST Charged::{TAX}{CALCULATED}|0.27::1::PST::PST Charged::{TAX}{CALCULATED}</DoubleColonProducts>
  <AVSResponseCode />
  <CVV2ResponseCode />
</TranxResponse>

