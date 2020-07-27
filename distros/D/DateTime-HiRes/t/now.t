use strict;
use warnings;

use Test::More;

use Time::HiRes;
use DateTime::HiRes;

{
    my $dt = DateTime::HiRes->now;
    isa_ok( $dt, 'DateTime' );
}

{
    my $dt1 = DateTime::HiRes->now;
    my $dt2 = DateTime->now;

    my $dur = $dt1 - $dt2;
    is( $dur->seconds, 0, 'dt1 - dt2 < 1 second' );
}

{
    my $dt1 = DateTime::HiRes->now;
    my $dt2 = DateTime::HiRes->now;

    my $dur = $dt1 - $dt2;
    is( $dur->seconds, 0, 'dt1 - dt2 < 1 second' );
    ok( $dur->nanoseconds < 500_000_000, 'dt1 - dt2 < .5 second' );
}

{
    my $dt = DateTime::HiRes->now(
        time_zone => 'Africa/Cairo',
        locale    => 'ar_EG',
    );

    is(
        $dt->time_zone_long_name, 'Africa/Cairo',
        'accepted time_zone parameter'
    );
    like( $dt->locale->id, qr/ar[_-]EG/, 'accepted locale parameter' );
}

done_testing();
