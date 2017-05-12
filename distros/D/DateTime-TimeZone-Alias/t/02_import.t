use strict;
use warnings;

use Test::More tests => 4;

use DateTime;
use DateTime::TimeZone;

# passing a hash to import
use DateTime::TimeZone::Alias HIST => 'Pacific/Honolulu', EST => 'Australia/Melbourne';

{
    my $dt = DateTime->now( time_zone => 'HIST' );
    isa_ok( $dt, 'DateTime' );

    my $dttz = $dt->time_zone();
    isa_ok( $dttz, 'DateTime::TimeZone::Pacific::Honolulu' );
}

{
    my $dttz = DateTime::TimeZone->new( name => 'EST' );
    isa_ok( $dttz, 'DateTime::TimeZone::Australia::Melbourne' );
}

# multiple imports
use DateTime::TimeZone::Alias York => 'America/New_York';

{
    my $dttz = DateTime::TimeZone->new( name => 'York' );
    isa_ok( $dttz, 'DateTime::TimeZone::America::New_York' );
}
