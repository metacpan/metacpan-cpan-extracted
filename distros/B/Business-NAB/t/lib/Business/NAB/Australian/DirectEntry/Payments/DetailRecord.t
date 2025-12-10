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
        Payments
        DetailRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $DetailRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is( $DetailRecord->bsb_number,           '083-047',           '->bsb_number' );
    is( $DetailRecord->account_number,       '111111111',         '->account_number' );
    is( $DetailRecord->indicator,            ' ',                 '->indicator' );
    is( $DetailRecord->transaction_code,     '13',                '->transaction_code' );
    is( $DetailRecord->amount,               '0000130511',        '->amount' );
    is( $DetailRecord->title_of_account,     ' Beneficiary 1',    '->title_of_account' );
    is( $DetailRecord->lodgement_reference,  'FOR DEMONSTRATION', '->lodgement_reference' );
    is( $DetailRecord->bsb_number_trace,     '083-047',           '->bsb_number_trace' );
    is( $DetailRecord->account_number_trace, '123456789',         '->account_number_trace' );
    is( $DetailRecord->remitter_name,        'NAB SAMPLE  TEST',  '->remitter_name' );
    is( $DetailRecord->withholding_tax,      '00000000',          '->withholding_tax' );

    my $bad_line = $example_line =~ s/^1/2/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(2\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $DetailRecord = $class->new(
            bsb_number           => '083-047',
            account_number       => '111111111',
            transaction_code     => '13',
            amount               => 1305.11 * 100,
            title_of_account     => ' Beneficiary 1',
            lodgement_reference  => 'FOR DEMONSTRATION',
            bsb_number_trace     => '083-047',
            account_number_trace => '123456789',
            remitter_name        => 'NAB SAMPLE  TEST',
            withholding_tax      => '00000000',
        ),
        $class,
    );

    ok( $DetailRecord->is_debit,   '->is_debit' );
    ok( !$DetailRecord->is_credit, '! ->is_credit' );
    is( $DetailRecord->to_record, $example_line, '->to_record' );
};

subtest 'type constraints' => sub {

    my %attributes = (
        account_number       => '111111111',
        transaction_code     => '13',
        title_of_account     => ' Beneficiary 1',
        lodgement_reference  => 'FOR DEMONSTRATION',
        account_number_trace => '123456789',
        remitter_name        => 'NAB SAMPLE  TEST',
    );

    foreach my $attr ( sort keys( %attributes ) ) {

        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    $attr            => $attributes{ $attr } x 5,
                    amount           => 1305.11 * 100,
                    indicator        => 'Y',
                    bsb_number       => '083-047',
                    bsb_number_trace => '083-047',
                );
            },
            qr/(?:
                string\ provided\ for\ $attr\ was\ outside
                |
                \w+\ provided,\ \w+,\ is\ not\ valid
            )/ix,
            "length check on $attr",
        );
    }

    my %common = (
        amount           => 1305.11 * 100,
        bsb_number       => '083-047',
        bsb_number_trace => '083-047',
        withholding_tax  => 0,
    );

    throws_ok(
        sub {
            $class->new(
                %attributes,
                %common,
                bsb_number => 'XYZ-ABC',
            );
        },
        qr/The BSB provided, XYZ-ABC, does not match/,
    );

    foreach my $invalid_account (
        '         ',
        '000000000',
        '1234567890',
        '1234!6789',
    ) {
        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    %common,
                    account_number => $invalid_account,
                );
            },
            qr/is not valid/,
            "'$invalid_account' fails",
        );
    }

    foreach my $invalid_indicator (
        grep { !/[NTWXY]/ } 'A' .. 'Z',
    ) {
        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    %common,
                    indicator => $invalid_indicator,
                );
            },
            qr/does not match/,
            "'$invalid_indicator' fails",
        );
    }
};

subtest 'coercion' => sub {

    my $Obj = $class->new(
        account_number       => '111111111',
        transaction_code     => '13',
        title_of_account     => ' Beneficiary 1',
        lodgement_reference  => 'FOR DEMONSTRATION',
        account_number_trace => '123456789',
        remitter_name        => 'NAB SAMPLE  TEST',
        amount               => 1305.11 * 100,
        indicator            => 'Y',
        bsb_number           => '083047',
        bsb_number_trace     => '083947',
    );

    is( $Obj->bsb_number, '083-047', '->bsb_number' );
    is(
        $Obj->bsb_number_trace,
        '083-947',
        '->bsb_number_trace',
    );
};

done_testing();

__DATA__
1083-047111111111 130000130511 Beneficiary 1                  FOR DEMONSTRATION 083-047123456789NAB SAMPLE  TEST00000000
