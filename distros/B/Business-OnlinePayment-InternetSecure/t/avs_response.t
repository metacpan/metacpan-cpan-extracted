# vim:set syntax=perl:

use Test::More tests => 1 + 2;

BEGIN { use_ok('Business::OnlinePayment') };


my $txn = new Business::OnlinePayment 'InternetSecure', merchant_id => '0000';

$txn->parse_response(<<__EOF__);
<?xml version="1.0" encoding="UTF-8"?>
<TranxResponse>
  <CardType>Test Card Number</CardType>
  <Page>2000</Page>
  <AVSResponseCode>Z</AVSResponseCode>
</TranxResponse>
__EOF__

is($txn->avs_code, 'Z', 'avs_code');
is($txn->avs_response, 'Z', 'avs_response');


