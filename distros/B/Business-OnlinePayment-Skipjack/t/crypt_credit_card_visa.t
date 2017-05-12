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

my $login = $ENV{'sj_html_serial_number'} || '000843232776';
my $password = $ENV{'sj_devel_serial_number'} || '100025931874';

$tx->content(
    type           => 'VISA',
    login          => $login, # "HTML serial number"
    password       => $password, # "Developer serial number"
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment::Skipjack test',
    amount         => '32',
    card_number    => '4445999922225',
    expiration     => '03/10',
    cvv2           => '999',
    name           => 'Tofu Beast',
    address        => '8320',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '85284',
    phone          => '415-420-5454',
    email          => 'ivan-skipjack-test@420.am',
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

