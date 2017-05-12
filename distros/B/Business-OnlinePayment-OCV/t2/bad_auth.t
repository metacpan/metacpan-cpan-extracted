BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("OCV",
  account => '0',
  server  => 'localhost',
  port    => 3005,
);
$tx->content(
    type           => 'CC',
    login          => '10009', #ClientID
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '1.01',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => '4111111111111112',
    expiration     => '08/06',
);
$tx->test_transaction(1); # test, dont really charge (NOP for this gateway)
$tx->submit();

if($tx->is_success()) {
    print "not ok 1\n";
    warn $tx->error_message;
} else {
    print "ok 1\n";
}
