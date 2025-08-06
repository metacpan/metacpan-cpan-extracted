#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RealTime';

use_ok( $class );

my %attr = (
    payer_payment_reference => 'REF00005',
    payment_amount => '123.23',
    recipient_reference => 'REF00005',
    account_number => '000002',
    account_name => 'Payee 5',
    bsb_number => '062-000',
    funding_bsb_number => '032-000',
    funding_account_number => '000007',
);

isa_ok(
    my $RealTime = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $RealTime->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"RT",,"REF00005","123.23","REF00005","062-000","000002","Payee 5","032-000","000007"
