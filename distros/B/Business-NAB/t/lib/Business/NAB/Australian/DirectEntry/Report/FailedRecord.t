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
        Australian
        DirectEntry
        Report
        FailedRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $FailedRecord = $class->new_from_record( $example_line ),
        $class,
    );

    my $bad_line = $example_line =~ s/^6/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(11\)/,
    );
};

subtest 'instantiation (credit)' => sub {

    isa_ok(
        my $FailedRecord = $class->new(
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
        ),
        $class,
    );

    is( $FailedRecord->to_record, $example_line, '->to_record' );
    ok( $FailedRecord->is_credit, '->is_credit' );
    ok( !$FailedRecord->is_debit, '->is_debit' );
};

done_testing();

__DATA__
61,UXD,DEN,DebitLodgementRef,1000,AUD,CR,Test NAB Account,084-737,123456789,,The Account Number 123456789 is Invalid.
