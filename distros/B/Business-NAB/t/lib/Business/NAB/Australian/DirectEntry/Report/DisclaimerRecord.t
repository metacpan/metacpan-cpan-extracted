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
        DisclaimerRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $DisclaimerRecord = $class->new_from_record( $example_line ),
        $class,
    );

    my $bad_line = $example_line =~ s/^1/8/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(800\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $DisclaimerRecord = $class->new(
            text => '(c) 2012 National Australia Bank Limit ABN 12 004 044 937',
        ),
        $class,
    );

    is( $DisclaimerRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
100,(c) 2012 National Australia Bank Limit ABN 12 004 044 937
