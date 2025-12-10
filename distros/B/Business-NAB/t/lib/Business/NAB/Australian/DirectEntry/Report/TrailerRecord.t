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

    my $bad_line = $example_line =~ s/^9/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(19\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $TrailerRecord = $class->new(
            net_file_total          => 0,
            credit_file_total       => 3000,
            debit_file_total        => 3000,
            total_number_of_records => 4,
        ),
        $class,
    );

    is( $TrailerRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
99,0,3000,3000,4
