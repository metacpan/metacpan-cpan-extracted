#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::File';

use_ok( $class );

my %header_attr = (
    customer_code => 'TESTPAYER',
    customer_name => 'TESTPAYER',
    customer_file_reference => 'TESTFILE001',
    scheduled_date => '26082016',
);

isa_ok( my $File = $class->new( %header_attr ),$class );

my %remittance = (
    remittance_delivery_type => 'EMAIL',
    payee_name => 'Payee 01',
    addressee_name => 'Addressee 01',
    street_1 => 'Level 1',
    street_2 => 'Wallsend Plaza',
    city => 'Wallsend',
    state => 'NSW',
    post_code => '2287',
    country => 'AU',
    email => 'test@test.com',
    remittance_layout_code => 1,
    return_to_address_identifier => 1,
);

my %invoice = (
    payers_invoice_number => '1000000001',
    recipient_invoice_number => '1000000001',
    issued_date => '26082016',
    due_date => '01092016',
    invoice_amount => '36.04',
    invoice_amount_paid => '36.04',
    invoice_description => 'Desc 1',
    deduction_description => 'Ded Desc 1',
);

$File->add_eft_record(
    eft => {
        payer_payment_reference => 'REF00001',
        payment_amount => '36.04',
        recipient_reference => 'REF00001',
        account_number => '000002',
        account_name => 'Payee 02',
        bsb_number => '062-000',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        remitter_name => 'Remitter Name',
    },
    remittance => \%remittance,
    invoices => [ \%invoice ],
);

$File->add_osko_record(
    osko => {
        debtor_information => 'Debtor Information 01',
        payment_amount => '100.00',
        end_to_end_id => 'EndToEndID01',
        account_identifier => '062000000002',
        account_scheme_name => 'BBAN',
        payee_account_name => 'Payee 02',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        remittance_information_1 => 'Remittance Information 1',
        remittance_information_2 => 'Remittance Information 2',
    },
);

$File->add_cheque_record(
    cheque => {
        payer_payment_reference => 'REF00002',
        payment_amount => '718.65',
        recipient_reference => '100008',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    },
    remittance => {
        %remittance,
        remittance_delivery_type => 'POST',
        payee_name => 'Payee 02',
        addressee_name => 'Addressee 02',
        email => undef,
    },
    invoices => [
        {
            payers_invoice_number => '2000000001',
            recipient_invoice_number => '2000000001',
            issued_date => '26082016',
            due_date => '01092016',
            invoice_amount => '359.32',
            invoice_amount_paid => '359.32',
            invoice_description => 'Desc 2',
            deduction_description => 'Ded Desc 2',
        },
        {
            payers_invoice_number => '2000000002',
            recipient_invoice_number => '2000000002',
            issued_date => '26082016',
            due_date => '01092016',
            invoice_amount => '359.33',
            invoice_amount_paid => '359.33',
            invoice_description => 'Desc 3',
            deduction_description => 'Ded Desc 3',
        },
    ],
);

$File->add_bpay_record(
    bpay => {
        payer_payment_reference => 'REF00003',
        payment_amount => '191.57',
        recipient_reference => '1234500012',
        bsb_number => '062-000',
        bpay_biller_number => '401234',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    }
);

$File->add_bpay_record(
    bpay => {
        payer_payment_reference => 'REF00004',
        payment_amount => '69.95',
        recipient_reference => '1234500013',
        bsb_number => '062-000',
        bpay_biller_number => '401234',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    }
);

$File->add_realtime_record(
    realtime => {
        payer_payment_reference => 'REF00005',
        payment_amount => '123.23',
        recipient_reference => 'REF00005',
        account_number => '000002',
        account_name => 'Payee 5',
        bsb_number => '062-000',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
    },
    remittance => {
        %remittance,
        payee_name => 'Payee 05',
        addressee_name => 'Addressee 05',
        remittance_layout_code => 2,
    },
);

$File->add_remittance_only_record(
    remittance_only => {
        payer_payment_reference => 'REF00006',
        payment_amount => '16.35',
        recipient_reference => 'REF00006',
    },
    remittance => {
        %remittance,
        payee_name => 'Payee 06',
        addressee_name => 'Addressee 06',
        remittance_layout_code => 2,
    },
);

$File->add_overseas_telegraphic_transfer_record(
    overseas_telegraphic_transfer => {
        payer_payment_reference => 'REF00007',
        payment_amount => 759.63,
        payment_currency => 'USD',
        recipient_reference => 'REF00007',
        swift_code => 'WBC12345XXX',
        account_number_iban => '032000000026',
        payee_account_name => 'Payee 07',
        payee_street_1 => 'Level 1',
        payee_street_2 => 'Wallsend Plaza',
        payee_city => 'Wallsend',
        payee_state => 'NSW',
        payee_post_code => '2287',
        payee_country => 'AU',
        funding_amount => 995.58,
        funding_currency => 'AUD',
        dealer_reference => '0123456789',
        exchange_rate => '0.7630',
        funding_bsb_number => '032-000',
        funding_account_number => '000007',
        outgoing_payment_information_line_1 => 'REF00071',
        outgoing_payment_information_line_2 => 'REF00072',
        charge_bearer_code => "",
    },
    remittance => {
        %remittance,
        payee_name => 'Payee 07',
        addressee_name => 'Addressee 07',
        remittance_layout_code => 2,
    },
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $File->to_csv ],
    [ @expected ],
    '->to_csv'
);

subtest 'exceptions' => sub {

    throws_ok(
        sub { $File->_add_record( 'not an object' ); },
        qr/Validation failed for/,
    );

    throws_ok(
        sub { $File->add_cheque_record( cheque => {} ); },
        qr/Cheque records must have a remittance/,
    );

    throws_ok(
        sub { $File->add_remittance_only_record( remittance_only => {} ); },
        qr/RemittanceOnly records must have a remittance/,
    );

    throws_ok(
        sub { $File->add_cheque_record( cheque => {},remittance => {} ); },
        qr/\QAttribute (payment_amount) is required\E/,
    );
};

done_testing();

# test file below built from the sample file in the docs at
# https://paymentsplus.westpac.com.au/docs/file-formats/australian-payment-import-csv/
__DATA__
"H","TESTPAYER","TESTPAYER","TESTFILE001","26082016","AUD","6"
"E",,"REF00001","36.04","REF00001","062-000","000002","Payee 02","032-000","000007","Remitter Name"
"R","EMAIL","Payee 01","Addressee 01","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,"test@test.com","1","1"
"I","1000000001","1000000001","26082016","01092016","36.04","36.04","Desc 1","0","Ded Desc 1"
"O",,"Debtor Information 01","100.00","EndToEndID01","062000000002","BBAN","Payee 02","032-000","000007","Remittance Information 1","Remittance Information 2"
"C",,"REF00002","718.65","100008","032-000","000007"
"R","POST","Payee 02","Addressee 02","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,,"1","1"
"I","2000000001","2000000001","26082016","01092016","359.32","359.32","Desc 2","0","Ded Desc 2"
"I","2000000002","2000000002","26082016","01092016","359.33","359.33","Desc 3","0","Ded Desc 3"
"B",,"REF00003","191.57","401234","1234500012","032-000","000007"
"B",,"REF00004","69.95","401234","1234500013","032-000","000007"
"RT",,"REF00005","123.23","REF00005","062-000","000002","Payee 5","032-000","000007"
"R","EMAIL","Payee 05","Addressee 05","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,"test@test.com","2","1"
"RO",,"REF00006","REF00006","16.35"
"R","EMAIL","Payee 06","Addressee 06","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,"test@test.com","2","1"
"OTT",,"REF00007","759.63","USD","REF00007","WBC12345XXX","032000000026",,"Payee 07","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU","995.58","AUD","0123456789","0.7630","032-000","000007","REF00071","REF00072",""
"R","EMAIL","Payee 07","Addressee 07","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,"test@test.com","2","1"
"T","8","2015.42"
