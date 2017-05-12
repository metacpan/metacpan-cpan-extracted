# vim:set syntax=perl:

use Test::More tests => 1 + 2;

BEGIN { use_ok('Business::OnlinePayment') };


my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

$txn->parse_response(<<__EOF__);
<?xml version="1.0" encoding="UTF-8"?>
<TranxResponse>
  <CardType>Test Card Number</CardType>
  <Page>2000</Page>
  <SalesOrderNumber>42</SalesOrderNumber>
</TranxResponse>
__EOF__

is($txn->order_number, 42, 'order_number');
is($txn->sales_number, 42, 'sales_number');


