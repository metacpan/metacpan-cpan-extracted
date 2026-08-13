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
        Payments
        /,
);

use_ok( $class );

my $example_file = "$Bin/../example_files/bpay_batch_test_file.bpb";

subtest 'parse' => sub {

    isa_ok(
        my $Payments = $class->new_from_file( $example_file ),
        $class,
    );

    isa_ok(
        $Payments->header_record->[ 0 ],
        'Business::NAB::BPAY::Payments::HeaderRecord',
    );

    is( scalar( $Payments->detail_record->@* ), 5, 'count of detail_record' );

    isa_ok(
        $Payments->trailer_record->[ 0 ],
        'Business::NAB::BPAY::Payments::TrailerRecord',
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
        [ qw/ 7773 083-004 035261665 13863530005 12345 / ],
        [ qw/ 17079 083-004 035261665 017626433 45678 / ],
        [ qw/ 999755 083-004 035261665 130000044284027 999 / ],
        [ qw/ 78790 083004 035261665 42500153772 95173 / ],
        [ qw/ 8532 083004 035261665 6008642900322007 35719 / ],
    ) {
        $i++;

        $Payments->add_detail_record( {
            biller_code               => $payment->[ 0 ],
            payment_account_bsb       => $payment->[ 1 ],
            payment_account_number    => $payment->[ 2 ],
            customer_reference_number => $payment->[ 3 ],
            amount                    => $payment->[ 4 ],
            lodgement_reference_1     => "TransNo00$i",
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
        );

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

subtest 'floating point' => sub {

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

    # force some floating point issues with arithmetic
    my $amount = 281.71;
    $amount *= 100;

    foreach my $payment (
        [ qw/ 7773 083-004 035261665 13863530005 /,$amount ],
    ) {
        $i++;

        $Payments->add_detail_record( {
            biller_code               => $payment->[ 0 ],
            payment_account_bsb       => $payment->[ 1 ],
            payment_account_number    => $payment->[ 2 ],
            customer_reference_number => $payment->[ 3 ],
            amount                    => $payment->[ 4 ],
            lodgement_reference_1     => "TransNo00$i",
        } );
    }

    is( scalar( $Payments->detail_record->@* ), 1, '1 detail records added' );

    # BPAY records are fixed 144-char lines terminated with CRLF; pad the
    # meaningful prefix out to the record width rather than spelling out the
    # trailing blanks.
    my $line = sub { $_[0] . ( ' ' x ( 144 - length $_[0] ) ) . "\r\n" };
    my $expected =
        $line->( "1123456          TEST CUSTOMER       20070430" )
        . $line->( "2000000777308300403526166513863530005         0000000028171TransNo001" )
        . $line->( "900000000010000000028171" )
    ;

    subtest '->to_file (lacking trailer record)' => sub {
        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Payments->to_file( $tmp_file );

        file_contents_eq_or_diff(
            $tmp_file, $expected, "batch file content"
        );
    };
};

done_testing();
