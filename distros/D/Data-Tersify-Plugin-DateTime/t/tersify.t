#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::More;

use Data::Tersify qw(tersify);

test_datetime();

done_testing();

sub test_datetime {
    my %verbose = (
        just_date           => DateTime->new(
            year      => 2017, month  => 8,  day    => 17,
            time_zone => 'floating'
        ),
        full                => DateTime->new(
            year      => 2017, month  => 8,  day    => 17,
            hour      => 15,   minute => 9,  second => 23,
            time_zone => 'floating',
        ),
        full_with_time_zone => DateTime->new(
            year      => 1789, month  => 7,  day    => 14,
            hour      => 13,   minute => 30, second => 0,
            time_zone => 'Europe/Paris',
        ),
        date_and_timezone   => DateTime->new(
            year      => 2000, month  => 1,  day    => 1,
            time_zone => 'Pacific/Kiritimati',
        ),
    );
    my $tersified = tersify(\%verbose);
    my $re_refaddr = qr{ \( 0x [0-9a-f]+ \) }x;
    like(
        ${ $tersified->{just_date} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 $}x,
        'A DateTime with "empty" time components is summarised as ymd'
    );
    like(
        ${ $tersified->{full} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 \s 15:09:23 $}x,
        'A DateTime with an interesting time is summarised as ymd hms'
    );
    like(
        ${ $tersified->{full_with_time_zone} },
        qr{^ DateTime \s $re_refaddr \s
             1789-07-14 \s 13:30:00 \s Europe/Paris $}x,
        'A non-floating time zone is mentioned',
    );
    like(
        ${ $tersified->{date_and_timezone} },
        qr{^ DateTime \s $re_refaddr \s
             2000-01-01 $}x,
        'A time zone is ignored if the time is uninteresting',
    );
}
