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

    is( $TrailerRecord->total_number_of_payments, 5,      '->net_total_amount' );
    is( $TrailerRecord->total_value_of_payments,  189914, '->record_count' );

    my $bad_line = $example_line =~ s/^9/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(1\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $TotalRecord = $class->new(
            total_value_of_payments  => 189914,
            total_number_of_payments => 5,
        ),
        $class,
    );

    is( $TotalRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
900000000050000000189914                                                                                                                        
