BEGIN { $| = 1; print "1..1\n"; }

eval "use Net::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("eSelectPlus");

#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::HTTPS::DEBUG = 1;
$Business::OnlinePayment::eSelectPlus::DEBUG = 1;
$Business::OnlinePayment::eSelectPlus::DEBUG = 1;

$tx->content(
    type           => 'VISA',
    login          => 'moot',
    password       => 'moot',
    action         => 'Normal Authorization',
    amount         => '0.80',
    currency       => 'CAD',
    card_number    => '4242424242424242',
    expiration     => '01/12',
    invoice_number => '540',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();
    warn $tx->order_number."\n";

if ( $tx->order_number =~ /-540$/ ) {
    print "ok 1\n";
} else {
    warn $tx->order_number."\n";
    print "not ok 1\n";
}

