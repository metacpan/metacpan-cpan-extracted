#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::More;

use Data::Tersify qw(tersify);

test_datetime();

done_testing();

sub test_datetime {
    my $just_date = DateTime->new(year => 2017, month => 8, day => 17);
    my $full = DateTime->new(
        year   => 2017,
        month  => 8,
        day    => 17,
        hour   => 15,
        minute => 9,
        second => 23
    );
    my $re_refaddr = qr{ \( 0x [0-9a-f]+ \) }x;
    my $original = {
        day        => $just_date,
        exact_time => $full,
    };
    my $tersified = tersify($original);
    like(
        ${ $tersified->{day} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 $}x,
        'A DateTime with just day components is summarised as ymd'
    );
    like(
        ${ $tersified->{exact_time} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 \s 15:09:23$}x,
        'A fuller DateTime is summarised as ymd hms'
    );
}