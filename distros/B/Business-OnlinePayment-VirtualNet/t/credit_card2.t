BEGIN { $| = 1; print "1..2\n"; }

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

my $tx = new Business::OnlinePayment("VirtualNet",
    'merchant_id' => '888000002200',
    'store'       => '5999',
    'terminal'    => '1515',
    'mcc'         => '5999', #merchant category code
    'bin'         => '999995', #acquirer BIN
    #'bin'         => '999700', #acquirer BIN
    'zip'         => '543211420', #merchant zip (US) or assigned city code

    'agent'       => '000000', #agent bank
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
    #amount         => '10.00',
    amount         => '3.20',
    invoice_number => '100100',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    first_name     => 'Tofu',
    last_name      => 'Beast',
    address        => '8320 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84284',
#    card_number    => '4111111111111111',
#    expiration     => '09/03',
    card_number    => '5499740000000057',
    expiration     => '01/05',
#    card_number    => '6011000993026909',
#    expiration     => '01/04',

);
$tx->test_transaction(1); # test, dont really charge (doesn't do anything with VirtualNet)
$tx->submit();

if($tx->is_success()) {
    print "ok 1 (". $tx->authorization. ")\n";
    warn "(auth ok ". $tx->authorization. ")\n" if $DEBUG;
} else {
    warn "(auth) ** (". $tx->result_code. ') '. $tx->error_message. "**\n"
      if $DEBUG;
    print "not ok 1\n";
    exit;
}

$tx->content(
  type           => 'CC',
  action         => 'Post Authorization',
  #amount         => '10.00',
  amount         => '3.20',
#  card_number    => '4111111111111111',
#  expiration     => '09/03',
  card_number    => '5499740000000057',
  expiration     => '01/05',
#   card_number    => '6011000993026909',
#   expiration     => '01/04',

  authorization             => $tx->authorization,
  authorization_source_code => $tx->authorization_source_code,
  returned_ACI              => $tx->returned_ACI,
  transaction_identifier    => $tx->transaction_identifier,
  validation_code           => $tx->validation_code,
  transaction_sequence_num  => $tx->transaction_sequence_num,
  local_transaction_date    => $tx->local_transaction_date,
  local_transaction_time    => $tx->local_transaction_time,
  AVS_result_code           => $tx->AVS_result_code,
  #description    => 'Business::OnlinePayment::VirtualNet test',
);

$tx->submit();

if($tx->is_success()) { 
    print "ok 2\n";
} else {
    warn '(capture) ** ('.$tx->result_code.') '.  $tx->error_message. " **\n"
      if $DEBUG;
    print "not ok 2\n";
}

