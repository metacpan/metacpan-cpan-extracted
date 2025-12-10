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
        TrailerRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $TrailerRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is(
        $TrailerRecord->total_number_of_successful_payments,
        2,
        '->total_number_of_successful_payments',
    );

    is(
        $TrailerRecord->total_value_of_successful_payments,
        9914,
        '->total_value_of_successful_payments',
    );
    is(
        $TrailerRecord->total_number_of_declined_payments,
        3,
        '->total_number_of_declined_payments',
    );

    is(
        $TrailerRecord->total_value_of_declined_payments,
        180001,
        '->total_value_of_declined_payments',
    );
    is(
        $TrailerRecord->total_number_of_payments,
        5,
        '->total_number_of_payments',
    );

    is(
        $TrailerRecord->total_value_of_payments,
        189915,
        '->total_value_of_payments',
    );

    my $bad_line = $example_line =~ s/^9/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(1\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $TotalRecord = $class->new(
            total_value_of_payments             => 189915,
            total_number_of_payments            => 5,
            total_number_of_successful_payments => 2,
            total_value_of_successful_payments  => 9914,
            total_number_of_declined_payments   => 3,
            total_value_of_declined_payments    => 180001,
        ),
        $class,
    );

    is( $TotalRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
9000000000200000000099140000000003000000018000100000000050000000189915
