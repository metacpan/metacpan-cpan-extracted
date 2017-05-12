BEGIN { $| = 1; print "1..2\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("BankOfAmerica", 'merchant_id' => 'YOURMERCHANTID' );
$tx->content(
    type           => 'VISA',
    action         => 'Authorization Only',
    description    => 'Business::OnlinePayment::BankOfAmerica visa test',
    amount         => '0.01',
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
    card_number    => '4007000000027',
    expiration     => '12/2002',
    referer        => 'http://cleanwhisker.420.am/',
);
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
    $auth = $tx->authorization;
    $ordernum = $tx->order_number;
    #warn "********* $auth ***********\n";
    #warn "********* $ordernum ***********\n";
} else {
    print "not ok 1\n";
#    warn '***** '. $tx->error_message. " *****\n";
    exit;
}

#exit;
my $capture = new Business::OnlinePayment("BankOfAmerica", 'merchant_id' => 'YOURMERCHANTID' );

$capture->content(
    action         => 'Post Authorization',
    login          => 'YOURLOGIN
    password       => 'YOURPASSWORD',
    order_number   => $ordernum,
    amount         => '0.01',
    authorization  => $auth,
    description    => 'Business::OnlinePayment::BankOfAmerica visa test',
);

$capture->submit();

if($capture->is_success()) { 
    print "ok 2\n";
} else {
#    warn '***** '. $capture->error_message. " *****\n";
    print "not ok 2\n";
}


