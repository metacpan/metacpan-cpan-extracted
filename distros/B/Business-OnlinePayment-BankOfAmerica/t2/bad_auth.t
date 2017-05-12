BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("BankOfAmerica", 'merchant_id' => 'YOURMERCHANTID' );
$tx->content(
    type           => 'VISA',
    action         => 'Authorization Only',
    description    => 'Business::OnlinePayment::BankOfAmerica visa test',
    amount         => '49.95',
    invoice_number => '100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',
    email          => 'ivan-bofa@420.am',
#    card_number    => '4007000000027',
    expiration     => '08/2004',
    referer        => 'http://cleanwhisker.420.am/',
);
$tx->submit();

if($tx->is_success()) {
    print "not ok 1\n";
} else {
#    warn '***** '. $tx->error_message. " *****\n";
    print "ok 1\n";
}
