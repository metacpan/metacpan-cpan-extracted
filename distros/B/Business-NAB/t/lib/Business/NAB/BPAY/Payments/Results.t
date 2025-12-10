#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::Most;
use FindBin qw/ $Bin /;
use File::Temp;
use Test::File::Contents;
use Test::Warnings;
use Business::NAB::BPAY::Payments::Results::TrailerRecord;

my $class = join(
    '::',
    qw/
        Business
        NAB
        BPAY
        Payments
        Results
        /,
);

use_ok( $class );

my $example_file = "$Bin/../../example_files/bpay_batch_test_file_results.bpb";

subtest 'parse' => sub {

    isa_ok(
        my $Payments = $class->new_from_file( $example_file ),
        $class,
    );

    isa_ok(
        $Payments->header_record->[ 0 ],
        'Business::NAB::BPAY::Payments::Results::HeaderRecord',
    );

    is( scalar( $Payments->detail_record->@* ), 5, 'count of detail_record' );

    isa_ok(
        $Payments->trailer_record->[ 0 ],
        'Business::NAB::BPAY::Payments::Results::TrailerRecord',
    );

    subtest 'round trip' => sub {

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

};

subtest 'instantiation + add attributes' => sub {

    isa_ok(
        my $Payments = $class->new,
        $class,
    );

    $Payments->add_header_record( {
        bpay_batch_user_id  => '123456',
        customer_short_name => 'TEST CUSTOMER',
        processing_date     => DateTime->new(
            year  => 2007,
            month => 4,
            day   => 30,
        ),
    } );

    my $i = 0;

    foreach my $payment (
        [ qw/ 7773 083-004 035261665 13863530005 12345 0000 / ],
        [ qw/ 17079 083-004 035261665 017626433 45678 0000 / ],
        [ qw/ 999755 083-004 035261665 130000044284027 999 1001 / ],
        [ qw/ 78790 083004 035261665 42500153772 95173 1012 / ],
        [ qw/ 8532 083004 035261665 6008642900322007 35719 2001 / ],
    ) {
        $i++;

        $Payments->add_detail_record( {
            biller_code                  => $payment->[ 0 ],
            payment_account_bsb          => $payment->[ 1 ],
            payment_account_number       => $payment->[ 2 ],
            customer_reference_number    => $payment->[ 3 ],
            amount                       => $payment->[ 4 ],
            lodgement_reference_1        => "TransNo00$i",
            return_code                  => $payment->[ 5 ],
            return_code_desc             => 'foo bar baz',
            transaction_reference_number => 'NAB200704305102030UTC',
        } );
    }

    is( scalar( $Payments->detail_record->@* ), 5, '5 detail records added' );

    subtest '->to_file (lacking trailer record)' => sub {
        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

    subtest '->to_file (with trailer record)' => sub {
        $Payments->add_trailer_record(
            Business::NAB::BPAY::Payments::Results::TrailerRecord->new(
                total_value_of_payments             => 189914,
                total_number_of_payments            => 5,
                total_value_of_successful_payments  => 9914,
                total_number_of_successful_payments => 2,
                total_value_of_declined_payments    => 180001,
                total_number_of_declined_payments   => 3,
            )
        );

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

done_testing();
