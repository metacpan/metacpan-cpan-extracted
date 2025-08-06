#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice';

use_ok( $class );

my %attr = (
    payers_invoice_number => '1000000001',
    recipient_invoice_number => '1000000001',
    issued_date => '26082016',
    due_date => '01092016',
    invoice_amount => '36.04',
    invoice_amount_paid => '36.04',
    invoice_description => 'Desc 1',
    deduction_description => 'Ded Desc 1',
    pass_through_data => 'Some pass through data',
);

isa_ok(
    my $Invoice = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $Invoice->to_csv ],
    [ @expected ],
    '->to_csv'
);

subtest 'num type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, invoice_amount => $_ ) },
        qr/does not pass the type constraint/,
    ) for ( qw/ x / );
};

done_testing();

__DATA__
"I","1000000001","1000000001","26082016","01092016","36.04","36.04","Desc 1","0","Ded Desc 1"
"IP","Some pass through data"
