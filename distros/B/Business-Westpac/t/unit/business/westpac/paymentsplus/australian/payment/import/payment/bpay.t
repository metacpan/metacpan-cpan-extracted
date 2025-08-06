#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::BPAY';

use_ok( $class );

my %attr = (
    payer_payment_reference => 'REF00003',
    payment_amount => '191.57',
    recipient_reference => '1234500012',
    bsb_number => '062-000',
    bpay_biller_number => '401234',
    funding_bsb_number => '032-000',
    funding_account_number => '000007',
);

isa_ok(
    my $BPAY = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $BPAY->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"B",,"REF00003","191.57","401234","1234500012","032-000","000007"
