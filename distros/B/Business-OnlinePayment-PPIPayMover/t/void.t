BEGIN { $| = 1; print "1..2\n"; }

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
    description    => 'Business::OnlinePayment void test',
    amount         => '0.01',
    card_number    => '4445999922225',
    expiration     => '03/10',
    cvv2           => '999',
    name           => 'Tofu Beast',
    address        => '8320',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '85284',
    phone          => '415-420-5454',
    email          => 'ivan-ppipaymover-test@420.am',
    customer_id    => '5454',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    #warn $tx->server_response."\n";
    warn $tx->error_message. "\n";
    print "not ok 1\n";
}

my $v_tx = new Business::OnlinePayment("PPIPayMover");

$v_tx->content(
    type           => 'VISA',
    'login'        => '195325FCC230184964CAB3A8D93EEB31888C42C714E39CBBB2E541884485D04B', #token
    action         => 'Void',
    description    => 'Business::OnlinePayment::PPIPayMover test',
    customer_id    => '5454',
    order_number   => $tx->order_number(),
);

$v_tx->test_transaction(1); # test, dont really charge
$v_tx->submit();

if($v_tx->is_success()) {
    print "ok 2\n";
} else {
    #warn $v_tx->server_response."\n";
    warn $v_tx->error_message. "\n";
    print "not ok 2\n";
}




