#BEGIN { $| = 1; print "1..1\n"; }
use Test::More tests => 1;

SKIP: {
  skip "test account no longer available", 1;

use Business::OnlinePayment;

my $ctx = new Business::OnlinePayment("PaymentsGateway");
$ctx->content(
    type           => 'CHECK',
    login          => '2000',
    password       => 'merchant4demo',
    action         => 'Normal Authorization',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    account_number => '12345',
    routing_code   => '321076441',
    bank_name      => 'First National Test Bank',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

print $ctx->is_success()."\n";

if($ctx->is_success()) {
    print "ok 1\n";
} else {
    warn $ctx->result_code. ': '. $ctx->error_message();
    print "not ok 1 (".$ctx->error_message().")\n";
}

}
