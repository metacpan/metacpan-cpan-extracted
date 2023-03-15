package main;

use 5.008;

use strict;
use warnings;

use Astro::SpaceTrack 0.084;
use Astro::Coord::ECI::TLE;
use HTTP::Date;
use LWP::UserAgent;
use Test::More 0.88;	# Because of done_testing();
use Time::Local;

note <<'EOD';

This test checks to see if the canned magnitude data may need updating.
It checks the file dates of relevant files, and scrapes Heavens Above
for current magnitudes.

EOD

$ENV{TLE_DO_MAGNITUDE_STATUS}
    or plan skip_all => 'TLE_DO_MAGNITUDE_STATUS not set';

is_last_modified(
    'http://celestrak.org/SpaceTrack/query/visual.txt',
    Astro::Coord::ECI::TLE->_CELESTRAK_VISUAL(),
    'Celestrak visual.txt',
);

do './tools/heavens-above-mag'
    or die "Failed to execute ./tools/heavens-above-mag";

my %canned = Astro::Coord::ECI::TLE->magnitude_table( 'show' );
foreach my $oid ( sort keys %canned ) {
    my $got = $canned{$oid};
    my @rslt = heavens_above_mag::process_get( $oid );
    my ( undef, $name, $want ) = @{ $rslt[0] };
    if ( defined( $got ) && defined( $want ) ) {
	cmp_ok $got, '==', $want, "Canned magnitude of $oid ($name)";
    } else {
	is $got, $want, "Canned magnitude of $oid ($name)";
    }
}

=begin comment

is_last_modified( mccants => 'vsnames',
    Astro::Coord::ECI::TLE->_MCCANTS_VSNAMES(),
    'McCants vsnames.mag',
);

is_last_modified( mccants => 'mcnames',
    'Thu, 25 May 2017 00:09:56 GMT',
    'McCants mcnames.mag',
);

is_last_modified( mccants => 'quicksat',
    Astro::Coord::ECI::TLE->_MCCANTS_QUICKSAT(),
    'McCants qs.mag',
);

=end comment

=cut

done_testing;

{
    my $st;
    my $ua;

    sub is_last_modified {
	my @arg = @_;
	my $resp;

	my ( $want, $name ) = splice @arg, -2, 2;

	unless ( defined $want ) {
	    my $builder = Test::More->builder();
	    $builder->skip( "$name unused" );
	    return;
	}

	if ( $arg[0] =~ m/ \A \w+ : /smx ) {
	    $ua ||= LWP::UserAgent->new();
	    $resp = $ua->head( shift @arg );
	} else {
	    $st ||= Astro::SpaceTrack->new();
	    my ( $src, $catalog ) = splice @arg, 0, 2;
	    $resp = $st->$src( $catalog );
	}

	unless ( $resp->is_success() ) {
	    @_ = "$name: " . $resp->status_line();
	    goto &fail;
	}

	if ( my ( $got ) = $resp->header( 'Last-Modified' ) ) {
	    @_ = ( $got, $want, "$name Last-Modified: $want" );
	    goto &is;
	}

	@_ = "$name: No Last-Modified header found";
	goto &fail;
    }
}

1;

# ex: set textwidth=72 :
