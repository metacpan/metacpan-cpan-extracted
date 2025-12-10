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
        File
        /,
);

use_ok( $class );

my $example_file = "$Bin/../example_files/account_information.nai";

subtest 'reconstruct_file_records (NAI)' => sub {

    my $reconstructed_file_records = $class->reconstruct_file_records(
        $example_file
    );

    is(
        $reconstructed_file_records->{ raw_record_count },
        29,
        'raw_record_count',
    );

    cmp_deeply(
        $reconstructed_file_records->{ records },
        [
            [ "01", "",     "BNZA",     "210521", "0400", "1", "78", "78" ],
            [ "02", "BNZA", "NATAAU3M", "1", "210521", "0000" ],
            [
                "03",    "111111111", "AUD",   "015", "10000011", "100",
                "000",   "102",       "000",   "400", "000",      "402", "000", "500",
                "40011", "501",       "50011", "502", "200011",   "503", "200011",
                "965",   "000",       "966",   "050", "967",      "075", "968", "006",
                "969",   "017",
            ],
            [ "49", "10490203", "10490055" ],
            [
                "03",    "222222222", "AUD",   "015", "10000009", "100",
                "000",   "102",       "000",   "400", "125555",   "402", "400", "500",
                "40009", "501",       "50009", "502", "200009",   "503", "200009",
                "965",   "000",       "966",   "000", "967",      "000", "968", "000",
                "969",   "070",
            ],
            [
                "16", "495", "450000", "0", "0", "INTERNET TRANSFER",
                "Internet Transfer PYMT-ID 999999999 AA to 123",
            ],
            [
                "16", "495", "150000", "0", "0", "INTERNET BILL PAYMNT",
                "INTERNET BPAY PMT 111111111111 NARRATIVEINFO",
            ],
            [
                "16", "495", "1700000", "0", "0", "INTERNET TRANSFER",
                "Internet Transfer PYMT-ID 12346789 O1 to 123",
            ],
            [
                "16", "495", "860475", "0", "0", "INTERNET TRANSFER",
                "Internet Transfer PYMT-ID 222222222 Narrative",
            ],
            [ "49", "13776545", "13776475" ],
            [
                "03",    "333333333", "AUD",   "015", "10000010", "100",
                "000",   "102",       "000",   "400", "47310",    "402", "200", "500",
                "40010", "501",       "50010", "502", "200010",   "503", "200010",
                "965",   "000",       "966",   "187", "967",      "000", "968", "000",
                "969",   "031",
            ],
            [ "16", "920",      "541105", "0", "0", "Payment Narrative 123456" ],
            [ "16", "595",      "6585",   "0", "0", "MERCHNAME" ],
            [ "49", "11085468", "11085250" ],
            [ "98", "35352216", "3", "35351780" ],
            [ "99", "35352216", "1", "29", "35351780" ],
        ],
    );
};

my $File;

subtest 'new_from_file (NAI)' => sub {

    isa_ok(
        $File = $class->new_from_file( $example_file ),
        $class,
    );

    ok( !$File->is_bai2, '->is_bai2' );
    is( $File->sender_identification,   '',     '->sender_identification' );
    is( $File->receiver_identification, 'BNZA', '->receiver_identification' );
    isa_ok( $File->file_creation_date, 'DateTime' );
    is( $File->file_creation_date->ymd, '2021-05-21', '->file_creation_date' );
    is( $File->file_creation_time,      '0400',       '->file_creation_time' );
    is( $File->file_sequence_number,    1,            '->file_sequence_number' );
    is( $File->physical_record_length,  78,           '->physical_record_length' );
    is( $File->blocking_factor,         78,           '->blocking_factor' );

    is( $File->control_total_a,   35352216, '->control_total_a' );
    is( $File->number_of_groups,  1,        '->number_of_groups' );
    is( $File->number_of_records, 29,       '->number_of_records' );
    is( $File->control_total_b,   35351780, '->control_total_b' );

    ok( $File->validate_totals, '->validate_totals' );

    subtest '->groups' => sub {

        is( scalar( $File->groups->@* ), 1, '->groups (count)' );
        isa_ok(
            my $Group = $File->groups->[ 0 ],
            'Business::NAB::AccountInformation::Group',
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
        is( $Group->as_of_date->ymd,    '2021-05-21', '->as_of_date' );
        is( $Group->control_total_a,    35352216,     '->control_total_a' );
        is( $Group->number_of_accounts, 3,            '->number_of_accounts' );
        is( $Group->control_total_b,    35351780,     '->control_total_b' );

        subtest '->accounts' => sub {

            is( scalar( $Group->accounts->@* ), 3, '->accounts (count)' );
            isa_ok(
                my $Account = $Group->accounts->[ 1 ],
                'Business::NAB::AccountInformation::Account',
            );

            ok( $Account->validate_totals, '->validate_totals' );

            subtest '->transactions' => sub {

                is(
                    scalar( $Account->transactions->@* ),
                    4,
                    '->transactions (count)',
                );
                isa_ok(
                    my $Transaction = $Account->transactions->[ 0 ],
                    'Business::NAB::AccountInformation::Transaction',
                );

                ok( $Account->validate_totals, '->validate_totals' );
            };
        };
    };

};

$example_file = "$Bin/../example_files/account_information.bai";

subtest 'new_from_file (BAI2)' => sub {

    isa_ok(
        $File = $class->new_from_file( $example_file ),
        $class,
    );

    ok( $File->is_bai2, '->is_bai2' );
    is( $File->sender_identification,   'NATAAU3M', '->sender_identification' );
    is( $File->receiver_identification, 'BNZA',     '->receiver_identification' );
    isa_ok( $File->file_creation_date, 'DateTime' );
    is( $File->file_creation_date->ymd, '2021-05-21', '->file_creation_date' );
    is( $File->file_creation_time,      '0400',       '->file_creation_time' );
    is( $File->file_sequence_number,    2,            '->file_sequence_number' );
    is( $File->physical_record_length,  0,            '->physical_record_length' );
    is( $File->blocking_factor,         0,            '->blocking_factor' );

    is( $File->control_total_a,   35352216, '->control_total_a' );
    is( $File->number_of_groups,  1,        '->number_of_groups' );
    is( $File->number_of_records, 29,       '->number_of_records' );
    is( $File->control_total_b,   undef,    '->control_total_b' );

    ok( $File->validate_totals, '->validate_totals' );

    subtest '->groups' => sub {

        is( scalar( $File->groups->@* ), 1, '->groups (count)' );
        isa_ok(
            my $Group = $File->groups->[ 0 ],
            'Business::NAB::AccountInformation::Group',
        );

        is(
            $Group->ultimate_receiver_identification,
            'BNZA',
            '->ultimate_receiver_identification',
        );
        is(
            $Group->originator_identification,
            '999-999',
            '->originator_identification',
        );
        is( $Group->additional_field, '', '->additional_field' );
        isa_ok( $Group->as_of_date, 'DateTime' );
        is( $Group->as_of_date->ymd,    '2021-05-21', '->as_of_date' );
        is( $Group->control_total_a,    35352216,     '->control_total_a' );
        is( $Group->number_of_accounts, 3,            '->number_of_accounts' );
        is( $Group->control_total_b,    undef,        '->control_total_b' );
        is( $Group->number_of_records,  27,           '->number_of_records' );

        subtest '->accounts' => sub {

            is( scalar( $Group->accounts->@* ), 3, '->accounts (count)' );
            isa_ok(
                my $Account = $Group->accounts->[ 1 ],
                'Business::NAB::AccountInformation::Account',
            );

            ok(
                $Account->validate_totals( $File->is_bai2 ),
                '->validate_totals',
            );

            subtest '->transactions' => sub {

                is(
                    scalar( $Account->transactions->@* ),
                    4,
                    '->transactions (count)',
                );
                isa_ok(
                    my $Transaction = $Account->transactions->[ 0 ],
                    'Business::NAB::AccountInformation::Transaction',
                );

                ok(
                    $Account->validate_totals( $File->is_bai2 ),
                    '->validate_totals',
                );
            };
        };
    };

};

done_testing();
