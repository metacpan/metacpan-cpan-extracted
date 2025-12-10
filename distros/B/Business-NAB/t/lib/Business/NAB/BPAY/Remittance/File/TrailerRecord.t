#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::Most;
use Test::Warnings;

my $class = join(
    '::',
    qw/
        Business
        NAB
        BPAY
        Remittance
        File
        TrailerRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $TrailerRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is( $TrailerRecord->amount_of_error_corrections,  40000,       'amount_of_error_corrections' );
    is( $TrailerRecord->amount_of_payments,           70000,       'amount_of_payments' );
    is( $TrailerRecord->amount_of_reversals,         -10000,       'amount_of_reversals' );
    is( $TrailerRecord->biller_code,                 '0000187536', 'biller_code' );
    is( $TrailerRecord->number_of_error_corrections, 4,            'number_of_error_corrections' );
    is( $TrailerRecord->number_of_payments,          7,            'number_of_payments' );
    is( $TrailerRecord->number_of_reversals,         1,            'number_of_reversals' );
    is( $TrailerRecord->settlement_amount,           20000,        'settlement_amount' );

    my $bad_line = $example_line =~ s/^9/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(19\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $TotalRecord = $class->new(
            'amount_of_error_corrections' =>  40000,
            'amount_of_payments'          =>  70000,
            'amount_of_reversals'         => -10000,
            'biller_code'                 => '0000187536',
            'number_of_error_corrections' => 4,
            'number_of_payments'          => 7,
            'number_of_reversals'         => 1,
            'settlement_amount'           => 20000,
        ),
        $class,
    );

    is( $TotalRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
99000018753600000000G00000000007000{00000000D00000000004000{00000000A00000000001000}00000000002000{
