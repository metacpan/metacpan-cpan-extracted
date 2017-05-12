BEGIN { $| = 1; print "1..1\n"; }

#print "ok 1 # Skipped: testing account won't accept ACH transactions\n"; exit;

#eval "use Net::SSLeay;";
#if ( $@ ) {
#  print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
#}

use Business::OnlinePayment;

require "t/lib/test_account.pl";
my($login, $regkey) = test_account_or_skip();

my $ctx = new Business::OnlinePayment("TransactionCentral");

$ctx->content(
    type           => 'ECHECK',
    login          => $login,
    password       => $regkey,
    action         => 'Normal Authorization',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    account_number => '12345',
    #routing_code   => '026009593',
    routing_code   => 'bad_routing_code',
    bank_name      => 'First National Test Bank',
    phone          => '420-420-5454',
    #payee          => 'Tofu Heavy Enterprises, GmbH',
    check_number   => '420',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

#print $ctx->is_success()."\n";

if($ctx->is_success()) {
    #warn $ctx->error_message();
    print "not ok 1 (".$ctx->error_message().")\n";
} else {
    print "ok 1\n";
}
