use strict;
use warnings;

use Test::More qw( no_plan );

use DateTime::TimeZone::Alias;

{
    # timezones
    foreach my $key ( @DateTime::TimeZone::Catalog::ALL ) {
        is( DateTime::TimeZone::Alias->is_defined( $key ), 1 );
    }

    foreach my $key ( @DateTime::TimeZone::Catalog::ALL ) {
        is( DateTime::TimeZone::Alias->is_timezone( $key ), 1 );
    }

    foreach my $key ( @DateTime::TimeZone::Catalog::ALL ) {
        is( DateTime::TimeZone::Alias->is_alias( $key ), undef );
    }

    # aliases
    foreach my $key ( keys %DateTime::TimeZone::Catalog::LINKS ) {
        is( DateTime::TimeZone::Alias->is_defined( $key ), 1 );
    }

    foreach my $key ( keys %DateTime::TimeZone::Catalog::LINKS ) {
        is( DateTime::TimeZone::Alias->is_timezone( $key ), undef );
    }

    foreach my $key ( keys %DateTime::TimeZone::Catalog::LINKS ) {
        is( DateTime::TimeZone::Alias->is_alias( $key ), 1 );
    }
}
