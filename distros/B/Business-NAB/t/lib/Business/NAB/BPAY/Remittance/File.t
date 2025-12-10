#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::Most;
use FindBin qw/ $Bin /;
use File::Temp;
use Test::File::Contents;
use Test::Warnings;

my $class = join(
    '::',
    qw/
        Business
        NAB
        BPAY
        Remittance
        File
        /,
);

use_ok( $class );

my $example_file = "$Bin/../../example_files/bpay-reporting-brf.txt";

subtest 'parse' => sub {

    isa_ok(
        my $File = $class->new_from_file( $example_file ),
        $class,
    );

    isa_ok(
        $File->header_record->[ 0 ],
        'Business::NAB::BPAY::Remittance::File::HeaderRecord',
    );

    is( scalar( $File->detail_record->@* ), 12, 'count of detail_record' );

    isa_ok(
        $File->trailer_record->[ 0 ],
        'Business::NAB::BPAY::Remittance::File::TrailerRecord',
    );

    subtest 'round trip' => sub {

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $File->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

subtest 'instantiation + add attributes' => sub {

    isa_ok(
        my $File = $class->new,
        $class,
    );

    $File->add_header_record( {
        'biller_code'           => '0000187536',
        'biller_credit_account' => '123456789',
        'biller_credit_bsb'     => '082009',
        'biller_short_name'     => 'SAMPLE BILLER NAME',
        'file_creation_date'    => '20120806',
        'file_creation_time'    => '113615',
    } );

    foreach my $payment (
        [ qw/ 05 000 / ] x 7,
        [ qw/ 15 006 / ],
        [ qw/ 15 005 / ],
        [ qw/ 15 004 / ],
        [ qw/ 15 003 / ],
        [ qw/ 25 002 / ],
    ) {
        my ( $pit, $ecr ) = $payment->@*;

        $File->add_detail_record( {
            'amount'                       => '10000',
            'biller_code'                  => '187536',
            'customer_reference_number'    => '30677309603',
            'error_correction_reason'      => $ecr,
            'original_reference_number'    => '',
            'payment_date'                 => '20120608',
            'payment_instruction_type'     => $pit,
            'payment_time'                 => '193702',
            'settlement_date'              => '20120611',
            'transaction_reference_number' => 'NAB201202203052795923',
        } );
    }

    is( scalar( $File->detail_record->@* ), 12, '12 detail records added' );

    subtest '->to_file (lacking trailer record)' => sub {
        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $File->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

    subtest '->to_file (with trailer record)' => sub {
        $File->add_trailer_record( {
            'amount_of_error_corrections' => 40000,
            'amount_of_payments'          => 70000,
            'amount_of_reversals'         => 10000,
            'biller_code'                 => '0000187536',
            'number_of_error_corrections' => 4,
            'number_of_payments'          => 7,
            'number_of_reversals'         => 1,
            'settlement_amount'           => 20000,
        } );

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $File->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

done_testing();
