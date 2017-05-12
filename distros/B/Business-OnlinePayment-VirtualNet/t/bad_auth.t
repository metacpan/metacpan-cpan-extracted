BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

$DEBUG = 0;
$Business::OnlinePayment::VirtualNet::DEBUG = $DEBUG;
$Business::OnlinePayment::VirtualNet::DEBUG += 0; #quiet warnings with old perl

#     Use this merchant information for testing only. 
#  
#     Bin= 999995 Agent = 000000 Chain = 111111 Merchant = 888000002200
# Store = 5999 Terminal = 1515
#      Mcc = 5999 .
#    If you are doing AVS (address Ver ) use this address  8320 zip 85284.

my $tx = new Business::OnlinePayment("VirtualNet",,
    'merchant_id' => '888000002200',
    'store'       => '5999',
    'terminal'    => '1515',
    'mcc'         => '5999', #merchant category code
    'bin'         => '999995', #acquirer BIN
    'zip'         => '543211420', #merchant zip (US) or assigned city code

    'agent'	  => '000000',
    'v'           => '00000001',

    'merchant_name'  => 'Internet Service Provider', #25 char max
    'merchant_city'  => 'Gloucester', #13 char max
    'merchant_state' => 'VA', #2 char

    'seq_file'    => '/tmp/bop-virtualnet-sequence',
    'batchnum_file' => '/tmp/bop-virtualnet-batchnum', # :/  0-999 in 5 days
);
$tx->content(
    type           => 'CC',
    action         => 'Authorization only',
    description    => 'Business::OnlinePayment visa test',
    amount         => '999910.00',
    invoice_number => '100100',
    customer_id    => 'jsk',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '8320 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '85284',
    card_number    => '4111111111111111',
    expiration     => '09/03',
);
$tx->test_transaction(1); # test, dont really charge (doesn't do anything with VirtualNet)
$tx->submit();

if($tx->is_success()) {
    print "not ok 1\n";
    warn '** ('. $tx->result_code. ') '. $tx->error_message. " **\n" if $DEBUG;
    warn $tx->error_message if $DEBUG;
} else {
    warn '** ('. $tx->result_code. ') '. $tx->error_message. " **\n" if $DEBUG;
    print "ok 1\n";
}
