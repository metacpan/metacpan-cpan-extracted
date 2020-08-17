package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $st = Astro::SpaceTrack->new();

my $skip;
$skip = site_check( 'celestrak.com' )
    and plan skip_all => $skip;

$st->set(
    direct	=> 1,
);

SKIP: {

    is_success_or_skip( $st, celestrak => 'stations',
    'Direct-fetch celestrak stations', 4 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'celestrak', "Content source is 'celestrak'";

    my $resp = most_recent_http_response(  );

    is $st->content_type( $resp ), 'orbit', "Result type is 'orbit'";

    is $st->content_source( $resp ), 'celestrak',
	"Result source is 'celestrak'";
}

SKIP: {
    is_success_or_skip( $st, celestrak => 'iridium',
	'Direct-fetch Celestrak iridium', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'celestrak', "Content source is 'celestrak'";
}

SKIP: {

    is_error_or_skip( $st, celestrak => 'fubar',
	404, 'Direct-fetch non-existent Celestrak catalog' );

}

SKIP: {
    is_success_or_skip( $st, celestrak_supplemental => 'orbcomm',
	'Fetch Celestrak supplemental Orbcomm data', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'celestrak', "Content source is 'celestrak'";
}

SKIP: {
    is_success_or_skip( $st, celestrak_supplemental => '-rms', 'intelsat',
	'Fetch Celestrak supplemental Intelsat RMS data', 2 );

    is $st->content_type(), 'rms', "Content type is 'rms'";

    is $st->content_source(), 'celestrak', "Content source is 'celestrak'";
}

done_testing;

1;

__END__

# ex: set filetype=perl textwidth=72 :
