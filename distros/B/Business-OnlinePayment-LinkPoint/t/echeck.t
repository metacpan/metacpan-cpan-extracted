BEGIN { $| = 1; print "1..1\n"; }

$no_echeck_tests =
  "Skipped: Linkpoint doesn't provide a way to test echecks\n";
warn $no_echeck_tests;
print "ok 1 # $no_echeck_tests";
exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("LinkPoint",
  'storename' => '1909796604',
  'keyfile'   => './test.pem',
  'server'    => 'staging.linkpt.net',
);

$tx->content(
    type           => 'ECHECK',
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::LinkPoint echeck test',
    amount         => '0.01',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',
    email          => 'ivan-linkpoint@420.am',
    account_number => '0027',
    account_type   => 'Personal Checking',
    routing_code   => '400700000',
    bank_name      => 'SomeBank',
    bank_state     => 'UT',
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

