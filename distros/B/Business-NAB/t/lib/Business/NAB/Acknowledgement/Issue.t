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
        Acknowledgement
        Issue
        /,
);

use_ok( $class );

subtest 'instantiation' => sub {

    isa_ok(
        my $Issue = $class->new( code => 1, detail => 'foo' ),
        $class,
    );

    subtest 'attributes' => sub {
        is( $Issue->code,   1,     '->code' );
        is( $Issue->detail, 'foo', '->detail' );
    };
};

subtest 'type code handling' => sub {

    ok( $class->new( type => 'error' )->is_error,       '->is_error' );
    ok( $class->new( type => 'warning' )->is_warning,   '->is_warning' );
    ok( $class->new( type => 2025 )->is_uploaded,       '->is_uploaded' );
    ok( $class->new( type => 5013 )->is_corrected,      '->is_corrected' );
    ok( $class->new( type => 6010 )->is_ready_for_auth, '->is_ready_for_auth' );
    ok( $class->new( type => 6014 )->is_authorised,     '->is_authorised' );
    ok( $class->new( type => 50040 )->is_changed,       '->is_changed' );
    ok( $class->new( type => 104503 )->is_validated,    '->is_validated' );
    ok( $class->new( type => 104506 )->is_invalid,      '->is_invalid' );
    ok( $class->new( type => 112215 )->is_invalid,      '->is_invalid' );
    ok( $class->new( type => 130000 )->is_checked,      '->is_checked' );
    ok( $class->new( type => 130001 )->is_reserved,     '->is_reserved' );
    ok( $class->new( type => 130003 )->is_referred,     '->is_referred' );
    ok( $class->new( type => 133610 )->is_failed,       '->is_failed' );
    ok( $class->new( type => 140000 )->is_reserved,     '->is_reserved' );
    ok( $class->new( type => 180004 )->is_rejected,     '->is_rejected' );
    ok( $class->new( type => 180054 )->is_referred,     '->is_referred' );
    ok( $class->new( type => 180055 )->is_approved,     '->is_approved' );
    ok( $class->new( type => 180057 )->is_approved,     '->is_approved' );
    ok( $class->new( type => 181002 )->is_validated,    '->is_validated' );
    ok( $class->new( type => 181004 )->is_invalid,      '->is_invalid' );
    ok(
        $class->new( type => 181015 )->is_partially_failed,
        '->is_partially_failed',
    );

    ok( $class->new( type => 181016 )->is_invalid,    '->is_invalid' );
    ok( $class->new( type => 181026 )->is_invalid,    '->is_invalid' );
    ok( $class->new( type => 181100 )->is_held,       '->is_held' );
    ok( $class->new( type => 181104 )->is_released,   '->is_released' );
    ok( $class->new( type => 181253 )->is_authorised, '->is_authorised' );
    ok( $class->new( type => 181258 )->is_rejected,   '->is_rejected' );
    ok( $class->new( type => 181259 )->is_authorised, '->is_authorised' );
    ok( $class->new( type => 181301 )->is_ready,      '->is_ready' );
    ok( $class->new( type => 190108 )->is_invalid,    '->is_invalid' );
    ok( $class->new( type => 194500 )->is_report,     '->is_report' );
    ok( $class->new( type => 290049 )->is_report,     '->is_report' );

    ok( !$class->new( type => 181301 )->is_report,   '! ->is_report' );
    ok( !$class->new( type => 'error' )->is_warning, '! ->is_error' );
    ok( !$class->new( type => 'warning' )->is_error, '! ->is_warning' );
};

done_testing();
