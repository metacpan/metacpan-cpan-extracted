#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::OTT';

use_ok( $class );

my %attr = (
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
);

isa_ok(
    my $OTT = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $OTT->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"OTT",,"REF00007","759.63","USD","REF00007","WBC12345XXX","032000000026",,"Payee 07","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU","995.58","AUD","0123456789","0.7630","032-000","000007","REF00071","REF00072",
