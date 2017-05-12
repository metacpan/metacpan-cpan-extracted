BEGIN { $| = 1; print "1..1\n"; }

print "ok 1 # Skipped: need a valid iAuthorizer.net login/password/serial to test\n"; exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("iAuthorizer");
$tx->content('login'       => '...',            # login, password, and serial for your account
             'password'    => '...',
             'serial'      => '...',
             'action'      => 'Normal Authorization',
             'card_number' => '4012888888881',  # test card
             'expiration'  => '05/05',
             'amount'      => '1.00',
             'address'     => '123 Anystreet',
             'zip'         => '12345',
             'cvv2'        => '1234',
            );


$tx->test_transaction(1); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    #warn $tx->error_message;
    print "not ok 1\n";
}
