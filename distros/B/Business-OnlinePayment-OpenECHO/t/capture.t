BEGIN { $| = 1; print "1..2\n"; }

print "ok 1 # Skipped: no separate auth + capture test yet\n";
print "ok 2 # Skipped: no separate auth + capture test yet\n";
exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("OpenECHO");
$tx->content(
    type           => 'VISA',
    login          => 'testing',# CHANGE THESE TO TEST
    password       => 'testing',#
    action         => 'Authorization Only',
    description    => 'Business::OnlinePayment visa test',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
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
    warn $order_number;
    print "ok 1\n";

    my $settle_tx = new Business::OnlinePayment("OpenECHO");
    $settle_tx->content(
      type           => 'VISA',
      login          => 'testing', # CHANGE THESE TO TEST
      password       => 'testing', #
      action         => 'Post Authorization',
      description    => 'Business::OnlinePayment visa test',
      amount         => '49.95',
      invoice_number => '100100',
      order_number   => '111',
      card_number    => '4007000000027',
      expiration     => '08/06',
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
