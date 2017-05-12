BEGIN { $| = 1; print "1..2\n"; }

#print "ok 1 # Skipped: Voids not working with test account\n";
#print "ok 2 # Skipped: Voids not working with test account\n";
#exit;

eval "use Net::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Net::SSLeay is not installed\n";
  print "ok 2 # Skipped: Net::SSLeay is not installed\n";
  exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("eSelectPlus", 'currency' => 'CAD' );

$tx->content(
    type           => 'VISA',
    login          => 'moot',
    password       => 'moot',
    action         => 'Normal Authorization',
    amount         => '0.80',
    currency       => 'CAD',
    card_number    => '4242424242424242',
    expiration     => '01/12',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    #warn "authorization:". $tx->authorization."\n";
    #warn "order_number: ". $tx->order_number."\n";

    print "ok 1\n";
} else {
    warn $tx->server_response."\n";
    warn $tx->error_message. "\n";
    print "not ok 1\n";
}

#--

my $void = new Business::OnlinePayment("eSelectPlus", 'currency' => 'CAD' );

$void->content(
    type           => 'VISA',
    login          => 'moot',
    password       => 'moot',
    action         => 'Void',
    currency       => 'CAD',
    authorization  => $tx->authorization,
    order_number   => $tx->order_number,
    amount         => '0.80', #not used, but shouldn't error out
);

#$VAR11 = 'amount';
#$VAR12 = '1.00';
#$VAR15 = 'type';
#$VAR16 = 'CC';
#$VAR17 = 'referer';
#$VAR18 = 'http://cleanwhisker.420.am/'; 

$void->test_transaction(1); # test, dont really charge
$void->submit();

if($void->is_success()) {
    print "ok 2\n";
} else {
    warn $void->server_response."\n";
    warn $void->error_message. "\n";
    print "not ok 2\n";
}

