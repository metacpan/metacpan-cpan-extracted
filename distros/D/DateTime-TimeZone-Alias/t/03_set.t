use strict;
use warnings;

use Test::More tests => 8;

use DateTime;
use DateTime::TimeZone;
use DateTime::TimeZone::Alias;

# passing a hash to set
DateTime::TimeZone::Alias->set( Lagos => 'Africa/Lagos', Qatar => 'Asia/Qatar' );

{
    my $dt = DateTime->now( time_zone => 'Lagos' );
    isa_ok( $dt, 'DateTime' );

    my $dttz = $dt->time_zone();
    isa_ok( $dttz, 'DateTime::TimeZone::Africa::Lagos' );
}

{
    my $dttz = DateTime::TimeZone->new( name => 'Qatar' );
    isa_ok( $dttz, 'DateTime::TimeZone::Asia::Qatar' );
}

# trying to set an alias to in invalid timezone
{
    eval { DateTime::TimeZone::Alias->set( foo => 'bar' ) };
    like( $@, qr/Aliases must point to a valid timezone/ );
}

{
    eval { DateTime::TimeZone::Alias->set() };
    like( $@, qr/Can't be called without any parameters/ );
}

DateTime::TimeZone::Alias->set( zulu => 'UTC', home => 'local', boat => 'floating' );
{
    my $dttz = DateTime::TimeZone->new( name => 'zulu' );
    isa_ok( $dttz, 'DateTime::TimeZone::UTC' );
}

{
    my $dttz = DateTime::TimeZone->new( name => 'home' );
    my $ltz = DateTime::TimeZone::Local->TimeZone();
    is( $dttz->name, $ltz->name );
}

{
    my $dttz = DateTime::TimeZone->new( name => 'boat' );
    isa_ok( $dttz, 'DateTime::TimeZone::Floating' );
}
