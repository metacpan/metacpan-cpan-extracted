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
        HeaderRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $HeaderRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is( $HeaderRecord->bpay_batch_user_id, '123456', '->bpay_batch_user_id' );
    is(
        $HeaderRecord->customer_short_name,
        'TEST CUSTOMER',
        '->customer_short_name',
    );
    isa_ok( $HeaderRecord->processing_date, 'DateTime', 'coercion of value' );
    is( $HeaderRecord->processing_date->ymd, '2007-04-30', '->processing_date' );

    my $bad_line = $example_line =~ s/^1/2/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(2\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $HeaderRecord = $class->new(
            bpay_batch_user_id  => '123456',
            customer_short_name => 'TEST CUSTOMER',
            processing_date     => DateTime->new(
                year  => 2007,
                month => 4,
                day   => 30,
            ),
        ),
        $class,
    );

    isa_ok( $HeaderRecord->processing_date, 'DateTime', 'coercion of value' );
    is( $HeaderRecord->to_record, $example_line, '->to_record' );
};

subtest 'length constraints' => sub {

    my %attributes = (
        bpay_batch_user_id  => '123456',
        customer_short_name => 'TEST CUSTOMER',
    );

    foreach my $attr ( sort keys( %attributes ) ) {

        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    processing_date => '20070430',
                    $attr           => $attributes{ $attr } x 5,
                );
            },
            qr/string provided for $attr was outside/,
        );
    }
};

done_testing();

__DATA__
1123456          TEST CUSTOMER       20070430                                                                                                   
