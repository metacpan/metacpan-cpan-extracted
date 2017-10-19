package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::TLE::Iridium;
use Test::More 0.88;	# Because of done_testing();

note <<'EOD';

Astro::Coord::ECI::TLE::Iridium duplicates the manifest constants for
portable Iridium status from Astro::SpaceTrack because I did not want
this package to depend on the latter. The purpose of this test is to
ensure that I have maintained consistency between the codes.
EOD

{
    local $@ = undef;
    eval {
	require Astro::SpaceTrack;
	1;
    } or plan( skip_all => "Unable to load Astro::SpaceTrack: $@" );
}

foreach my $key ( sort keys %Astro::SpaceTrack:: ) {
    $key =~ m/ \A BODY_STATUS_IS_ [_[:upper:]]+ \z /smx
	or next;
    local $@ = undef;
    eval {
	cmp_ok( Astro::Coord::ECI::TLE::Iridium->$key(), '==',
	    Astro::SpaceTrack->$key(),
	    "$key is consistent",
	);
	1;
    } or fail( "Astro::Coord::ECI::TLE::Iridium does not implement $key" );
}

done_testing;

1;

# ex: set textwidth=72 :
