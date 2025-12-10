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
        Payments
        Results
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

    is( $DetailRecord->biller_code,            '7773',      '->biller_code' );
    is( $DetailRecord->payment_account_bsb,    '083004',    '->payment_account_bsb' );
    is( $DetailRecord->payment_account_number, '035261665', '->payment_account_number' );
    is(
        $DetailRecord->customer_reference_number, '13863530005',
        '->customer_reference_number',
    );
    is( $DetailRecord->amount,                12345,         '->amount' );
    is( $DetailRecord->lodgement_reference_1, 'TransNo001',  '->lodgement_reference_1' );
    is( $DetailRecord->lodgement_reference_2, '',            '->lodgement_reference_2' );
    is( $DetailRecord->lodgement_reference_3, '',            '->lodgement_reference_3' );
    is( $DetailRecord->return_code,           '1001',        '->return_code' );
    is( $DetailRecord->return_code_desc,      'foo bar baz', '->return_code_desc' );
    ok( $DetailRecord->is_failed,      '->is_failed' );
    ok( !$DetailRecord->is_successful, '->is_successful' );

    my $bad_line = $example_line =~ s/^2/3/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(3\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $DetailRecord = $class->new(
            biller_code                  => '7773',
            payment_account_bsb          => '083004',
            payment_account_number       => '035261665',
            customer_reference_number    => '13863530005',
            amount                       => 12345,
            lodgement_reference_1        => 'TransNo001',
            return_code                  => '1001',
            return_code_desc             => 'foo bar baz',
            transaction_reference_number => 'NAB200704305102030UTC',
        ),
        $class,
    );

    is( $DetailRecord->to_record, $example_line, '->to_record' );
};

subtest 'type constraints' => sub {

    my %attributes = (
        biller_code                  => '7773',
        customer_reference_number    => '13863530005',
        lodgement_reference_1        => 'TransNo001',
        lodgement_reference_2        => 'TransNo001' x 2,
        lodgement_reference_3        => 'TransNo001' x 5,
        return_code                  => '1001',
        return_code_desc             => 'foo bar baz' x 3,
        transaction_reference_number => 'NABYYYYMMDDPHHMMSSTTT',
    );

    foreach my $attr ( sort keys( %attributes ) ) {

        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    $attr                  => $attributes{ $attr } x 5,
                    payment_account_bsb    => '083004',
                    payment_account_number => '035261665',
                    amount                 => 12345,
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
};

done_testing();

__DATA__
2000000777308300403526166513863530005         0000000012345TransNo001                                                                      1001foo bar baz                                       NAB200704305102030UTC
