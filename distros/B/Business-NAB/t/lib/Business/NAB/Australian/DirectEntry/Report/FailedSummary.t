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
        FailedSummary
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $FailedSummary = $class->new_from_record( $example_line ),
        $class,
    );

    my $bad_line = $example_line =~ s/^6/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(12\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $FailedSummary = $class->new(
            sub_trancode                 => 'UXS',
            number_of_items              => 1,
            total_of_items               => 1000,
            failed_item_treatment_option => 1,
            text => 'Failed items will be returned as individual items to your trace account.',
        ),
        $class,
    );

    is( $FailedSummary->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
62,UXS,1,1000,1,Failed items will be returned as individual items to your trace account.
