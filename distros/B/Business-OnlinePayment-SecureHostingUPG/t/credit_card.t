BEGIN { $| = 1; print "1..1\n"; }

eval "use Net::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("SecureHostingUPG");

#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::SecureHostingUPG::DEBUG = 1;
#$Business::OnlinePayment::SecureHostingUPG::DEBUG = 1;

$tx->content(
    type           => 'VISA',
    login          => 'SH207361', #SecureHosting Reference
    password       => '495376',   #SecureHosting Checkcode value
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '49.95',
    currency       => 'GBP',
    name           => 'Tofu Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    phone          => '420-543-2199',
    email          => 'tofu.beast@example.com',
    #card_number    => '4005550000000019',
    card_number    => '4242424242424242',
    expiration     => '01/06',
    card_start     => '05/04',
    cvv2           => '1234', #optional
    issue_number   => '5678',
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

