#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw(no_plan);
use Data::Dumper;
## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my $FTP_LOGIN =  $ENV{'FTP_LOGIN'} ? $ENV{'FTP_LOGIN'} : 'TESTMERCHANT';
my $FTP_PASS = $ENV{'FTP_PASS'} ? $ENV{'FTP_PASS'} : 'TESTMERCHANT';

my @opts = ('default_Origin' => 'RECURRING');

my $str = do { local $/ = undef; <DATA> };
my $data;
eval($str); ## no critic

my $authed = 
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID};

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3, !$authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'MerchantID');
}

my %orig_content = (
    login          => $login,
    password       => $password,
    merchantid     => $merchantid,
    action         => 'Account Update',
);

use_ok 'Business::OnlinePayment::Litle::UpdaterResponse';
my $update = Business::OnlinePayment::Litle::UpdaterResponse->new({
    litleTxnId   => 'fake_txn_id',
    orderId      => '123',
    responseTime => '',
    response     => '500',
    message      => 'test',
    customerId   => '456',
    reportGroup  => 'BOP',
    originalCard => {
                number => '4111111111111111',
                type    => 'VISA',
                expDate => '1212',
    },
    updatedCard  => {
                number  => '4007000000027',
                type    => 'VISA',
                expDate => '1220',
    },
});
isa_ok($update, 'Business::OnlinePayment::Litle::UpdaterResponse') or die 'Cannot new Business::OnlinePayment::Litle::UpdaterResponse';
cmp_ok($update->new_cardnum, 'eq', '4007000000027', 'new_cardnum exists');
cmp_ok($update->old_cardnum, 'eq', '4111111111111111', 'old_cardnum exists');

my $batch_id = time;
SKIP: {
    skip "No Test Account setup",1 if ! $authed;
### Litle Updater Tests
    print '-'x70;
    print "Updater SFTP TESTS\n";
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    foreach my $account ( @{$data->{'updater_request'}} ){
        my %content = %orig_content;
        $content{'type'} = $account->{'card'};
        $content{'card_number'} = $account->{'account'};
        $content{'expiration'} = $account->{'expdate'};
        $content{'customer_id'} = $account->{'id'};
        $content{'invoice_number'} = $account->{'id'};
        ## get the response validation set for this order
        
        $tx->add_item(\%content);

    }
    $tx->test_transaction(1);
    $tx->create_batch( 
        method     => 'sftp',
        login      => $login,
        password   => $password,
        merchantid => $merchantid,
        batch_id   => $batch_id,
        ftp_username => $FTP_LOGIN,
        ftp_password => $FTP_PASS,
    );
    is( $tx->is_success, 1, "Batch Completed Correctly" );
}

diag("HTTPS POST");
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
### Litle Updater Tests
    print '-'x70;
    print "Updater TESTS\n";
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    foreach my $account ( @{$data->{'updater_request'}} ){
        my %content = %orig_content;
        $content{'type'} = $account->{'card'};
        $content{'card_number'} = $account->{'account'};
        $content{'expiration'} = $account->{'expdate'};
        $content{'customer_id'} = $account->{'id'};
        $content{'invoice_number'} = $account->{'id'};
        ## get the response validation set for this order
        
        $tx->add_item(\%content);

    }
    $tx->test_transaction(1);
    $tx->create_batch( 
        method     => 'https',
        login      => $login,
        password   => $password,
        merchantid => $merchantid,
        batch_id   => $batch_id,
    );
    is( $tx->is_success, 1, "Batch Completed Correctly" );

    foreach my $resp ( @{ $tx->get_update_response } ) {
        my ($resp_validation) = grep { $_->{'id'} ==  $resp->invoice_number } @{ $data->{'updater_response'} };
        tx_check(
            $resp,
            desc        => 'Updater check',
            is_success  => $resp_validation->{'message'} eq 'Approved' ? 1 : 0,
            result_code   => $resp_validation->{'code'},
            error_message => $resp_validation->{'message'},
        );
    }

}
diag("HTTPS RFR");
## HTTPS RFR
SKIP: {
    skip "No Test Account setup",2 if ! $authed;
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction(1);
    eval{
     $tx->send_rfr({
         login =>  $login,
         password   => $password,
         merchantid => $merchantid,
         date  => '2010-04-15',
     });
     is( $tx->is_success, 0, "Correctly not finished");
     is( $tx->error_message, "The account update file is not ready yet.  Please try again later.", "Correct delay message");
    };

}
diag("Batch Response");
SKIP: {
    skip "No Test Account setup",21 if ! $authed;
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    diag $batch_id;
    my $result = $tx->retrieve_batch(
        batch_return => $data->{'updater_batch'},
        batch_id   => $batch_id,
    );
    foreach my $resp ( @{ $result->{'account_update'} } ) {
        my ($resp_validation) = grep { $_->{'id'} ==  $resp->invoice_number } @{ $data->{'final_response'} };
        tx_check(
            $resp,
            desc        => 'Batch Response check',
            is_success  => $resp_validation->{'message'} eq 'Approved' ? 1 : 0,
            result_code   => $resp_validation->{'code'},
            error_message => $resp_validation->{'message'},
        );
    }
}

diag("Waiting for Batch processing");
SKIP: {
    skip "No Test Account setup",30 if ! $authed;
    ok( sleep(90), "Wait for processing");
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    diag $batch_id;
    my $result = $tx->retrieve_batch(
        method     => 'sftp',
        batch_id   => $batch_id,
        ftp_username => $FTP_LOGIN,
        ftp_password => $FTP_PASS,
    );
    foreach my $resp ( @{ $result->{'account_update'} } ) {
        my ($resp_validation) = grep { $_->{'id'} ==  $resp->invoice_number } @{ $data->{'updater_response'} };
        tx_check(
            $resp,
            desc        => 'Updater check',
            is_success  => $resp_validation->{'message'} eq 'Approved' ? 1 : 0,
            result_code   => $resp_validation->{'code'},
            error_message => $resp_validation->{'message'},
        );
    }
}


#-----------------------------------------------------------------------------------
#
sub tx_check {
    my $tx = shift;
    my %o  = @_;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
    if( $o{authorization} ){
        is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    }
    if( $o{avs_code} ){
        is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    }
    if( $o{cvv2_response} ){
        is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    }
    like( $tx->order_number, qr/^\w{5,19}/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " error_message(", $tx->error_message, ")",
            " result_code(",   $tx->result_code,   ")",
            " invoice_number(",   $tx->invoice_number ,   ")",
        )
    );
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d%02d", $month, $year);
}

__DATA__
$data= {
'updater_request' => [
  { id  =>  1,
    account => '4457010000000009',
    expdate => '0912',
    card  =>  'VI',
  },
  { id  =>  2,
    account => '4457003100000003',
    expdate => '0505',
    card  =>  'VI',
  },
  { id  =>  3,
    account => '4457000300000007',
    expdate => '0107',
    card  =>  'VI',
  },
  { id  =>  4,
    account => '4457000400000006',
    expdate => '0000',
    card  =>  'VI',
  },
  { id  =>  5,
    account => '4457000200400008',
    expdate => '0210',
    card  =>  'VI',
  },
  { id  =>  6,
    account => '5112010000000003',
    expdate => '0205',
    card  =>  'MC',
  },
  { id  =>  7,
    account => '5112002200000008',
    expdate => '0912',
    card  =>  'MC',
  },
  { id  =>  8,
    account => '5112000200000002',
    expdate => '0508',
    card  =>  'MC',
  },
  { id  =>  9,
    account => '5112002100000009',
    expdate => '0000',
    card  =>  'MC',
  },
  { id  =>  10,
    account => '5112000400400018',
    expdate => '0210',
    card  =>  'MC',
  },
],

'updater_response' => [
 { id =>  1,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  2,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  3,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  4,
   type => 'VI',
   code =>  '320',
   message => 'Invalid Expiration Date',
 },
 { id =>  5,
   type => 'VI',
   code =>  '301',
   message => 'Invalid Account Number',
 },
 { id =>  6,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  7,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  8,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  9,
   type => 'VI',
   code =>  '320',
   message => 'Invalid Expiration Date',
 },
 { id =>  10,
   type => 'VI',
   code =>  '301',
   message => 'Invalid Account Number',
 },
 ],
 'final_response' => [
 { id =>  1,
   type => 'VI',
   code =>  '506',
   message => 'No changes found',
 },
 { id =>  2,
   type => 'VI',
   code =>  '502',
   message => 'The expiration date was changed',
 },
 { id =>  3,
   type => 'VI',
   code =>  '501',
   message => 'The account was closed',
 },
 { id =>  6,
   type => 'MC',
   code =>  '500',
   message => 'The account number was changed',
 },
 { id =>  7,
   type => 'MC',
   code =>  '503',
   message => 'The issuing bank does not participate in the update program.',
 },
 { id =>  8,
   type => 'MC',
   code =>  '504',
   message => 'Contact the cardholder for updated information',
 },
 { id =>  10,
   type => 'VI',
   code =>  '503',
   message => 'The issuing bank does not participate in the update program.',
 },
 
 ],
'updater_batch' => '
<litleResponse version="3.0" xmlns="http://www.litle.com/schema" response="0" message="Merchant Fiscal Day: 04052010" litleSessionId="27519289618">
<batchResponse litleBatchId="27519289717" merchantId="050800">
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="1"     customerId="1">
<litleTxnId>27200079920000</litleTxnId>
<orderId>1</orderId>
<response>506</response>
<message>No changes found</message>
<originalCard>
<type>VISA</type>
<number>4457010000000009</number>
<expDate>0912</expDate>
</originalCard>
<updatedCard>
<type>N/A</type>
<number>N/A</number>
<expDate>N/A</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="2"     customerId="2">
<litleTxnId>27200079920109</litleTxnId>
<orderId>2</orderId>
<response>502</response>
<message>The expiration date was changed</message>
<originalCard>
<type>VISA</type>
<number>4457003100000003</number>
<expDate>0505</expDate>
</originalCard>
<updatedCard>
<type>VISA</type>
<number>4457003100000003</number>
<expDate>0210</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="3"     customerId="3">
<litleTxnId>27200079920208</litleTxnId>
<orderId>3</orderId>
<response>501</response>
<message>The account was closed</message>
<originalCard>
<type>VISA</type>
<number>4457000300000007</number>
<expDate>0107</expDate>
</originalCard>
<updatedCard>
<type>N/A</type>
<number>N/A</number>
<expDate>N/A</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="6"     customerId="6">
<litleTxnId>27200079920505</litleTxnId>
<orderId>6</orderId>
<response>500</response>
<message>The account number was changed</message>
<originalCard>
<type>MasterCard</type>
<number>5112010000000003</number>
<expDate>0205</expDate>
</originalCard>
<updatedCard>
<type>MasterCard</type>
<number>5112010000000999</number>
<expDate>0212</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="7"     customerId="7">
<litleTxnId>27200079920604</litleTxnId>
<orderId>7</orderId>
<response>503</response>
<message>The issuing bank does not participate in the update program.</message>
<originalCard>
<type>MasterCard</type>
<number>5112002200000008</number>
<expDate>0912</expDate>
</originalCard>
<updatedCard>
<type>N/A</type>
<number>N/A</number>
<expDate>N/A</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="8"     customerId="8">
<litleTxnId>27200079920703</litleTxnId>
<orderId>8</orderId>
<response>504</response>
<message>Contact the cardholder for updated information</message>
<originalCard>
<type>MasterCard</type>
<number>5112000200000002</number>
<expDate>0508</expDate>
</originalCard>
<updatedCard>
<type>N/A</type>
<number>N/A</number>
<expDate>N/A</expDate>
</updatedCard>
</accountUpdateResponse>
<accountUpdateResponse reportGroup="YourCompany_20100331"     id="10"     customerId="10">
<litleTxnId>27200079920901</litleTxnId>
<orderId>10</orderId>
<response>503</response>
<message>The issuing bank does not participate in the update program.</message>
<originalCard>
<type>VISA</type>
<number>5112000400000018</number>
<expDate>0210</expDate>
</originalCard>
<updatedCard>
<type>N/A</type>
<number>N/A</number>
<expDate>N/A</expDate>
</updatedCard>
</accountUpdateResponse>
</batchResponse>
</litleResponse>
',



        };
