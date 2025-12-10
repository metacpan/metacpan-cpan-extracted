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
        Acknowledgement
        /,
);

use_ok( $class );

my $example_file = "$Bin/example_files/rejected.ack";

subtest 'edge cases' => sub {

    throws_ok(
        sub { $class->new_from_xml( '<FooAck type="info"></FooAck>' ); },
        qr/Unknown acknowledgement type: FooAck/,
        'uknown XML doc throws error',
    );
};

subtest 'parse MessageAcknowledgement' => sub {

    isa_ok(
        my $Ack = $class->new_from_xml( $example_file ),
        $class,
    );

    isa_ok( $Ack->dom, 'XML::LibXML::Document' );

    subtest 'attributes' => sub {
        isa_ok( $Ack->date, 'DateTime' );
        is( $Ack->customer_id,         'STAGE02',                    '->customer_id' );
        is( $Ack->company_name,        'STAGE02 SFTP test instance', '->company_name' );
        is( $Ack->original_message_id, '11246624',                   '->original_message_id' );
        is( $Ack->data_type,           'DTBPB',                      '->data_type' );
        is( $Ack->status,              'rejected',                   '->status' );

        is(
            $Ack->data_type_description,
            'DT:BPB incoming BPay Batch files',
            '->data_type_description',
        );

        is(
            $Ack->original_filename,
            'BPAY_Batch_Worked_Example_large.bpb',
            '->original_filename',
        );

        isa_ok( $Ack->issue->[ 0 ], 'Business::NAB::Acknowledgement::Issue' );
    };

    subtest 'methods' => sub {
        ok( $Ack->is_rejected,   '->is_rejected' );
        ok( !$Ack->is_accepted,  '! ->is_accepted' );
        ok( !$Ack->is_processed, '! ->is_processed' );
        ok( !$Ack->is_pending,   '! ->is_pending' );
        ok( !$Ack->is_declined,  '! ->is_declined' );
        ok( !$Ack->is_received,  '! ->is_received' );
        ok( !$Ack->is_held,      '! ->is_held' );
    };
};

$example_file = "$Bin/example_files/received_payments.ack";

subtest 'parse PaymentsAcknowledgement' => sub {

    isa_ok(
        my $Ack = $class->new_from_xml( $example_file ),
        $class,
    );

    isa_ok( $Ack->dom, 'XML::LibXML::Document' );

    subtest 'attributes' => sub {
        isa_ok( $Ack->date, 'DateTime' );
        is( $Ack->customer_id,         'STAGE02',                     '->customer_id' );
        is( $Ack->company_name,        'STAGE02 SFTP test instance',  '->company_name' );
        is( $Ack->original_message_id, '11250282',                    '->original_message_id' );
        is( $Ack->user_message,        'Payment status is PROCESSED', '->user_message' );
        is( $Ack->status,              'processed',                   '->status' );

        is(
            $Ack->detailed_message,
            'Payment has been successfully processed.',
            '->detailed_message',
        );

        is(
            $Ack->original_filename,
            'SAMP01AU_DTDC_0000001.aba',
            '->original_filename',
        );

        isa_ok( $Ack->issue->[ 0 ], 'Business::NAB::Acknowledgement::Issue' );
        is( scalar( $Ack->issue->@* ), 12, 'number of ->issue' );
        is(
            $Ack->issue->[ 9 ]->detail,
            'Funds have been reserved.',
            '->issue->detail',
        );
        is( $Ack->issue->[ 9 ]->code, '130001', '->issue->code' );
    };

    subtest 'methods' => sub {
        ok( !$Ack->is_rejected, '! ->is_rejected' );
        ok( !$Ack->is_accepted, '! ->is_accepted' );
        ok( $Ack->is_processed, '->is_processed' );
        ok( !$Ack->is_pending,  '! ->is_pending' );
        ok( !$Ack->is_declined, '! ->is_declined' );
        ok( !$Ack->is_received, '! ->is_received' );
        ok( !$Ack->is_held,     '! ->is_held' );
    };
};

$example_file = "$Bin/example_files/rejected_disbursement.ack";

subtest 'parse PaymentsAcknowledgement (rejected)' => sub {

    isa_ok(
        my $Ack = $class->new_from_xml( $example_file ),
        $class,
    );

    isa_ok( $Ack->dom, 'XML::LibXML::Document' );

    subtest 'attributes' => sub {
        isa_ok( $Ack->date, 'DateTime' );
        is( $Ack->customer_id,         'TEST01AU',             '->customer_id' );
        is( $Ack->company_name,        'Test Company Pty Ltd', '->company_name' );
        is( $Ack->original_message_id, '12334208',             '->original_message_id' );
        is(
            $Ack->user_message,
            'Payment 12,334,212 has been rejected.',
            '->user_message',
        );
        is( $Ack->status, 'rejected', '->status' );

        is(
            $Ack->detailed_message,
            'Payment 12,334,212 has completed validation and has been'
                . ' automatically rejected due to the following issues.',
            '->detailed_message',
        );

        is(
            $Ack->original_filename,
            'DISBURSEMENT_20250610_01.ABA.pgp',
            '->original_filename',
        );

        isa_ok( $Ack->issue->[ 0 ], 'Business::NAB::Acknowledgement::Issue' );
        is( scalar( $Ack->issue->@* ), 2, 'number of ->issue' );
        like(
            $Ack->issue->[ 1 ]->detail,
            qr/Invalid trailer record/,
            '->issue->detail',
        );
        is( $Ack->issue->[ 1 ]->code, 'error', '->issue->code' );
    };

    subtest 'methods' => sub {
        ok( $Ack->is_rejected,   '->is_rejected' );
        ok( !$Ack->is_accepted,  '! ->is_accepted' );
        ok( !$Ack->is_processed, '! ->is_processed' );
        ok( !$Ack->is_pending,   '! ->is_pending' );
        ok( !$Ack->is_declined,  '! ->is_declined' );
        ok( !$Ack->is_received,  '! ->is_received' );
        ok( !$Ack->is_held,      '! ->is_held' );
    };
};
done_testing();
