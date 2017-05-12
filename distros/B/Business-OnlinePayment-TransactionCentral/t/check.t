BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

require "t/lib/test_account.pl";
my($login, $regkey) = test_account_or_skip();

my $ctx = Business::OnlinePayment->new("TransactionCentral");

#$Business::OnlinePayment::TransactionCentral::DEBUG = 1;
#$Business::OnlinePayment::TransactionCentral::DEBUG = 1;

$ctx->content(
    type           => 'CHECK',
    login          => $login,
    password       => $regkey,
    action         => 'Normal Authorization',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    account_number => '12345',
    routing_code   => '111000025',  # BoA in Texas taken from Wikipedia
    bank_name      => 'First National Test Bank',
    account_type   => 'Checking',
    license_num    => '12345678',
    license_state  => 'OR',
    license_dob    => '1975-05-21',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

if($ctx->is_success()) {
    print "ok 1\n";
} else {
    warn "error message : ". $ctx->error_message(). "\n";
    warn "response code : ". $ctx->response_code(). "\n";
    warn "response page : ". $ctx->response_page(). "\n";

    print "not ok 1 (".$ctx->error_message().")\n";
}
