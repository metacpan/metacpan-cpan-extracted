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
        TotalRecord
    /
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $TotalRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is( $TotalRecord->bsb_number,'999-999','->bsb_number' );
    is( $TotalRecord->net_total_amount,0,'->net_total_amount' );
    is( $TotalRecord->credit_total_amount,5,'->credit_total_amount' );
    is( $TotalRecord->debit_total_amount,5,'->debit_total_amount' );
    is( $TotalRecord->record_count,6,'->record_count' );

    my $bad_line = $example_line =~ s/^7/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(1\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $TotalRecord = $class->new(
            bsb_number => '999-999',
            net_total_amount => 0,
            credit_total_amount => 5,
            debit_total_amount => 5,
            record_count => 6,
        ),
        $class
    );

    is( $TotalRecord->to_record,$example_line,'->to_record' );
};

done_testing();

__DATA__
7999-999            000000000000000000050000000005                        000006                                        
