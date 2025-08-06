#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::Cheque';

use_ok( $class );

my %attr = (
    payer_payment_reference => 'REF00002',
    payment_amount => '718.65',
    recipient_reference => '100008',
    funding_bsb_number => '032-000',
    funding_account_number => '000007',
);

isa_ok(
    my $Cheque = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $Cheque->to_csv ],
    [ @expected ],
    '->to_csv'
);

subtest 'BSB type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, funding_bsb_number => "1234-123" ) },
        qr/does not match/,
    );
};

subtest 'string type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, recipient_reference => 'longer than 7 chars' ) },
        qr/The string provided for recipient_reference was outside 1\.\.7 chars/,
    );
};

done_testing();

__DATA__
"C",,"REF00002","718.65","100008","032-000","000007"
