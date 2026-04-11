#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/09.storable.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

eval { require Storable };
if( $@ )
{
    plan( skip_all => 'Storable not available' );
}

# NOTE: Round-trip via Storable::dclone (deep clone through freeze/thaw)
subtest 'Round-trip via Storable::dclone (deep clone through freeze/thaw)' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 4,
        day       => 3,
        hour      => 14,
        minute    => 30,
        second    => 45,
        time_zone => 'UTC',
    );

    my $frozen = Storable::freeze( $dt );
    ok( defined( $frozen ), 'freeze() returns data' );

    my $thawed = Storable::thaw( $frozen );
    ok( defined( $thawed ), 'thaw() returns an object' );
    isa_ok( $thawed, 'DateTime::Lite' );

    is( $thawed->year,   $dt->year,   'storable: year round-trip' );
    is( $thawed->month,  $dt->month,  'storable: month round-trip' );
    is( $thawed->day,    $dt->day,    'storable: day round-trip' );
    is( $thawed->hour,   $dt->hour,   'storable: hour round-trip' );
    is( $thawed->minute, $dt->minute, 'storable: minute round-trip' );
    is( $thawed->second, $dt->second, 'storable: second round-trip' );
    is( $thawed->epoch,  $dt->epoch,  'storable: epoch round-trip' );
    is( $thawed->time_zone->name, $dt->time_zone->name, 'storable: time_zone round-trip' );
};

# NOTE: Non-UTC timezone round-trip
subtest 'Non-UTC timezone round-trip' => sub
{
    my $dt = DateTime::Lite->new(
        year      => 2025,
        month     => 7,
        day       => 15,
        hour      => 9,
        minute    => 0,
        second    => 0,
        time_zone => 'Asia/Tokyo',
    );

    my $thawed = Storable::thaw( Storable::freeze( $dt ) );
    is( $thawed->time_zone->name, 'Asia/Tokyo', 'storable: non-UTC tz name' );
    is( $thawed->epoch, $dt->epoch, 'storable: non-UTC epoch round-trip' );
};

# NOTE: TO_JSON
subtest 'TO_JSON' => sub
{
    require JSON;
    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 3,
        hour      => 14,
        minute    => 30,
        second    => 45,
        time_zone => 'UTC',
    );
    is( $dt->TO_JSON, '2026-04-03T14:30:45', 'TO_JSON() returns ISO 8601 string' );
    my $json = JSON->new->convert_blessed(1)->encode($dt);
    is( $json, '"2026-04-03T14:30:45"', 'JSON encoder uses TO_JSON()' );
};

done_testing;

__END__
