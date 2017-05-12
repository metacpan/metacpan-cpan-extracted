BEGIN { $| = 1; print "1..1\n"; }

eval "use Net::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("PPIPayMover");
$tx->content(
    type           => 'VISA',
    'login'        => '195325FCC230184964CAB3A8D93EEB31888C42C714E39CBBB2E541884485D04B', #token
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '0.10',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    phone          => '420-543-2199',
    card_number    => '4007000000027',
    expiration     => '08/09',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "not ok 1\n";
} else {
    #warn $tx->server_response."\n";
    #warn $tx->error_message. "\n";
    print "ok 1\n";
}
