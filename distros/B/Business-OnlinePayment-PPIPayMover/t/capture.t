BEGIN { $| = 1; print "1..2\n"; }

#print "ok 1 # Skipped: no separate auth + capture test yet\n";
#print "ok 2 # Skipped: no separate auth + capture test yet\n";
#exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("PPIPayMover");
$tx->content(
    type           => 'VISA',
    'login'        => '195325FCC230184964CAB3A8D93EEB31888C42C714E39CBBB2E541884485D04B', #token
    action         => 'Authorization Only',
    description    => 'Business::OnlinePayment auth + capture test',
    amount         => '0.01',
    invoice_number => '100100',
    customer_id    => '5454',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => '4007000000027',
    expiration     => '08/06',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

unless($tx->is_success()) {
    print "not ok 1\n";
    print "not ok 2\n";
} else {
    my $order_number = $tx->order_number;
    #warn $order_number;
    print "ok 1\n";

    my $settle_tx = new Business::OnlinePayment("PPIPayMover");
    $settle_tx->content(
      type           => 'VISA',
    'login'        => '195325FCC230184964CAB3A8D93EEB31888C42C714E39CBBB2E541884485D04B', #token
      action         => 'Post Authorization',
      description    => 'Business::OnlinePayment auth + capture test',
      amount         => '0.01',
      invoice_number => '100100',
      order_number   => $order_number,
      card_number    => '4007000000027',
      expiration     => '08/06',
      customer_id    => '5454',
   );

    $settle_tx->test_transaction(1); # test, dont really charge
    $settle_tx->submit();

    if($settle_tx->is_success()) {
        print "ok 2\n";
    } else {
        warn $settle_tx->error_message;
        print "not ok 2\n";
    }

}
