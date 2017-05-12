BEGIN {
  $| = 1; print "1..1\n";
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
}

print "ok 1 # Skipped: testing account won't accept ACH transactions\n"; exit;

eval "use Crypt::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Crypt::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

# checks are broken it seems
my $ctx = new Business::OnlinePayment("OpenECHO",
  payee          => 'Tofu Heavy Enterprises, GmbH',
);
$ctx->content(
    type           => 'ECHECK',
    'login'        => '123>4685706',
    'password'     => '09437869',
    action         => 'Normal Authorization',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    account_number => '12345',
    routing_code   => '026009593',
    bank_name      => 'First National Test Bank',
    phone          => '420-420-5454',
    #payee          => 'Tofu Heavy Enterprises, GmbH',
    check_number   => '420',
);
$ctx->test_transaction(1); # test, dont really charge
$ctx->submit();

print $ctx->is_success()."\n";

if($ctx->is_success()) {
    #warn $ctx->error_message();
    print "not ok 1 (".$ctx->error_message().")\n";
} else {
    print "ok 1\n";
}
