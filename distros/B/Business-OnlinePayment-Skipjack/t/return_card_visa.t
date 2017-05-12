BEGIN { $| = 1; print "1..4\n"; }

eval "use Net::SSLeay;";
if ( $@ ) {
  print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
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

# -------

my $pa_tx = new Business::OnlinePayment("Skipjack");

$pa_tx->content(
    type  => 'VISA',
    login          => $login, # "HTML serial number"
    password       => $password, # "Developer serial number"
    action         => 'Post Authorization',
    description    => 'Business::OnlinePayment::Skipjack test',
    order_number   => $tx->order_number(),
);

$pa_tx->test_transaction(1); #test
$pa_tx->submit();

if($pa_tx->is_success()) {
    print "ok 2\n";

#  warn "STATUS : ". $st_tx->status(). "\n";
#  warn "PENDING: ". $st_tx->pending_status(). "\n";

} else {
    #warn $pa_tx->server_response."\n";
    warn $pa_tx->error_message. "\n";
    print "not ok 2\n";
}

# -------

my $st_tx = new Business::OnlinePayment("Skipjack");

$st_tx->content(
    type  => 'VISA',
    login          => $login, # "HTML serial number"
    password       => $password, # "Developer serial number"
    action         => 'Status',
    description    => 'Business::OnlinePayment::Skipjack test',
    order_number   => $tx->order_number(),
);

$st_tx->test_transaction(1); #test
$st_tx->submit();

if($st_tx->is_success()) {
    print "ok 3\n";

  #warn "STATUS : ". $st_tx->status(). "\n";
  #warn "PENDING: ". $st_tx->pending_status(). "\n";

} else {
    #warn $st_tx->server_response."\n";
    warn $st_tx->error_message. "\n";
    print "not ok 3\n";
}

# -------

print "ok 4 # Skipped: Credit needs a settled transaction\n"; exit;

my $cr_tx = new Business::OnlinePayment("Skipjack");

$cr_tx->content(
    type           => 'VISA',
    login          => $login, # "HTML serial number"
    password       => $password, # "Developer serial number"
    action         => 'Credit',
    description    => 'Business::OnlinePayment::Skipjack test',
    amount         => 11,
    order_number   => $tx->order_number(),
);

$cr_tx->test_transaction(1); # test, dont really charge
$cr_tx->submit();

if($cr_tx->is_success()) {
    print "ok 4\n";
} else {
    #warn $cr_tx->server_response."\n";
    warn $cr_tx->error_message. "\n";
    print "not ok 4\n";
}




