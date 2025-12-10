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
        Australian
        DirectEntry
        Returns
        /,
);

use_ok( $class );

my $example_file = "$Bin/../../example_files/dtret01_614409_20231031_210606075.1.txt";

subtest 'parse' => sub {

    isa_ok(
        my $Returns = $class->new_from_file( $example_file ),
        $class,
    );

    isa_ok(
        $Returns->descriptive_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Returns::DescriptiveRecord',
    );

    is( scalar( $Returns->detail_record->@* ), 14, 'count of detail_record' );

    subtest '->detail_record' => sub {
        isa_ok(
            my $DetailRecord = $Returns->detail_record->[ 3 ],
            'Business::NAB::Australian::DirectEntry::Returns::DetailRecord',
        );

        is(
            $DetailRecord->return_code_description,
            'Refer to customer',
            '->return_code_description',
        );

        is( $DetailRecord->return_code, '6', '->return_code' );
        is(
            $DetailRecord->original_day_of_processing,
            '24',
            '->original_day_of_processing',
        );

        is(
            $DetailRecord->original_user_id_number,
            '614409',
            '->original_user_id_number',
        );
    };

    isa_ok(
        $Returns->total_record->[ 0 ],
        'Business::NAB::Australian::DirectEntry::Returns::TotalRecord',
    );

    subtest 'round trip' => sub {

        my $fh       = File::Temp->new;
        my $tmp_file = $fh->filename;
        $Returns->to_file( $tmp_file );

        files_eq_or_diff( $tmp_file, $example_file, { style => 'Unified' } );
    };

};

done_testing();
