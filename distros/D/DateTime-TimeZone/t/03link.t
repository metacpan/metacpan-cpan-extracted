use strict;
use warnings;

use lib 't/lib';
use T::RequireDateTime;

use Test::More;

use DateTime::TimeZone;

for my $link ( DateTime::TimeZone::links() ) {
    my $tz = DateTime::TimeZone->new( name => $link );
    isa_ok( $tz, 'DateTime::TimeZone' );
}

my $tz = DateTime::TimeZone->new( name => 'Libya' );
is( $tz->name, 'Africa/Tripoli', 'check ->name' );

$tz = DateTime::TimeZone->new( name => 'US/Central' );
is( $tz->name, 'America/Chicago', 'check ->name' );

done_testing();
