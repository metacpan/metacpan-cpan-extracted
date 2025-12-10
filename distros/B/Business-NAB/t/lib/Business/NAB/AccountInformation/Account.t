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

use_ok( "${class}::$_" ) for qw/ Account Transaction /;

subtest 'parse' => sub {

    $class = "${class}::Account";
    my $example_line = join(
        ',',
        "03",    "111111111", "AUD",   "015", "10000011", "100",
        "000",   "102",       "000",   "400", "000",      "402", "000", "500",
        "40011", "501",       "50011", "502", "200011",   "503", "200011",
        "965",   "000",       "966",   "050", "967",      "075", "968", "006",
        "969",   "017",
    );

    isa_ok(
        my $Account = $class->new_from_raw_record( $example_line ),
        $class,
    );

    is(
        $Account->commercial_account_number,
        '111111111',
        '->commercial_account_number',
    );

    is( $Account->currency_code, 'AUD', '->currency_code' );
    cmp_deeply(
        $Account->transaction_code_values,
        {
            '015' => '10000011',
            '100' => '000',
            '102' => '000',
            '400' => '000',
            '402' => '000',
            '500' => '40011',
            '501' => '50011',
            '502' => '200011',
            '503' => '200011',
            '965' => '000',
            '966' => '050',
            '967' => '075',
            '968' => '006',
            '969' => '017',
        },
        '->transaction_code_values',
    );

    $Account->add_transaction(
        Business::NAB::AccountInformation::Transaction->new_from_raw_record(
            '16,495,450000,0,0,INTERNET TRANSFER'
        )
    );
    isa_ok(
        $Account->transactions->[ 0 ],
        'Business::NAB::AccountInformation::Transaction',
    );

    my $bad_line = $example_line =~ s/^0/1/r;

    throws_ok(
        sub { $class->new_from_raw_record( $bad_line ); },
        qr/unsupported record type \(13\)/,
    );

    subtest 'validation' => sub {

        $Account->control_total_a( 10940203 );
        $Account->control_total_b( 10940055 );

        ok( $Account->validate_totals, '->validate_totals' );
    };
};

done_testing();
