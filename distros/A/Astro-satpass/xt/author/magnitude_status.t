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
All it really does is to check file dates on the relevant files.

EOD

is_last_modified(
    'http://celestrak.com/SpaceTrack/query/visual.txt',
    Astro::Coord::ECI::TLE->_CELESTRAK_VISUAL(),
    'Celestrak visual.txt',
);

is_last_modified( mccants => 'vsnames',
    Astro::Coord::ECI::TLE->_MCCANTS_VSNAMES(),
    'McCants vsnames.mag',
);

=begin comment

is_last_modified( mccants => 'mcnames',
    'Thu, 25 May 2017 00:09:56 GMT',
    'McCants mcnames.mag',
);

=end comment

=cut

is_last_modified( mccants => 'quicksat',
    Astro::Coord::ECI::TLE->_MCCANTS_QUICKSAT(),
    'McCants qs.mag',
);

done_testing;

{
    my $st;
    my $ua;

    sub is_last_modified {
	my @arg = @_;
	my $resp;

	if ( $arg[0] =~ m/ \A \w+ : /smx ) {
	    $ua ||= LWP::UserAgent->new();
	    $resp = $ua->head( shift @arg );
	} else {
	    $st ||= Astro::SpaceTrack->new();
	    my ( $src, $catalog ) = splice @arg, 0, 2;
	    $resp = $st->$src( $catalog );
	}

	my ( $want, $name ) = @arg;

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
