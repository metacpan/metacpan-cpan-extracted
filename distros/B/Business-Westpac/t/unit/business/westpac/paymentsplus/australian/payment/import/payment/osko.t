#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Osko';

use_ok( $class );

my %attr = (
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
);

isa_ok(
    my $Osko = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $Osko->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"O",,"Debtor Information 01","100.00","EndToEndID01","062000000002","BBAN","Payee 02","032-000","000007","Remittance Information 1","Remittance Information 2"
