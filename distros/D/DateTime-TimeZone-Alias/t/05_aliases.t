use strict;
use warnings;

use Test::More tests => 7;

use DateTime;

# aliasing an alias
use DateTime::TimeZone::Alias Hawaii => 'US/Hawaii';

{
    my $dt = DateTime->now( time_zone => 'Hawaii' );
    isa_ok( $dt, 'DateTime' );

    my $dttz = $dt->time_zone();
    isa_ok( $dttz, 'DateTime::TimeZone::Pacific::Honolulu' );
}

# redefing a timezone with an alais
use DateTime::TimeZone::Alias 'Pacific/Apia' => 'Pacific/Auckland';

{
    my $dt = DateTime->now( time_zone => 'Pacific/Apia' );
    isa_ok( $dt, 'DateTime' );

    my $dttz = $dt->time_zone();
    isa_ok( $dttz, 'DateTime::TimeZone::Pacific::Auckland' );
}

# attempt to make circular aliases
use DateTime::TimeZone::Alias 'Pacific/Auckland' => 'Pacific/Apia';

{
    my $dt = DateTime->now( time_zone => 'Pacific/Auckland' );
    isa_ok( $dt, 'DateTime' );

    my $dttz = $dt->time_zone();
    isa_ok( $dttz, 'DateTime::TimeZone::Pacific::Auckland' );
}

{
    eval { DateTime::TimeZone::Alias->add() };
    like( $@, qr/Can't be called without any parameters/ );
}

