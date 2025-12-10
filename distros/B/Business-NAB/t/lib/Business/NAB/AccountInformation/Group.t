#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::Most;
use FindBin qw/ $Bin /;
use File::Temp;
use Test::File::Contents;
use Test::Warnings;

my $class = join(
    '::',
    qw/
        Business
        NAB
        AccountInformation
        /,
);

use_ok( "${class}::$_" ) for qw/ Group Account /;

subtest 'parse' => sub {

    $class = "${class}::Group";
    my $example_line = '02,BNZA,NATAAU3M,1,210521,0000';
    isa_ok(
        my $Group = $class->new_from_raw_record( $example_line ),
        $class,
    );

    is(
        $Group->ultimate_receiver_identification,
        'BNZA',
        '->ultimate_receiver_identification',
    );

    is(
        $Group->originator_identification,
        'NATAAU3M',
        '->originator_identification',
    );
    is( $Group->additional_field, undef, '->additional_field' );
    isa_ok( $Group->as_of_date, 'DateTime' );
    is( $Group->as_of_date->ymd, '2021-05-21', '->as_of_date' );

    $Group->add_account( Business::NAB::AccountInformation::Account->new(
        commercial_account_number => '12345678',
        currency_code             => 'AUD',
        transaction_code_values   => {},
        control_total_a           => 10940203,
        control_total_b           => 10940055,
    ) );
    isa_ok(
        $Group->accounts->[ 0 ],
        'Business::NAB::AccountInformation::Account',
    );

    my $bad_line = $example_line =~ s/^0/1/r;

    throws_ok(
        sub { $class->new_from_raw_record( $bad_line ); },
        qr/unsupported record type \(12\)/,
    );

    subtest 'validation' => sub {

        $Group->control_total_a( 10940203 );
        $Group->control_total_b( 10940055 );
        $Group->number_of_accounts( 1 );

        ok( $Group->validate_totals, '->validate_totals' );
    };
};

done_testing();
