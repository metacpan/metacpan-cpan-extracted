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
        DescriptiveRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $DescriptiveRecord = $class->new_from_record( $example_line ),
        $class,
    );

    is( $DescriptiveRecord->reel_sequence_number, 1,          '->reel_sequence_number' );
    is( $DescriptiveRecord->institution_name,     'NAB',      '->institution_name' );
    is( $DescriptiveRecord->user_name,            'NAB TEST', '->user_name' );
    is( $DescriptiveRecord->user_number,          123456,     '->user_number' );
    is( $DescriptiveRecord->description,          'DrDebit',  '->description' );
    isa_ok( $DescriptiveRecord->process_date, 'DateTime' );
    is( $DescriptiveRecord->process_date->ymd( '' ), '20231201', '->process_date' );

    my $bad_line = $example_line =~ s/^0/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(1\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $DescriptiveRecord = $class->new(
            reel_sequence_number => '01',
            institution_name     => 'NAB',
            user_name            => 'NAB TEST',
            user_number          => 123456,
            description          => 'DrDebit',
            process_date         => '011223',
        ),
        $class,
    );

    is( $DescriptiveRecord->reel_sequence_number, 1, 'trigger fires' );
    isa_ok( $DescriptiveRecord->process_date, 'DateTime', 'coercion of value' );

    is( $DescriptiveRecord->to_record, $example_line, '->to_record' );
};

subtest 'length constraints' => sub {

    my %attributes = (
        reel_sequence_number => '01',
        institution_name     => 'NAB',
        user_name            => 'NAB TEST',
        user_number          => 123456,
        description          => 'DrDebit',
    );

    foreach my $attr ( sort keys( %attributes ) ) {

        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    process_date => '011223',
                    $attr        => $attributes{ $attr } x 5,
                );
            },
            qr/string provided for $attr was outside/,
        );
    }
};

subtest 'BECS EBCDIC constraints' => sub {

    my %attributes = (
        institution_name => 'NÀB',
        user_name        => 'NÀB TEST',
        description      => 'DrDébit',
    );

    foreach my $attr ( sort keys( %attributes ) ) {

        throws_ok(
            sub {
                $class->new(
                    %attributes,
                    reel_sequence_number => '01',
                    process_date         => '011223',
                    user_number          => 123456,
                    $attr                => $attributes{ $attr },
                );
            },
            qr/contains non BECS EBCDIC chars/,
        );
    }
};

done_testing();

__DATA__
0                 01NAB       NAB TEST                  123456DrDebit     011223                                        
