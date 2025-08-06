#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::RemittanceOnly';

use_ok( $class );

my %attr = (
    payer_payment_reference => 'REF00006',
    payment_amount => '16.35',
    recipient_reference => 'REF00006',
);

isa_ok(
    my $RemittanceOnly = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $RemittanceOnly->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"RO",,"REF00006","REF00006","16.35"
