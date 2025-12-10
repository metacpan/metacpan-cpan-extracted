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
        Report
        /,
);

use_ok( $class );

my $example_file = "$Bin/../../example_files/payments_direct_debit.rpt";

subtest 'parse' => sub {

    isa_ok(
        my $Report = $class->new_from_file( $example_file ),
        $class,
    );

    is(
        $Report->original_filename,
        'MultiSAmpleDC_pressinvalid.txt',
        '->original_filename',
    );
    is( $Report->status, 'PROCESSED', '->status' );

    isa_ok(
        $Report->header_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Report::HeaderRecord',
    );

    is( scalar( $Report->payment_record->@* ), 3, 'count of payment_record' );
    is( scalar( $Report->value_summary->@* ),  2, 'count of value_summary' );
    is( scalar( $Report->failed_record->@* ),  1, 'count of failed_record' );
    is( scalar( $Report->failed_summary->@* ), 1, 'count of failed_summary' );

    isa_ok(
        $Report->trailer_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Report::TrailerRecord',
    );

    isa_ok(
        $Report->disclaimer_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Report::DisclaimerRecord',
    );

    subtest 'round trip' => sub {

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Report->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

};

subtest 'instantiation + add attributes' => sub {

    isa_ok(
        my $Report = $class->new,
        $class,
    );

    $Report->add_header_record( {
        bank_name        => 'NATIONAL AUSTRALIA BANK',
        product_name     => 'Direct Link',
        report_name      => 'Direct Link - Direct Credit Disbursement Report',
        run_date         => '30012014',
        run_time         => '163707',
        fund_id          => 'SITDL',
        customer_name    => 'Automation',
        import_file_name => 'MultiSAmpleDC_pressinvalid.txt',
        payment_date     => '30012014',
        batch_no_links   => '10339867',
        export_file_name => 'DCtest',
        de_user_id       => '342180',
        me_id            => undef,
        report_file_name => 'MultiSAmpleDC_pressinvalid.txt_10339867.dis',
    } );

    $Report->add_payment_record( {
        payment_type     => 'DNN',
        lodgement_ref    => 'DebitLodgementRef',
        amount           => 1000,
        currency         => 'AUD',
        credit_debit     => 'CR',
        title_of_account => 'Test NAB Account',
        bsb_number       => '084737',
        account_number   => $_,
    } ) for ( qw/ 576512164 576512172 / );

    $Report->add_payment_record( {
        payment_type     => 'DNN',
        lodgement_ref    => 'CredtLodgementRef',
        amount           => 3000,
        currency         => 'AUD',
        credit_debit     => 'DR',
        title_of_account => 'Other ANZ Account',
        bsb_number       => '084737',
        account_number   => $_,
    } ) for ( qw/ 576510388 / );

    $Report->add_failed_record( {
        sub_trancode         => 'UXD',
        payment_type         => 'DEN',
        lodgement_ref        => 'DebitLodgementRef',
        amount               => 1000,
        currency             => 'AUD',
        credit_debit         => 'CR',
        title_of_account     => 'Test NAB Account',
        bsb_number           => '084737',
        account_number       => '123456789',
        failed_reason_code   => '',
        reason_for_rejection => 'The Account Number 123456789 is Invalid.',
    } );

    subtest '->to_file (lacking total/summary records)' => sub {
        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Report->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

    $Report->add_value_summary( {
        record_type     => '54',
        sub_trancode    => 'UVD',
        number_of_items => 2,
        total_of_items  => 2000,
    } );

    $Report->add_value_summary( {
        record_type     => '58',
        sub_trancode    => 'UVD',
        number_of_items => 1,
        total_of_items  => 3000,
    } );

    $Report->add_failed_summary( {
        sub_trancode                 => 'UXS',
        number_of_items              => 1,
        failed_item_treatment_option => 1,
        text                         => 'Failed items will be returned as individual '
            . 'items to your trace account.',
        total_of_items => 1000,
    } );

    $Report->add_trailer_record( {
        net_file_total          => 0,
        credit_file_total       => 3000,
        debit_file_total        => 3000,
        total_number_of_records => 4,
    } );

    subtest '->to_file (with total/summary records)' => sub {
        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Report->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };
};

done_testing();
