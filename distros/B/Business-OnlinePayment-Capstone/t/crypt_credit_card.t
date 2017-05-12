BEGIN {
  $| = 1; print "1..1\n";
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
}

eval "use Crypt::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Crypt::SSLeay is not installed\n"; exit;
}

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("Capstone");

#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::Capstone::DEBUG = 1;
#$Business::OnlinePayment::Capstone::DEBUG = 1;

$tx->content(
    type           => 'VISA',
    login          => '10217',
    password       => 'testing',
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::Capstone test',
    amount         => '54.01',
    card_number    => '4111111111111111',
    expiration     => '08/06',
    cvv2           => '420',
    name           => 'Tofu Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',
    email          => 'ivan-capstone-test@420.am',
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

