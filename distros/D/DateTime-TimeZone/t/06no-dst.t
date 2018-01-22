use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;
use Test::Fatal;

use File::Spec;
use Try::Tiny;

use DateTime;

{
    my $dt = DateTime->now;
    is(
        exception { $dt->set_time_zone('Pacific/Tarawa') },
        undef,
        'time zone without dst change works'
    );

    is(
        exception { $dt->set_time_zone('Asia/Dhaka') },
        undef,
        'time zone without dst change works (again)'
    );
}

# This tests a bug that happened when a time zone has a final rule
# that does not repeat (no DST changes), such as America/Caracas.
{
    my $tz = DateTime::TimeZone->new( name => 'America/Caracas' );
    my @last_spans = @{ $tz->{spans} }[ -2, -1 ];

    # This is basically a meta-test to make sure that America/Caracas
    # has not introduced DST, in which case the bug would no longer
    # apply.
    ok(
        ( !grep { $_->[5] } @last_spans ),
        'the last two spans for America/Caracas do not have DST'
    );

    for my $hm (
        [ 2,  59 ],
        [ 3,  00 ],
        [ 5,  00 ],
        [ 11, 29 ],
        [ 11, 30 ],
    ) {
        my $dt = try {
            DateTime->new(
                year      => 2007,     month  => 12, day => 9,
                hour      => $hm->[0], minute => $hm->[1],
                time_zone => 'America/Caracas',
            );
        };

        my $time = sprintf( '%02d:%02d', @{$hm} );
        is( $@, q{}, "made object in America/Caracas at $time" );
    }
}

done_testing();
