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
        Australian
        DirectEntry
        Payments
        /,
);

use_ok( $class );

my $example_file = "$Bin/../../example_files/payments_direct_debit.txt";

subtest 'parse' => sub {

    isa_ok(
        my $Payments = $class->new_from_file( $example_file ),
        $class,
    );

    isa_ok(
        $Payments->descriptive_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Payments::DescriptiveRecord',
    );

    is( scalar( $Payments->detail_record->@* ), 6, 'count of detail_record' );

    isa_ok(
        $Payments->total_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Payments::TotalRecord',
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

    $Payments->add_descriptive_record( {
        reel_sequence_number => '01',
        institution_name     => 'NAB',
        user_name            => 'NAB TEST',
        user_number          => 123456,
        description          => 'DrDebit',
        process_date         => '011223',
    } );

    $Payments->add_detail_record( {
        bsb_number           => '083-047',
        account_number       => $_ x 9,
        transaction_code     => '13',
        amount               => 1,
        title_of_account     => " Beneficiary $_",
        lodgement_reference  => 'FOR DEMONSTRATION',
        bsb_number_trace     => '083-047',
        account_number_trace => '123456789',
        remitter_name        => 'NAB SAMPLE  TEST',
        withholding_tax      => '00000000',
    } ) for 1 .. 5;

    my $fh       = File::Temp->new;
    my $tmp_file = $fh->filename;

    throws_ok(
        sub { $Payments->to_file( $tmp_file ); },
        qr/you have debits missing a credit/,
    );

    $Payments->add_detail_record( {
        bsb_number           => '083-047',
        account_number       => '123456789',
        transaction_code     => '50',
        amount               => 5,
        title_of_account     => " NAB TEST 1",
        lodgement_reference  => 'FOR DEMONSTRATION',
        bsb_number_trace     => '083-047',
        account_number_trace => '123456789',
        remitter_name        => 'NAB SAMPLE  TEST',
        withholding_tax      => '00000000',
    } );

    is( scalar( $Payments->detail_record->@* ), 6, '6 detail records added' );

    subtest '->to_file (lacking total record)' => sub {
        $Payments->to_file( $tmp_file, '999-999' );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

    subtest '->to_file (with total record)' => sub {
        $Payments->add_total_record(
            bsb_number          => '999-999',
            net_total_amount    => 0,
            credit_total_amount => 5,
            debit_total_amount  => 5,
            record_count        => 6,
        );

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

done_testing();
