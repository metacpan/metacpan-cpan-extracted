#!perl -w
use strict;
use Data::ICal::TimeZone;
use Test::More tests => 2 * @{ [ Data::ICal::TimeZone->zones ] };

for my $zone ( Data::ICal::TimeZone->zones ) {
    my $ics = Data::ICal::TimeZone->new( timezone => $zone );
    ok( $ics, "loaded $zone" )
        or do { fail( $ics->error_message ); next };
    is( $ics->timezone, $zone );
}
