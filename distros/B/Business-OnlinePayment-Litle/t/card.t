#!/usr/bin/perl -w

use Test::More qw(no_plan);

## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my @opts = ('default_Origin' => 'RECURRING' );

## grab test info from the storable^H^H yeah actually just DATA now

my $str = do { local $/ = undef; <DATA> };
my $data;
eval($str);

#print Dumper( keys %{$data} );
  
my $authed = 
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID};

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3 if ! $authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'Supplied a MerchantID');
}

my %orig_content = (
    type           => 'CC',
    login          => $login,
    password       => $password,
    merchantid      =>  $merchantid,
    action         => 'Authorization Only', #'Normal Authorization',
    description    => 'BLU*BusinessOnlinePayment',
#    card_number    => '4007000000027',
    card_number    => '4457010000000009',
    cvv2           => '123',
    expiration     => expiration_date(),
    amount         => '49.95',
    name           => 'Tofu Beast',
    email          => 'ippay@weasellips.com',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',      # will be forced to USA
    customer_id    => 'tfb',
    company_phone  => '801.123-4567',
    url            =>  'support.foo.com',
    invoice_number => '1234',
    ip             =>  '127.0.0.1',
    ship_name      =>  'Tofu Beast, Co.',
    ship_address   =>  '123 Anystreet',
    ship_city      => 'Anywhere',
    ship_state     => 'UT',
    ship_zip       => '84058',
    ship_country   => 'US',      # will be forced to USA
    tax            => 0,
    products        =>  [
    {   description =>  'First Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  500,
        discount    =>  0,
        code        =>  1,
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 500,
    },
    {   description =>  'Second Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  1500,
        discount    =>  0,
        code        =>  2,
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 1500,
    }

    ],
);

    %auth_resp = ();
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
    my %content = %orig_content;
### Litle AUTH Tests
    print '-'x70;
    print "PARTIAL AUTH TESTS\n";
    foreach my $account ( @{$data->{'partial_account'}} ){
        $content{'amount'} = $account->{'Amount'};
        $content{'type'} = $account->{'CardType'};
        $content{'card_number'} = $account->{'AccountNumber'};
        $content{'expiration'} = $account->{'ExpDate'};
        $content{'cvv2'} = $account->{'CardValidation'};
        $content{'cvv2'} = '' if $content{'cvv2'} eq 'blank';
        $content{'invoice_number'} = time;
        ## get the response validation set for this order
        my ($address) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'address'} };
        $content{'name'} = $address->{'Name'};
        $content{'address'} = $address->{'Address1'};
        $content{'address2'} = $address->{'Address2'};
        $content{'city'} = $address->{'City'};
        $content{'state'} = $address->{'State'};
        $content{'state'} = $address->{'State'};
        $content{'zip'} = $address->{'Zip'};
        $content{'partial_auth'} = 1;

        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'partial_auth_response'} };
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Auth Only",
                is_success    => $resp_validation->{'Message'} eq 'Partially Approved' ? 1 : 0,
                result_code   => $resp_validation->{'Response Code'},
                error_message => $resp_validation->{'Message'},
                #authorization => $resp_validation->{'Auth Code'},
                approved_amount => $resp_validation->{'ApprovedAmount'},
            );

            $auth_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
        }
    }
}


    my %auth_resp = ();
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
    my %content = %orig_content;
### Litle AUTH Tests
    print '-'x70;
    print "AUTH TESTS\n";
    foreach my $account ( @{$data->{'account'}} ){
        $content{'amount'} = $account->{'Amount'};
        $content{'type'} = $account->{'CardType'};
        $content{'card_number'} = $account->{'AccountNumber'};
        $content{'expiration'} = $account->{'ExpDate'};
        $content{'cvv2'} = $account->{'CardValidation'};
        $content{'cvv2'} = '' if $content{'cvv2'} eq 'blank';
        $content{'invoice_number'} = time;
        ## get the response validation set for this order
        my ($address) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'address'} };
        $content{'name'} = $address->{'Name'};
        $content{'address'} = $address->{'Address1'};
        $content{'address2'} = $address->{'Address2'};
        $content{'city'} = $address->{'City'};
        $content{'state'} = $address->{'State'};
        $content{'state'} = $address->{'State'};
        $content{'zip'} = $address->{'Zip'};

        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'auth_response'} };
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Auth Only",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'Response Code'},
                error_message => $resp_validation->{'Message'},
                authorization => $resp_validation->{'Auth Code'},
                avs_code      => $resp_validation->{'AVS Result'},
                cvv2_response => $resp_validation->{'Card Validation Result'},
            );

            $auth_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
        }
    }
}


print '-'x70;
print "AUTH REVERSAL\n";

SKIP: {
    skip "No Test Account setup",12 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'auth_reversal_info'}} ){
        $content{'action'} = 'Auth Reversal';
        $content{'amount'} = $account->{'Auth Amount'};
        $content{'invoice_number'} = time;
        $content{'order_number'} = $auth_resp{ $account->{'Order ID'} } if $auth_resp{ $account->{'Order ID'} };
        ## get the response validation set for this order
        my ($resp_validation) = grep { $_->{'Order ID'} ==  $account->{'Order ID'} } @{ $data->{'auth_reversal_response'} };
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Auth Reversal",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'Response'},
                error_message => $resp_validation->{'Message'},
            );
        }
    }
}

    %auth_resp = ();
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
    my %content = %orig_content;
### Litle AUTH Tests
    print '-'x70;
    print "AUTH TESTS\n";
    foreach my $account ( @{$data->{'account'}} ){
        $content{'amount'} = $account->{'Amount'};
        $content{'type'} = $account->{'CardType'};
        $content{'card_number'} = $account->{'AccountNumber'};
        $content{'expiration'} = $account->{'ExpDate'};
        $content{'cvv2'} = $account->{'CardValidation'};
        $content{'cvv2'} = '' if $content{'cvv2'} eq 'blank';
        $content{'invoice_number'} = time;
        ## get the response validation set for this order
        my ($address) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'address'} };
        $content{'name'} = $address->{'Name'};
        $content{'address'} = $address->{'Address1'};
        $content{'address2'} = $address->{'Address2'};
        $content{'city'} = $address->{'City'};
        $content{'state'} = $address->{'State'};
        $content{'state'} = $address->{'State'};
        $content{'zip'} = $address->{'Zip'};

        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'auth_response'} };
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Auth Only",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'Response Code'},
                error_message => $resp_validation->{'Message'},
                authorization => $resp_validation->{'Auth Code'},
                avs_code      => $resp_validation->{'AVS Result'},
                cvv2_response => $resp_validation->{'Card Validation Result'},
            );

            $auth_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
        }
    }
}

print '-'x70;
print "CAPTURE\n";

my %cap_resp = ();

SKIP: {
    skip "No Test Account setup",15 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'account'}} ){
        next if $account->{'OrderId'} > 5; #can only capture first 5
        $content{'action'} = 'Post Authorization';
        $content{'amount'} = $account->{'Amount'};
        $content{'invoice_number'} = time;
        $content{'order_number'} = $auth_resp{ $account->{'OrderId'} };

        ## get the response validation set for this order
        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'capture'} };
        #print Dumper(\%content);
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Capture",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'ResponseCode'},
                error_message => $resp_validation->{'Message'},
            );
            $cap_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
        }
    }
}

print '-'x70;
print "SALE\n";
my %sale_resp = ();
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
    %content = %orig_content;

    foreach my $account ( @{$data->{'account'}} ){
        $content{'action'} = 'Normal Authorization';
        $content{'amount'} = $account->{'Amount'};
        $content{'type'} = $account->{'CardType'};
        $content{'card_number'} = $account->{'AccountNumber'};
        $content{'expiration'} = $account->{'ExpDate'};
        $content{'cvv2'} = $account->{'CardValidation'};
        $content{'cvv2'} = '' if $content{'cvv2'} eq 'blank';
        $content{'invoice_number'} = time;
        ## get the response validation set for this order
        my ($address) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'address'} };
        $content{'name'} = $address->{'Name'};
        $content{'address'} = $address->{'Address1'};
        $content{'address2'} = $address->{'Address2'};
        $content{'city'} = $address->{'City'};
        $content{'state'} = $address->{'State'};
        $content{'state'} = $address->{'State'};
        $content{'zip'} = $address->{'Zip'};

        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'sales'} };
        #print Dumper(\%content);
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Sale Order",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'ResponseCode'},
                error_message => $resp_validation->{'Message'},
                authorization => $resp_validation->{'AuthCode'},
                avs_code      => $resp_validation->{'AVSResult'},
                cvv2_response => $resp_validation->{'Card Validation Result'},
            );
            $sale_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
        }
    }
}
print '-'x70;
print "CREDIT\n";

SKIP: {
    skip "No Test Account setup",15 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'account'}} ){
        next if $account->{'OrderId'} > 5;
        $content{'action'} = 'Credit';
        $content{'amount'} = $account->{'Amount'};
        $content{'invoice_number'} = time;
        $content{'order_number'} = $cap_resp{ $account->{'OrderId'} };

        ## get the response validation set for this order
        my ($resp_validation) = grep { $_->{'OrderId'} ==  $account->{'OrderId'} } @{ $data->{'credit_response'} };
        #print Dumper(\%content);
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Credits",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'ResponseCode'},
                error_message => $resp_validation->{'Message'},
            );
        }
    }
}
    

print '-'x70;
print "VOID\n";

SKIP: {
    skip "No Test Account setup",15 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'account'}} ){
        next if $account->{'OrderId'} > 5;
        $content{'action'} = 'Void';
        $content{'amount'} = $account->{'Amount'};
        $content{'invoice_number'} = time;
        ## void from the sales tests, so they are active, and we can do the 6th test
        $content{'order_number'} = $sale_resp{ $account->{'OrderId'} } if $sale_resp{ $account->{'OrderId'} };

        ## get the response validation set for this order
        my ($resp_validation) = grep { $_->{'OrderID'} ==  $account->{'OrderId'} } @{ $data->{'void_response'} };
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "Void",
                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $resp_validation->{'Response Code'},
                error_message => $resp_validation->{'Message'},
            );
        }
    }
}



print '-'x70;
print "Response Codes\n";

SKIP: {
    skip "No Test Account setup",112 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'response_codes'}} ){
        $content{'action'} = 'Authorization Only';
        $content{'amount'} = '50.00';
        $content{'invoice_number'} = time;
        $content{'card_number'} = $account->{'Account Number'};
        $content{'type'} = 'CC';

        #### exp date hack for response, this one test requires it
        if( $account->{'Account Number'} eq '4457000200000008'){
            $content{'expiration'} = '21/20'; #impossible, but formatted correctly date
        }

        ## get the response validation set for this order
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            $account->{'Approval Code'} = undef if $account->{'Approval Code'} eq 'NA';
            tx_check(
                $tx,
                desc          => "Response Codes",
                is_success    => $account->{'Message'} eq 'Approved' ? 1 : 0,
                result_code   => $account->{'Response Code'},
                error_message => $account->{'Message'},
                authorization => $account->{'Approval Code'},
            );
        }
    }
}

print '-'x70;
print "AVS/Validation Tests\n";

SKIP: {
    skip "No Test Account setup", 84 if ! $authed;
    %content = %orig_content;
    foreach my $account ( @{$data->{'avs_validation'}} ){
        $content{'action'} = 'Authorization Only';
        $content{'amount'} = '50.00';
        $content{'invoice_number'} = time;
        $content{'card_number'} = $account->{'Account Number'};
        $content{'type'} = 'CC';

        ## get the response validation set for this order
        {
            my $tx = Business::OnlinePayment->new("Litle", @opts);
            $tx->content(%content);
            tx_check(
                $tx,
                desc          => "avs testing",
                is_success    => 1,
                result_code   => '000',
                error_message => 'Approved',
                authorization => '654321',
                avs_code      => $account->{'AVS Response Code'},
                cvv2_response => $account->{'Card Validation'},

            );
        }
    }
}


print '-'x70;
print "3DS Responses\n";
print "################# NOT Supported yet\n";

%content = %orig_content;
################# NOT Supported yet
#$content{'3ds'} = 'BwABBJQ1AgAAAAAgJDUCAAAAAAA=';
#delete( $content{'cvv2'} );
#
#foreach my $account ( @{$data->{'3ds_response'}} ){
#    $content{'action'} = 'Authorization Only';
#    $content{'amount'} = '50.00';
#    $content{'invoice_number'} = time;
#    $content{'card_number'} = $account->{'Account Number'};
#    $content{'type'} = 'CC';
#
#    ## get the response validation set for this order
#    {
#        my $tx = Business::OnlinePayment->new("Litle", @opts);
#        $tx->content(%content);
#        $account->{'Approval Code'} = undef if $account->{'Approval Code'} eq 'NA';
#        tx_check(
#            $tx,
#            desc          => "valid card_number",
#            is_success    => $account->{'Message'} eq 'Approved' ? 1 : 0,
#            result_code   => $account->{'Response Code'},
#            error_message => $account->{'Message'},
#            authorization => $account->{'Approval Code'},
#        );
#    }
#}


#-----------------------------------------------------------------------------------
#
sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

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
    if( $o{approved_amount} ){
        is( $tx->{_response}->{approvedAmount}, $o{approved_amount}, "approved_amount() / Partial Approval Amount" );
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
            " auth_info(",     $tx->authorization, ")",
            " avs_code(",      $tx->avs_code,      ")",
            " cvv2_response(", $tx->cvv2_response, ")",
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
          'partial_auth_response' => [
                               {
                                 'Response Code' => '010',
                                 'OrderId' => '10',
                                 'Message' => 'Partially Approved',
                                 'Auth Code' => '11111',
                                 'ApprovedAmount' => '32000',
                               },
                               {
                                 'Response Code' => '010',
                                 'OrderId' => '11',
                                 'Message' => 'Partially Approved',
                                 'Auth Code' => '11111',
                                 'ApprovedAmount' => '48000',
                               },
                               {
                                 'Response Code' => '010',
                                 'OrderId' => '12',
                                 'Message' => 'Partially Approved',
                                 'Auth Code' => '11111',
                                 'ApprovedAmount' => '40000',
                               },
                               {
                                 'Response Code' => '010',
                                 'OrderId' => '13',
                                 'Message' => 'Partially Approved',
                                 'Auth Code' => '12522',
                                 'ApprovedAmount' => '12000',
                               },
                             ],
          'partial_account' => [
                         {
                           'Amount' => '400.00',
                           'CardType' => 'VI',
                           'OrderId' => '10',
                           'AccountNumber' => '4457010140000141',
                           'ExpDate' => '0912',
                           'CardholderAuthentication' => '',
                           'CardValidation' => ''
                         },
                         {
                           'Amount' => '600.00',
                           'CardType' => 'MC',
                           'OrderId' => '11',
                           'AccountNumber' => '5112010140000004',
                           'ExpDate' => '1111',
                           'CardholderAuthentication' => '',
                           'CardValidation' => ''
                         },
                         {
                           'Amount' => '500.00',
                           'CardType' => 'AX',
                           'OrderId' => '12',
                           'AccountNumber' => '375001014000009',
                           'ExpDate' => '0412',
                           'CardholderAuthentication' => '',
                           'CardValidation' => ''
                         },
                         {
                           'Amount' => '150.00',
                           'CardType' => 'DI',
                           'OrderId' => '13',
                           'AccountNumber' => '6011010140000004',
                           'ExpDate' => '0812',
                           'CardholderAuthentication' => '',
                           'CardValidation' => ''
                         },
                       ],
          'auth_reversal_info' => [
                                    {
                                      'Order ID' => '1',
                                      'Payment Type' => 'VI',
                                      'Capture Amount' => '50.05',
                                      'Reversal Amount' => '50.05',
                                      'Auth Amount' => '100.10'
                                    },
                                    {
                                      'Order ID' => '2',
                                      'Payment Type' => 'MC',
                                      'Capture Amount' => '',
                                      'Reversal Amount' => '200.20',
                                      'Auth Amount' => '200.20'
                                    },
                                    {
                                      'Order ID' => '3',
                                      'Payment Type' => 'DI',
                                      'Capture Amount' => 'N/A',
                                      'Reversal Amount' => '100.00',
                                      'Auth Amount' => '300.30'
                                    },
                                    {
                                      'Order ID' => '4',
                                      'Payment Type' => 'AX',
                                      'Capture Amount' => '200.20',
                                      'Reversal Amount' => '200.20',
                                      'Auth Amount' => '400.40'
                                    },
                                    {
                                      'Order ID' => '5',
                                      'Payment Type' => 'AX',
                                      'Capture Amount' => 'N/A',
                                      'Reversal Amount' => '100.00',
                                      'Auth Amount' => '205.00'
                                    }
                                  ],
          'void_response' => [
                               {
                                 'Response Code' => '000',
                                 'Message' => 'Approved',
                                 'OrderID' => '1'
                               },
                               {
                                 'Response Code' => '000',
                                 'Message' => 'Approved',
                                 'OrderID' => '2'
                               },
                               {
                                 'Response Code' => '000',
                                 'Message' => 'Approved',
                                 'OrderID' => '3'
                               },
                               {
                                 'Response Code' => '000',
                                 'Message' => 'Approved',
                                 'OrderID' => '4'
                               },
                               {
                                 'Response Code' => '000',
                                 'Message' => 'Approved',
                                 'OrderID' => '5'
                               },
                               {
                                 'Response Code' => '360',
                                 'Message' => 'No transaction found with specified litleTxnId',
                                 'OrderID' => '6'
                               }
                             ],
          'avs_validation' => [
                                {
                                  'AVS Response Code' => '00',
                                  'Account Number' => '4457000300000007',
                                  'Card Validation' => 'U',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'AVS Response Code' => '01',
                                  'Account Number' => '4457000100000009',
                                  'Card Validation' => 'M',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'AVS Response Code' => '02',
                                  'Account Number' => '4457003100000003',
                                  'Card Validation' => 'M',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'AVS Response Code' => '10',
                                  'Account Number' => '4457000400000006',
                                  'Card Validation' => 'S',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'AVS Response Code' => '11',
                                  'Account Number' => '4457000200000008',
                                  'Card Validation' => 'M',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'AVS Response Code' => '12',
                                  'Account Number' => '5112000100000003',
                                  'Card Validation' => 'M',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '13',
                                  'Account Number' => '5112002100000009',
                                  'Card Validation' => 'M',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '14',
                                  'Account Number' => '5112002200000008',
                                  'Card Validation' => 'N',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '20',
                                  'Account Number' => '5112000200000002',
                                  'Card Validation' => 'N',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '30',
                                  'Account Number' => '5112000300000001',
                                  'Card Validation' => 'P',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '31',
                                  'Account Number' => '5112000400000000',
                                  'Card Validation' => 'U',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '32',
                                  'Account Number' => '6011000100000003',
                                  'Card Validation' => 'S',
                                  'Card Type' => 'DI'
                                },
                                {
                                #'AVS Response Code' => '33',
                                  'AVS Response Code' => '31',
                                  'Account Number' => '5112000500000009',
                                  'Card Validation' => '',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'AVS Response Code' => '34',
                                  'Account Number' => '5112000600000008',
                                  'Card Validation' => 'P',
                                  'Card Type' => 'MC'
                                }
                              ],
          'account' => [
                         {
                           'Amount' => '100.10',
                           'CardType' => 'VI',
                           'OrderId' => '1',
                           'AccountNumber' => '4457010000000009',
                           'ExpDate' => '0112',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '349'
                         },
                         {
                           'Amount' => '200.20',
                           'CardType' => 'MC',
                           'OrderId' => '2',
                           'AccountNumber' => '5112010000000003',
                           'ExpDate' => '0212',
                           'CardholderAuthentication' => 'BwABBJQ1AgAAAAAgJDUCAAAAAAA=',
                           'CardValidation' => '261'
                         },
                         {
                           'Amount' => '300.30',
                           'CardType' => 'DI',
                           'OrderId' => '3',
                           'AccountNumber' => '6011010000000003',
                           'ExpDate' => '0312',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '758'
                         },
                         {
                           'Amount' => '400.40',
                           'CardType' => 'AX',
                           'OrderId' => '4',
                           'AccountNumber' => '375001000000005',
                           'ExpDate' => '0412',
                           'CardholderAuthentication' => '',
                           'CardValidation' => 'blank'
                         },
                         {
                           'Amount' => '500.50',
                           'CardType' => 'VI',
                           'OrderId' => '5',
                           'AccountNumber' => '4457010200000007',
                           'ExpDate' => '0512',
                           'CardholderAuthentication' => 'BwABBJQ1AgAAAAAgJDUCAAAAAAA=',
                           'CardValidation' => '463'
                         },
                         {
                           'Amount' => '600.60',
                           'CardType' => 'VI',
                           'OrderId' => '6',
                           'AccountNumber' => '4457010100000008',
                           'ExpDate' => '0612',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '992'
                         },
                         {
                           'Amount' => '700.70',
                           'CardType' => 'MC',
                           'OrderId' => '7',
                           'AccountNumber' => '5112010100000002',
                           'ExpDate' => '0712',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '251'
                         },
                         {
                           'Amount' => '800.80',
                           'CardType' => 'DI',
                           'OrderId' => '8',
                           'AccountNumber' => '6011010100000002',
                           'ExpDate' => '0812',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '184'
                         },
                         {
                           'Amount' => '900.90',
                           'CardType' => 'AX',
                           'OrderId' => '9',
                           'AccountNumber' => '375001010000003',
                           'ExpDate' => '0912',
                           'CardholderAuthentication' => '',
                           'CardValidation' => '0421'
                         }
                       ],
          'sales' => [
                       {
                         'OrderId' => '1',
                         'ResponseCode' => '000',
                         'AuthCode' => '11111',
                         'Message' => 'Approved',
                         'Authentication Result' => '',
                         'Card Validation Result' => 'M',
                         'AVSResult' => '01'
                       },
                       {
                         'OrderId' => '2',
                         'ResponseCode' => '000',
                         'AuthCode' => '22222',
                         'Message' => 'Approved',
                         'Authentication Result' => 'Not returned for MasterCard',
                         'Card Validation Result' => 'M',
                         'AVSResult' => '10'
                       },
                       {
                         'OrderId' => '3',
                         'ResponseCode' => '000',
                         'AuthCode' => '33333',
                         'Message' => 'Approved',
                         'Authentication Result' => '',
                         'Card Validation Result' => 'M',
                         'AVSResult' => '10'
                       },
                       {
                         'OrderId' => '4',
                         'ResponseCode' => '000',
                         'AuthCode' => '44444',
                         'Message' => 'Approved',
                         'Authentication Result' => '',
                         'Card Validation Result' => '',
                         'AVSResult' => '13'
                       },
                       {
                         'OrderId' => '5',
                         'ResponseCode' => '000',
                         'AuthCode' => '55555',
                         'Message' => 'Approved',
                         'Authentication Result' => '2',
                         'Card Validation Result' => 'M',
                         'AVSResult' => '32'
                       },
                       {
                         'OrderId' => '6',
                         'ResponseCode' => '110',
                         'AuthCode' => '',
                         'Message' => 'Insufficient Funds',
                         'Authentication Result' => '',
                         'Card Validation Result' => 'P',
                         'AVSResult' => '34'
                       },
                       {
                         'OrderId' => '7',
                         'ResponseCode' => '301',
                         'AuthCode' => '',
                         'Message' => 'Invalid Account Number',
                         'Authentication Result' => '',
                         'Card Validation Result' => 'N',
                         'AVSResult' => '34'
                       },
                       {
                         'OrderId' => '8',
                         'ResponseCode' => '123',
                         #'ResponseCode' => '120',
                         'AuthCode' => '',
                         'Message' => 'Call Discover',
                         #'Message' => 'Call Issuer',
                         'Authentication Result' => '',
                         'Card Validation Result' => 'P',
                         'AVSResult' => '34'
                       },
                       {
                         'OrderId' => '9',
                         'ResponseCode' => '303',
                         'AuthCode' => '',
                         'Message' => 'Pick Up Card',
                         'Authentication Result' => '',
                         'Card Validation Result' => '',
                         'AVSResult' => '34'
                       }
                     ],
          'auth_response' => [
                               {
                                 'Response Code' => '000',
                                 'OrderId' => '1',
                                 'AVS Result' => '01',
                                 'Message' => 'Approved',
                                 'Authentication Result' => '',
                                 'Auth Code' => '11111',
                                 'Card Validation Result' => 'M'
                               },
                               {
                                 'Response Code' => '000',
                                 'OrderId' => '2',
                                 'AVS Result' => '10',
                                 'Message' => 'Approved',
                                 'Authentication Result' => 'Not returned for MasterCard',
                                 'Auth Code' => '22222',
                                 'Card Validation Result' => 'M'
                               },
                               {
                                 'Response Code' => '000',
                                 'OrderId' => '3',
                                 'AVS Result' => '10',
                                 'Message' => 'Approved',
                                 'Authentication Result' => '',
                                 'Auth Code' => '33333',
                                 'Card Validation Result' => 'M'
                               },
                               {
                                 'Response Code' => '000',
                                 'OrderId' => '4',
                                 'AVS Result' => '13',
                                 'Message' => 'Approved',
                                 'Authentication Result' => '',
                                 'Auth Code' => '44444',
                                 'Card Validation Result' => ''
                               },
                               {
                                 'Response Code' => '000',
                                 'OrderId' => '5',
                                 'AVS Result' => '32',
                                 'Message' => 'Approved',
                                 'Authentication Result' => '2',
                                 'Auth Code' => '55555',
                                 'Card Validation Result' => 'M'
                               },
                               {
                                 'Response Code' => '110',
                                 'OrderId' => '6',
                                 'AVS Result' => '34',
                                 'Message' => 'Insufficient Funds',
                                 'Authentication Result' => '',
                                 'Auth Code' => '',
                                 'Card Validation Result' => 'P'
                               },
                               {
                                 'Response Code' => '301',
                                 'OrderId' => '7',
                                 'AVS Result' => '34',
                                 'Message' => 'Invalid Account Number',
                                 'Authentication Result' => '',
                                 'Auth Code' => '',
                                 'Card Validation Result' => 'N'
                               },
                               {
                                 #'Response Code' => '120',
                                 'Response Code' => '123',
                                 'OrderId' => '8',
                                 'AVS Result' => '34',
                                 'Message' => 'Call Discover',
                                 #'Message' => 'Call Issuer',
                                 'Authentication Result' => '',
                                 'Auth Code' => '',
                                 'Card Validation Result' => 'P'
                               },
                               {
                                 'Response Code' => '303',
                                 'OrderId' => '9',
                                 'AVS Result' => '34',
                                 'Message' => 'Pick Up Card',
                                 'Authentication Result' => '',
                                 'Auth Code' => '',
                                 'Card Validation Result' => ''
                               }
                             ],
          'avs_only_response' => [
                                   {
                                     'OrderId' => '1',
                                     'Message' => 'Approved',
                                     'Response' => '000',
                                     'AVSResult' => '01'
                                   },
                                   {
                                     'OrderId' => '2',
                                     'Message' => 'Approved',
                                     'Response' => '000',
                                     'AVSResult' => '00'
                                   },
                                   {
                                     'OrderId' => '3',
                                     'Message' => 'Approved',
                                     'Response' => '000',
                                     'AVSResult' => '10'
                                   },
                                   {
                                     'OrderId' => '4',
                                     'Message' => 'Approved',
                                     'Response' => '000',
                                     'AVSResult' => '13'
                                   },
                                   {
                                     'OrderId' => '5',
                                     'Message' => 'Approved',
                                     'Response' => '000',
                                     'AVSResult' => '32'
                                   },
                                   {
                                     'OrderId' => '6',
                                     'Message' => 'Insufficient Funds',
                                     'Response' => '110',
                                     'AVSResult' => '34'
                                   },
                                   {
                                     'OrderId' => '7',
                                     'Message' => 'Invalid Account Number',
                                     'Response' => '301',
                                     'AVSResult' => '34'
                                   },
                                   {
                                     'OrderId' => '8',
                                     'Message' => 'Call Issuer',
                                     'Response' => '120',
                                     'AVSResult' => '34'
                                   },
                                   {
                                     'OrderId' => '9',
                                     'Message' => 'Pick Up Card',
                                     'Response' => '303',
                                     'AVSResult' => '34'
                                   }
                                 ],
          'force_capture' => [
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '1',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '2',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '3',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '4',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '5',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '6',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '7',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '8',
                                 'Message' => 'Approved'
                               },
                               {
                                 'ResponseCode' => '000',
                                 'OrderId' => '9',
                                 'Message' => 'Approved'
                               }
                             ],
          'credit_response' => [
                                 {
                                   'ResponseCode' => '000',
                                   'OrderId' => '1',
                                   'Message' => 'Approved'
                                 },
                                 {
                                   'ResponseCode' => '000',
                                   'OrderId' => '2',
                                   'Message' => 'Approved'
                                 },
                                 {
                                   'ResponseCode' => '000',
                                   'OrderId' => '3',
                                   'Message' => 'Approved'
                                 },
                                 {
                                   'ResponseCode' => '000',
                                   'OrderId' => '4',
                                   'Message' => 'Approved'
                                 },
                                 {
                                   'ResponseCode' => '000',
                                   'OrderId' => '5',
                                   'Message' => 'Approved'
                                 }
                               ],
          'capture' => [
                         {
                           'OrderId' => '1',
                           'ResponseCode' => '000',
                           'Message' => 'Approved'
                         },
                         {
                           'OrderId' => '2',
                           'ResponseCode' => '000',
                           'Message' => 'Approved'
                         },
                         {
                           'OrderId' => '3',
                           'ResponseCode' => '000',
                           'Message' => 'Approved'
                         },
                         {
                           'OrderId' => '4',
                           'ResponseCode' => '000',
                           'Message' => 'Approved'
                         },
                         {
                           'OrderId' => '5',
                           'ResponseCode' => '000',
                           'Message' => 'Approved'
                         }
                       ],
          'address_response' => [
                                  {
                                    'Response Code' => '000',
                                    'Response Message' => 'Approved',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950221111',
                                    'Account Number' => '4457000600000004',
                                    'Card Type' => 'VI',
                                    'Approval Code' => '654321'
                                  },
                                  {
                                    'Response Code' => '000',
                                    'Response Message' => 'Approved',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950222222',
                                    'Account Number' => '5112000700000007',
                                    'Card Type' => 'MC',
                                    'Approval Code' => '654321'
                                  },
                                  {
                                    'Response Code' => '000',
                                    'Response Message' => 'Approved',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950223333',
                                    'Account Number' => '375000010000005',
                                    'Card Type' => 'AX',
                                    'Approval Code' => '654321'
                                  },
                                  {
                                    'Response Code' => '000',
                                    'Response Message' => 'Approved',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950224444',
                                    'Account Number' => '6011000200000002',
                                    'Card Type' => 'DI',
                                    'Approval Code' => '654321'
                                  },
                                  {
                                    'Response Code' => '110',
                                    'Response Message' => 'Insufficient Funds',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950221111',
                                    'Account Number' => '4457000700000003',
                                    'Card Type' => 'VI',
                                    'Approval Code' => 'NA'
                                  },
                                  {
                                    'Response Code' => '110',
                                    'Response Message' => 'Insufficient Funds',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950222222',
                                    'Account Number' => '5112000800000006',
                                    'Card Type' => 'MC',
                                    'Approval Code' => 'NA'
                                  },
                                  {
                                    'Response Code' => '350',
                                    'Response Message' => 'Generic Decline',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950223333',
                                    'Account Number' => '375000020000003',
                                    'Card Type' => 'AX',
                                    'Approval Code' => 'NA'
                                  },
                                  {
                                    'Response Code' => '350',
                                    'Response Message' => 'Generic Decline',
                                    'Address Line 1' => '95 Main St.',
                                    'ZIP Code' => '950224444',
                                    'Account Number' => '6011000300000001',
                                    'Card Type' => 'DI',
                                    'Approval Code' => 'NA'
                                  }
                                ],
          'address' => [
                         {
                           'OrderId' => '1',
                           'AccountNumber' => '4457010000000009',
                           'Address2' => '',
                           'City' => 'Burlington',
                           'State' => 'MA',
                           'Country' => 'US',
                           'Address1' => '1 Main St.',
                           'Zip' => '01803-3747',
                           'Name' => 'John Smith'
                         },
                         {
                           'OrderId' => '2',
                           'AccountNumber' => '5112010000000003',
                           'Address2' => 'Apt. 222',
                           'City' => 'Riverside',
                           'State' => 'RI',
                           'Country' => 'US',
                           'Address1' => '2 Main St.',
                           'Zip' => '02915',
                           'Name' => 'Mike J. Hammer'
                         },
                         {
                           'OrderId' => '3',
                           'AccountNumber' => '6011010000000003',
                           'Address2' => '',
                           'City' => 'Bloomfield',
                           'State' => 'CT',
                           'Country' => 'US',
                           'Address1' => '3 Main St.',
                           'Zip' => '06002',
                           'Name' => 'Eileen Jones'
                         },
                         {
                           'OrderId' => '4',
                           'AccountNumber' => '375001000000005',
                           'Address2' => '',
                           'City' => 'Laurel',
                           'State' => 'MD',
                           'Country' => 'US',
                           'Address1' => '4 Main St.',
                           'Zip' => '20708',
                           'Name' => 'Bob Black'
                         },
                         {
                           'OrderId' => '5',
                           'AccountNumber' => '4457010200000007',
                           'Address2' => '',
                           'City' => '',
                           'State' => '',
                           'Country' => '',
                           'Address1' => '',
                           'Zip' => '',
                           'Name' => ''
                         },
                         {
                           'OrderId' => '6',
                           'AccountNumber' => '4457010100000008',
                           'Address2' => '',
                           'City' => 'Derry',
                           'State' => 'NH',
                           'Country' => 'US',
                           'Address1' => '6 Main St.',
                           'Zip' => '03038',
                           'Name' => 'Joe Green'
                         },
                         {
                           'OrderId' => '7',
                           'AccountNumber' => '5112010100000002',
                           'Address2' => '',
                           'City' => 'Amesbury',
                           'State' => 'MA',
                           'Country' => 'US',
                           'Address1' => '7 Main St.',
                           'Zip' => '01913',
                           'Name' => 'Jane Murray'
                         },
                         {
                           'OrderId' => '8',
                           'AccountNumber' => '6011010100000002',
                           'Address2' => '',
                           'City' => 'Manchester',
                           'State' => 'NH',
                           'Country' => 'US',
                           'Address1' => '8 Main St.',
                           'Zip' => '03101',
                           'Name' => 'Mark Johnson'
                         },
                         {
                           'OrderId' => '9',
                           'AccountNumber' => '375001010000003',
                           'Address2' => '',
                           'City' => 'Boston',
                           'State' => 'MA',
                           'Country' => 'US',
                           'Address1' => '9 Main St.',
                           'Zip' => '02134',
                           'Name' => 'James Miller'
                         }
                       ],
          '3ds_response' => [
                              {
                                'Account Number' => '4457010200000015',
                                'AuthenticationResult' => '0',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000023',
                                'AuthenticationResult' => '1',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000031',
                                'AuthenticationResult' => '2',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000049',
                                'AuthenticationResult' => '3',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000056',
                                'AuthenticationResult' => '4',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000064',
                                'AuthenticationResult' => '5',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000072',
                                'AuthenticationResult' => '6',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000080',
                                'AuthenticationResult' => '7',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000098',
                                'AuthenticationResult' => '8',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000106',
                                'AuthenticationResult' => '9',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000114',
                                'AuthenticationResult' => 'A',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000122',
                                'AuthenticationResult' => 'B',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000130',
                                'AuthenticationResult' => 'C',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '4457010200000148',
                                'AuthenticationResult' => 'D',
                                'Card Type' => 'VI'
                              },
                              {
                                'Account Number' => '5112010200000001',
                                'AuthenticationResult' => 'N/A',
                                'Card Type' => 'MC'
                              }
                            ],
          'response_codes' => [
                                {
                                  'Response Code' => '000',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Approved',
                                  'Account Number' => '4457000800000002',
                                  'Approval Code' => '654321',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '000',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Approved',
                                  'Account Number' => '4457000900000001',
                                  'Approval Code' => '654321',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '000',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Approved',
                                  'Account Number' => '4457001000000008',
                                  'Approval Code' => '654321',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '000',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Approved',
                                  'Account Number' => '5112000900000005',
                                  'Approval Code' => '654321',
                                  'Card Type' => 'MC'
                                },
                                {
                                  #'Response Code' => '121',
                                  'Response Code' => '120',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Call Issuer',
                                  'Account Number' => '375000030000001',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'AX'
                                },
                                {
                                  #'Response Code' => '120',
                                  'Response Code' => '123',
                                  'AVS Response Code' => undef,
                                  #'Message' => 'Call Issuer',
                                  'Message' => 'Call Discover',
                                  'Account Number' => '6011000400000000',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'DI'
                                },
                                {
                                  'Response Code' => '120',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Call Issuer',
                                  'Account Number' => '4457001200000006',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '120',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Call Issuer',
                                  'Account Number' => '4457001300000005',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '120',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Call Issuer',
                                  'Account Number' => '4457001400000004',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '101',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Issuer Unavailable',
                                  'Account Number' => '5112001000000002',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '321',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Merchant',
                                  'Account Number' => '4457001900000009',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '303',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Pick Up Card',
                                  'Account Number' => '4457002000000006',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '110',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Insufficient Funds',
                                  'Account Number' => '4457002100000005',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '120',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Call Issuer',
                                  'Account Number' => '4457002200000004',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '110',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Insufficient Funds',
                                  'Account Number' => '375000050000006',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'AX'
                                },
                                {
                                  'Response Code' => '349',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Do Not Honor',
                                  'Account Number' => '4457002300000003',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '340',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Amount',
                                  'Account Number' => '4457002500000001',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '301',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Account Number',
                                  'Account Number' => '5112001600000006',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '301',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Account Number',
                                  'Account Number' => '5112001700000005',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '321',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Merchant',
                                  'Account Number' => '5112001800000004',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '101',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Issuer Unavailable',
                                  'Account Number' => '4457002700000009',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '305',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Expired Card',
                                  'Account Number' => '5112001900000003',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '322',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Transaction',
                                  'Account Number' => '4457002800000008',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '350',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Generic Decline',
                                  'Account Number' => '4457002900000007',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '101',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Issuer Unavailable',
                                  'Account Number' => '4457003000000004',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '101',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Issuer Unavailable',
                                  'Account Number' => '5112002000000000',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'MC'
                                },
                                {
                                  'Response Code' => '301',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Account Number',
                                  'Account Number' => '4457000100000000',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                },
                                {
                                  'Response Code' => '320',
                                  'AVS Response Code' => undef,
                                  'Message' => 'Invalid Expiration Date',
                                  'Account Number' => '4457000200000008',
                                  'Approval Code' => 'NA',
                                  'Card Type' => 'VI'
                                }
                              ],
          'auth_reversal_response' => [
                                        {
                                        #'Message' => 'Authorization amount has already been depleted',
                                          'Message'  => 'Approved',
                                          'Order ID' => '1',
                                          'Response' => '000'
                                        },
                                        {
                                          'Message' => 'Approved',
                                          'Order ID' => '2',
                                          'Response' => '000'
                                        },
                                        {
                                          'Message' => 'Approved',
                                          'Order ID' => '3',
                                          'Response' => '000'
                                        },
                                        {
                                        #'Message' => 'This method of payment does not support authorization reversals',
                                          'Message' => 'Approved',
                                          'Order ID' => '4',
                                          'Response'  =>  '000',
                                          #'Response' => '335'
                                        },
                                        {
                                          'Message' => 'Reversal Amount does not match Authorization amount.',
                                          'Order ID' => '5',
                                          'Response' => '336'
                                        },
                                      ]
        };
