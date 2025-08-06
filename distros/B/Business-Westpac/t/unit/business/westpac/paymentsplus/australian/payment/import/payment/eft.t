#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT';

use_ok( $class );

my %attr = (
    payer_payment_reference => 'REF00001',
    payment_amount => '36.04',
    recipient_reference => 'REF00001',
    account_number => '000002',
    account_name => 'Payee 02',
    bsb_number => '062-000',
    funding_bsb_number => '032-000',
    funding_account_number => '000007',
    remitter_name => 'Remitter Name',
);

isa_ok(
    my $EFT = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $EFT->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"E",,"REF00001","36.04","REF00001","062-000","000002","Payee 02","032-000","000007","Remitter Name"
