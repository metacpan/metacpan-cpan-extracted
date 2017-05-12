use strict;
use warnings;

use Test::More tests => 3;

use DateTime;
use DateTime::TimeZone;
use DateTime::TimeZone::Alias;

{
    DateTime::TimeZone::Alias->add( Casa => 'Africa/Casablanca' );

    # verify that this is a valid aliasing
    my $dttz = DateTime::TimeZone->new( name => 'Casa' );
    isa_ok( $dttz, 'DateTime::TimeZone::Africa::Casablanca' );

    # attempt to redefine with add
    eval{ DateTime::TimeZone::Alias->add( Casa => 'Africa/Casablanca' ) };
    like( $@, qr/Attempt to redefine an alias or timezone/ );

    # attempt to define an alias with the some name as a timezone
    eval{ DateTime::TimeZone::Alias->add( 'Indian/Antananarivo' => 'Indian/Chagos' ) };
    like( $@, qr/Attempt to redefine an alias or timezone/ );
}
