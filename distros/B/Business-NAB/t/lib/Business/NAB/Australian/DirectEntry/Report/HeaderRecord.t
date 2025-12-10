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
        HeaderRecord
        /,
);

use_ok( $class );

chomp( my $example_line = <DATA> );

subtest 'parse' => sub {

    isa_ok(
        my $HeaderRecord = $class->new_from_record( $example_line ),
        $class,
    );

    isa_ok( $HeaderRecord->run_date, 'DateTime' );
    is( $HeaderRecord->run_date->ymd( '' ), '20140130', '->run_date' );

    my $bad_line = $example_line =~ s/^0/1/r;

    throws_ok(
        sub { $class->new_from_record( $bad_line ); },
        qr/unsupported record type \(10\)/,
    );
};

subtest 'instantiation' => sub {

    isa_ok(
        my $HeaderRecord = $class->new(
            bank_name        => 'NATIONAL AUSTRALIA BANK',
            product_name     => 'Direct Link',
            report_name      => 'Direct Link - Direct Credit Disbursement Report',
            run_date         => '30012014',
            run_time         => '163707',
            fund_id          => 'SITDL',
            customer_name    => 'Automation',
            import_file_name => 'MultiSAmpleDC_pressinvalid.txt',
            payment_date     => '30012014',
            batch_no_links   => '10339867',
            export_file_name => 'DCtest',
            de_user_id       => '342180',
            me_id            => undef,
            report_file_name => 'MultiSAmpleDC_pressinvalid.txt_10339867.dis',
        ),
        $class,
    );

    isa_ok( $HeaderRecord->run_date, 'DateTime', 'coercion of value' );
    is( $HeaderRecord->to_record, $example_line, '->to_record' );
};

done_testing();

__DATA__
00,NATIONAL AUSTRALIA BANK,Direct Link,Direct Link - Direct Credit Disbursement Report,30012014,163707,SITDL,Automation,MultiSAmpleDC_pressinvalid.txt,30012014,10339867,DCtest,342180,,MultiSAmpleDC_pressinvalid.txt_10339867.dis
