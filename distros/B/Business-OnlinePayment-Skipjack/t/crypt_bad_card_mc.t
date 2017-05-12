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

my $tx = new Business::OnlinePayment("Skipjack");

#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::HTTPS::DEBUG = 1;
#$Business::OnlinePayment::Skipjack::DEBUG = 1;
#$Business::OnlinePayment::Skipjack::DEBUG = 1;

my $login = $ENV{'sj_html_serial_number'} || '000792524556';
my $password = $ENV{'sj_devel_serial_number'} || '100025931874';

$tx->content(
    type           => 'VISA',
    login          => $login, # "HTML serial number"
    password       => $password, # "Developer serial number"
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::Skipjack test',
    amount         => '32',
    #card_number    => '5212345678901234',
    card_number    => '5222222222222222',
    expiration     => '03/10',
    name           => 'Tofu Beast',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    phone          => '415-420-5454',
    email          => 'ivan-skipjack-test@420.am',
);
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "not ok 1\n";
} else {
    #warn $tx->server_response."\n";
    #warn $tx->error_message. "\n";
    print "ok 1\n";
}

