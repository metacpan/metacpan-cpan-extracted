BEGIN {
  $| = 1; print "1..1\n";
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
}

eval "use Crypt::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Crypt::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("eSelectPlus");

$tx->content(
    type           => 'VISA',
    login          => 'moot',
    password       => 'moot',
    action         => 'Normal Authorization',
    amount         => '0.54',
    currency       => 'CAD',
    card_number    => '4242424242424242',
    expiration     => '08/00',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

# warn $tx->server_response."\n";
# warn $tx->error_message. "\n";
if($tx->is_success()) {
    print "not ok 1\n";
} else {
    print "ok 1\n";
}

