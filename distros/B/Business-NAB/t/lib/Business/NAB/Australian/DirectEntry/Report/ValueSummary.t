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
        ValueSummary
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $ValueSummary = $class->new_from_record( $example_line ),
        $class,
    );

    ok( $ValueSummary->is_credit,  '->is_credit' );
    ok( !$ValueSummary->is_debit,  '! ->is_debit' );
    ok( !$ValueSummary->is_failed, '->is_failed' );

    my $bad_line = $example_line =~ s/^5/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(14\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $ValueSummary = $class->new(
            sub_trancode    => 'UVD',
            number_of_items => 2,
            total_of_items  => 2000,
        ),
        $class,
    );

    is( $ValueSummary->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
54,UVD,2,2000
