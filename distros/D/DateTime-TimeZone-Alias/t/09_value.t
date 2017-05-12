use strict;
use warnings;

use Test::More qw( no_plan );

use DateTime::TimeZone::Alias;

{
    foreach my $key ( keys %DateTime::TimeZone::Catalog::LINKS ) {
        is( DateTime::TimeZone::Alias->value( $key ), $DateTime::TimeZone::Catalog::LINKS{ $key } );
    }

    # DT::TZ::ALL is only used as a source of non-alias (LINKS) values
    foreach my $key ( @DateTime::TimeZone::Catalog::ALL ) {
        is( DateTime::TimeZone::Alias->value( $key ), undef );
    }
}
