use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Data::Fake::Dates;

subtest 'fake epochs' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_past_epoch->();
        my $now = time();
        like( $got, qr/^\d+$/, "fake_past_epoch looks like integer" );
        ok( $got <= $now, "fake_past_epoch ($got) is in the past" );
    }
    for my $i ( 0 .. 5 ) {
        my $now = time();
        my $got = fake_future_epoch->();
        like( $got, qr/^\d+$/, "fake_future_epoch looks like integer" );
        ok( $got >= $now, "fake_future_epoch ($got) is in the future" );
    }
};

subtest 'fake datetimes' => sub {
    my $date_re    = qr/\d{4}-\d{2}-\d{2}/;
    my $time_re    = qr/\d{2}:\d{2}:\d{2}Z/;
    my $iso8601_re = qr/^${date_re}T${time_re}$/;
    for my $i ( 0 .. 5 ) {
        my $got = fake_past_datetime->();
        like( $got, $iso8601_re, "fake_past_datetime ($got) looks like ISO-8601" );
    }
    for my $i ( 0 .. 5 ) {
        my $now = time();
        my $got = fake_future_datetime->();
        like( $got, $iso8601_re, "fake_future_datetime ($got) looks like ISO-8601" );
    }

    # formats
    my $got = fake_past_datetime("%Y-%m-%d")->();
    like( $got, qr/^$date_re$/, "fake_past_datetime('%Y-%m-%d') ($got)" );
    $got = fake_future_datetime("%Y-%m-%d")->();
    like( $got, qr/^$date_re$/, "fake_future_datetime('%Y-%m-%d') ($got)" );
};

done_testing;
#
# This file is part of Data-Fake
#
# This software is Copyright (c) 2015 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et tw=75:
