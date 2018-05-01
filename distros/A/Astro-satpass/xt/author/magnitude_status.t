package main;

use 5.008;

use strict;
use warnings;

use Astro::SpaceTrack 0.084;
use HTTP::Date;
use LWP::UserAgent;
use Test::More 0.88;	# Because of done_testing();
use Time::Local;

note <<'EOD';

This test checks to see if the canned magnitude data may need updating.
All it really does is to check file dates on the relevant files.

EOD

is last_modified(
    'http://celestrak.com/SpaceTrack/query/visual.txt' ),
    'Thu, 12 Apr 2018 22:44:11 GMT',
    'Celestrak visual.txt Last-Modified';

is last_modified( mccants => 'vsnames' ),
    'Thu, 25 May 2017 00:30:11 GMT',
    'McCants vsnames.mag Last-Modified';

=begin comment

is last_modified( mccants => 'mcnames' ),
    'Thu, 25 May 2017 00:09:56 GMT',
    'McCants mcnames.mag Last-Modified';

=end comment

=cut

is last_modified( mccants => 'quicksat' ),
    'Thu, 25 May 2017 00:00:55 GMT',
    'McCants qs.mag Last-Modified';

done_testing;

{
    my $st;
    my $ua;

    sub last_modified {
	my ( $src, $catalog ) = @_;
	my $resp;
	if ( defined $catalog ) {
	    $st ||= Astro::SpaceTrack->new();
	    $resp = $st->$src( $catalog );
	} else {
	    $ua ||= LWP::UserAgent->new();
	    $resp = $ua->head( $src );
	}
	$resp->is_success()
	    or return $resp->status_line();
	foreach my $val ( $resp->header( 'Last-Modified' ) ) {
	    return $val;
	}
	return 'No Last-Modified header found';
    }
}

1;

# ex: set textwidth=72 :
