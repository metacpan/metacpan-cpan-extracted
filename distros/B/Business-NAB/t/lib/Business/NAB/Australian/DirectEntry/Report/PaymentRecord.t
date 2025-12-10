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
        PaymentRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $PaymentRecord = $class->new_from_record( $example_line ),
        $class,
    );

    my $bad_line = $example_line =~ s/^5/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(13\)/,
    );
};

subtest 'instantiation (credit)' => sub {

    isa_ok(
        my $PaymentRecord = $class->new(
            payment_type     => 'DNN',
            lodgement_ref    => 'DebitLodgementRef',
            amount           => 1000,
            currency         => 'AUD',
            credit_debit     => 'CR',
            title_of_account => 'Test NAB Account',
            bsb_number       => '084737',
            account_number   => '576512164',
        ),
        $class,
    );

    is( $PaymentRecord->to_record, $example_line, '->to_record' );
    ok( $PaymentRecord->is_credit, '->is_credit' );
    ok( !$PaymentRecord->is_debit, '->is_debit' );
};

subtest 'instantiation (debit)' => sub {

    isa_ok(
        my $PaymentRecord = $class->new(
            payment_type     => 'DNN',
            lodgement_ref    => 'DebitLodgementRef',
            amount           => 1000,
            currency         => 'AUD',
            credit_debit     => 'DR',
            title_of_account => 'Test NAB Account',
            bsb_number       => '084737',
            account_number   => '576512164',
        ),
        $class,
    );

    $example_line =~ s/^53/57/;
    $example_line =~ s/,CR,/,DR,/;

    is( $PaymentRecord->to_record, $example_line, '->to_record' );
    ok( !$PaymentRecord->is_credit, '->is_credit' );
    ok( $PaymentRecord->is_debit,   '->is_debit' );
};

done_testing();

__DATA__
53,DNN,DebitLodgementRef,1000,AUD,CR,Test NAB Account,084-737,576512164
