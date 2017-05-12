BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("Cardcom", terminalnumber => 1000);

#$Business::OnlinePayment::Cardcom::DEBUG = 2;

$tx->content(
    type           => 'CC',
    login          => 'moot',
    password       => 'moot',
    action         => 'Normal Authorization',
    amount         => '0.80',
    currency       => 'CAD',
    card_number    => '4580000000000000',
    expiration     => '01/14',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    warn $tx->server_response."\n";
    warn $tx->error_message. "\n";
    print "not ok 1\n";
}

