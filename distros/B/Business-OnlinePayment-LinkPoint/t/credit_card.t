BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("LinkPoint",
  'storename' => '1909796604',
  'keyfile'   => './test.pem',
  'server'    => 'staging.linkpt.net',
);

$tx->content(
    type           => 'VISA',
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::LinkPoint visa test',
    amount         => '0.01',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',
    email          => 'ivan-linkpoint@420.am',
    card_number    => '4007000000027',
    expiration     => '12/2008',
);

$tx->test_transaction(1);

$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
    #$auth = $tx->authorization;
    #warn "********* $auth ***********\n";
} else {
    print "not ok 1\n";
    warn '***** '. $tx->error_message. " *****\n";
    exit;
}

