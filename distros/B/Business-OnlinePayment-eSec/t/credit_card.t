BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("eSec");
$tx->content(
    type           => 'CC',
    login          => 'test', #EPS_MERCHANT
    action         => 'Authorization only',
    description    => 'Business::OnlinePayment visa test',
    amount         => '49.95',
    invoice_number => '100100',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    card_number    => 'testsuccess',
    expiration     => '08/06',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    warn "*******". $tx->error_message. "*******";
    print "not ok 1\n";
}
