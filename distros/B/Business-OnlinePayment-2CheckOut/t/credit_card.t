BEGIN { $| = 1; print "1..1\n"; }

#testing/testing is valid and seems to work...
#print "ok 1 # Skipped: need a valid Authorize.Net login/password to test\n"; exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("2CheckOut");
$tx->content(
    login          => '124',
    amount         => '23.00',
    order_number   => '100100',
    first_name     => 'Jason',
    last_name      => 'Kohles',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '99999',
    country        => 'USA',
    phone          => '555-55-55',
    email          => 'whoever@anywhere.com',
    card_number    => '4007000000027',
    expiration     => '09/02',
    cvv2           => '123',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    #warn $tx->error_message;
    print "not ok 1\n";
}
