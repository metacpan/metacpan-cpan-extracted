use strict;
use warnings;

use Test::More tests => 3;

use DateTime;
use DateTime::TimeZone;
use DateTime::TimeZone::Alias;

# remove an alias
{
    DateTime::TimeZone::Alias->set( yap => 'Pacific/Yap' );

    my $dt = DateTime->now( time_zone => 'yap' );
    isa_ok( $dt, 'DateTime' );

    DateTime::TimeZone::Alias->remove( qw( yap ) );

    eval { DateTime::TimeZone->new( name => 'yap' ) };
    like( $@, qr/Invalid offset/ );
}

# attempt to remove an alias that doesn't exist
{
    eval { DateTime::TimeZone::Alias->remove( qw( yap ) ) };
    like( $@, qr/Attempt to delete a nonexistant alias/ );
}
