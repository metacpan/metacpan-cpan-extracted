#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-OnlinePayment-WorldPay.t'

#########################

use Getopt::Long;
my $debug = '';
GetOptions( 'debug' => \$debug ) || die;

use Test::More tests => 35;
#use Test::More qw/no_plan/;
use Test::Exception;

BEGIN { use_ok('Business::OnlinePayment::WorldPay') };                              # test 1

#########################

my $tx = Business::OnlinePayment->new("WorldPay");
$tx->debug(1) if $debug;

isa_ok( $tx, 'Business::OnlinePayment::WorldPay' );                                 # test 2

$tx->set_server('live');
ok( $tx->server eq 'secure.ims.worldpay.com',         'Selecting live server' );    # test 3

$tx->set_server('test');
ok( $tx->server eq 'secure-test.wp3.rbsworldpay.com', 'Selecting test server' );    # test 4

$tx->test_transaction(1);

SKIP: {
    skip( 'because too many failed login tests may cause problems', 1) if 0;

    $tx->content(
        login          => 'FOOBAR',         # presumably invalid
        password       => 'FOOBAR',
        installation   => 'FOOBAR',
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '4484070000000000',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(
        $tx->is_success == 0 &&                                             # test 5
        $tx->error_message eq 'Authorization Required',     
        'Expected failed authorization'
    );
};

SKIP: {
    skip( 'because WORLDPAY_INSTALLATION_ID, WORLDPAY_MERCHANT_CODE, ' .
          'WORLDPAY_XML_PASSWORD envariables missing', 30 )                 # 35 - 5
    unless $ENV{WORLDPAY_INSTALLATION_ID} &&
           $ENV{WORLDPAY_MERCHANT_CODE}   &&
           $ENV{WORLDPAY_XML_PASSWORD};

    my $order_code;     # must be unique


    # Test with valid login & password but invalid installation ID

    $order_code = 'A' . sprintf("%07d", int rand 10000000);     # must be unique

    $tx->content(
        installation   => 'FOOBAR',       # presumably invalid
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => $order_code,
        name           => 'Karen Fieding',
        card_number    => '4484070000000000',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 6
        $tx->is_success == 0 &&
        $tx->error_message =~ /^Invalid installation ID/,
        'Expected invalid installation id'
    );


    # Test a valid Visa payment

    $order_code = 'A' . sprintf("%07d", int rand 10000000);             # must be unique

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => $order_code,
        name           => 'Karen Fieding',
        card_number    => '4484070000000000',                           # 16 digits
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 7
        $tx->is_success == 1,
        "Visa payment submitted"
    );

    ok(                                                                 # test 8
        $tx->authorization eq 'AUTHORIZED',
        "Visa payment authorized"
    );


    # Test a refund
    
    $tx->content(
        type           => 'Visa',
        action         => 'Refund',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => $order_code,
        name           => 'Karen Fieding',
        card_number    => '4484070000000000',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 1, "Visa refund" );                          # test 9


    # Test duplicate submission for payment with non-unique order code

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => $order_code,
        name           => 'Karen Fieding',
        card_number    => '4484070000000000',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 0 &&                                         # test 10
        $tx->error_message =~ /^Order has already been paid/,
        "Duplicate order_code"
    );


    # Test a invalid Visa payment, missing a required field (card holder name)

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        card_number    => '4484070000000000',                           # 16 digits
        exp_date       => '09/10',
    );

    throws_ok { $tx->submit() }  qr/missing required field name/,       # test 11
        'Expected exception, missing card holder name (required field)';


    # Test a valid Amex payment

    $tx->content(
        type           => 'Amex',
        action         => 'Payment',            # same as 'Normal Authorization'
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '370000200000000',                            # 15 digits
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 12
        $tx->is_success    == 1            &&
        $tx->authorization eq 'AUTHORIZED' &&
        $tx->error_message eq '',
        "Amex payment"
    );


    # Test a valid Solo payment with issue #

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '633473060000000000',                         # 18 digits
        issue_number   => 1,
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 1, "Solo payment with issue number");        # test 13


    # Test a valid Solo payment with start date instead of issue #

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '633473060000000000',                         # 18 digits
        start_date     => '01/02',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 1, "Solo payment with start date");          # test 14
    

    # Test a valid Solo payment with both start date and issue #

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '633473060000000000',                         # 18 digits
        issue_number   => 1,
        start_date     => '01/02',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 1, "Solo payment with issue # and start date");  # test 15
    

    # Test an invalid Solo payment with neither start date nor issue #

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '633473060000000000',                         # 18 digits
        exp_date       => '09/10',
    );

    throws_ok { $tx->submit() }  qr/missing required field issue_number or start_date/,     # test 16
        'Expected Solo exception, missing issue_number or start_date';

    
    # Test a 16-digit Solo # that doesn't accept an issue # (but does require start date)

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '6334580500000000',                           # 16 digits
        start_date     => '01/02',
        exp_date       => '09/10',
    );

    $tx->submit();

    ok( $tx->is_success == 1, "Solo payment with 16-digit card");       # test 17


    # Test an invalid Solo transaction, 16-digit # with an issue #

    $tx->content(
        type           => 'Solo',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '6334580500000000',                           # 16 digits
        issue_number   => 1,
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 18
        $tx->is_success == 0 &&
        $tx->error_message =~ /^Invalid payment details : Issue number/,
        "Expected invalid Solo payment, 16-digit card w/ issue #"
    );
    

    # Test valid MasterCard payment

    $tx->content(
        type           => 'MasterCard',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        card_number    => '5100080000000000',                           # 16 digits
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 19
        $tx->is_success    == 1            &&
        $tx->authorization eq 'AUTHORIZED' &&
        $tx->error_message eq '',
        "MasterCard payment"
    );


    # Test REFUSED MasterCard payment

    $tx->content(
        name           => 'REFUSED',

        type           => 'MasterCard',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        card_number    => '5100080000000000', 
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 20
        $tx->is_success    == 0         &&
        $tx->authorization eq 'REFUSED' &&
        $tx->result_code   == 5         &&
        $tx->error_message eq 'REFUSED',
        "Expected REFUSED MasterCard payment"
    );


    # Test REFERRED MasterCard payment

    $tx->content(
        name           => 'REFERRED',

        type           => 'MasterCard',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        card_number    => '5100080000000000', 
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 21
        $tx->is_success    == 0          &&
        $tx->authorization eq 'REFUSED'  &&
        $tx->result_code   == 2          &&
        $tx->error_message eq 'REFERRED',
        "Expected REFERRED MasterCard payment"
    );


    # Test FRAUD MasterCard payment

    $tx->content(
        name           => 'FRAUD',

        type           => 'MasterCard',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        card_number    => '5100080000000000', 
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 22
        $tx->is_success    == 0         &&
        $tx->authorization eq 'REFUSED' &&
        $tx->result_code   == 34        &&
        $tx->error_message eq 'FRAUD SUSPICION',
        "Expected FRAUD MasterCard payment"
    );
 

    # Test ERROR MasterCard payment

    $tx->content(
        name           => 'ERROR',

        type           => 'MasterCard',
        action         => 'Payment',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        card_number    => '5100080000000000', 
        exp_date       => '09/10',
    );

    $tx->submit();

    ok(                                                                 # test 23
        $tx->is_success    == 0                                      &&
        $tx->authorization eq 'ERROR'                                &&
        $tx->error_message eq 'Gateway error',
        "Expected ERROR MasterCard payment"
    );
 

    # Test "APPROVED" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 24
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->cvv_response eq 'APPROVED',
        "APPROVED CVC result"
    );


    # Test "FAILED" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '444',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 25
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->cvv_response eq 'FAILED',
        "Expected FAILED CVC result"
    );


    # Test "NOT CHECKED BY ACQUIRER" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '333',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 26
        $tx->is_success    == 1                          &&
        $tx->authorization eq 'AUTHORIZED'               &&
        $tx->cvv_response eq 'NOT CHECKED BY ACQUIRER',
        "Expected NOT CHECKED BY ACQUIRER CVC result"
    );


    # Test "NO RESPONSE FROM ACQUIRER" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '222',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 27
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->cvv_response eq 'NO RESPONSE FROM ACQUIRER',
        "Expected NO RESPONSE FROM ACQUIRER CVC result"
    );


    # Test "NOT SENT TO ACQUIRER" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '111',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 28
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->cvv_response eq 'NOT SENT TO ACQUIRER',
        "Expected NOT SENT TO ACQUIRER CVC result"
    );


    # Test "UNKNOWN" CVC result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '377',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 29
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->cvv_response eq 'UNKNOWN',
        "Expected UNKNOWN CVC result"
    );


    # Test "APPROVED" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '5555',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 30
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'APPROVED',
        "APPROVED AVS result"
    );


    # Test "FAILED" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '4444',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 31
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'FAILED',
        "Expected FAILED AVS result"
    );


    # Test "NOT CHECKED BY ACQUIRER" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '3333',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 32
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'NOT CHECKED BY ACQUIRER',
        "Expected NOT CHECKED BY ACQUIRER AVS result"
    );


    # Test "NO RESPONSE FROM ACQUIRER" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '2222',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 33
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'NO RESPONSE FROM ACQUIRER',
        "Expected NO RESPONSE FROM ACQUIRER AVS result"
    );


    # Test "NOT SENT TO ACQUIRER" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '1111',               # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 34
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'NOT SENT TO ACQUIRER',
        "Expected NOT SENT TO ACQUIRER AVS result"
    );


    # Test "UNKNOWN" AVS result

    $tx->content(
        type           => 'Visa',
        action         => 'Normal Authorization',
        description    => '20 English Roses',
        amount         => '49.95',
        currency       => 'GBP',
        order_number   => 'A' . sprintf("%07d", int rand 10000000),
        name           => 'Karen Fieding',
        address        => '123 Disk Drive',
        city           => 'Aywhere',
        state          => 'DE',
        zip            => '0',                  # 5555, 4444, 3333, 2222, 1111, 0, ...
        country        => 'US',
        phone          => '201-555-1212',
        card_number    => '4484070000000000', 
        exp_date       => '09/10',
        cvc            => '555',                # 555, 444, 333, 222, 111, ...
    );

    $tx->submit();

    ok(                                                                 # test 35
        $tx->is_success    == 1               &&
        $tx->authorization eq 'AUTHORIZED'    &&
        $tx->avs_response  eq 'UNKNOWN',
        "Expected UNKNOWN AVS result"
    );
}
