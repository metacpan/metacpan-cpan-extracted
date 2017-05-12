BEGIN { $| = 1; print "1..1\n"; }

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
    #account_number => 'badaccountnumber',
    routing_code   => '123456789',
    #routing_code   => 'badroutingcode',
    bank_name      => 'First National Test Bank',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

print $ctx->is_success()."\n";

if($ctx->is_success()) {
    print "not ok 1\n";
} else {
    #warn $ctx->error_message();
    print "ok 1\n";
}
