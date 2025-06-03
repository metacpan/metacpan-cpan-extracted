package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use List::Util 1.55 qw{ uniqint };
use Test2::V0;

use constant VISUAL_NAME	=> 'visual.txt';
use constant VISUAL_URL		=> 
    'http://celestrak.org/SpaceTrack/query/' . VISUAL_NAME;

note <<'EOD';

This test checks to see if the canned magnitude data may need updating.
It scrapes Heavens Above for current magnitudes. NOTE that the Heavens
Above data are cached for up to a day by default.

EOD

do './tools/heavens-above-mag'
    or plan skip_all => "Failed to execute ./tools/heavens-above-mag";

my %canned = Astro::Coord::ECI::TLE->magnitude_table( 'show' );

my $resp = heavens_above_mag::get_cached( VISUAL_NAME, VISUAL_URL );

my %visual = heavens_above_mag::parse_visual( $resp );

foreach my $oid (
    map { sprintf '%05d', $_ }
    sort { $a <=> $b }
    uniqint( keys %visual, keys %canned)
) {
    if ( ! exists $canned{$oid} ) {
	fail "OID $oid is in canned magnitudes";
    } elsif ( ! exists $visual{$oid} ) {
	fail "OID $oid is in current @{[ VISUAL_NAME ]}";
    } else {
	my @rslt = heavens_above_mag::process_get( $oid );
	my $want = format_mag( $rslt[0][2] );
	my $got = format_mag( $canned{$oid} );
	is $got, $want, "OID $oid canned magnitude";
    }
}

passing()
    or diag( <<'EOD' );


The canned magnitude table in lib/Astro/Coord/ECI/TLE.pm needs to be
regenerated.

EOD

done_testing;

sub passing {
    my $ctx = context();
    my $passing = $ctx->hub()->is_passing();
    $ctx->release();
    return $passing;
}

sub format_mag {
    my ( $mag, $dflt ) = @_;
    defined $mag
	or return $dflt;
    return sprintf '%.1f', $mag;
}

1;

# ex: set textwidth=72 :
