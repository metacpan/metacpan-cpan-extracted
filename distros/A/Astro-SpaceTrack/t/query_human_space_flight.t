package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $skip;
$skip = site_check( 'spaceflight.nasa.gov' )
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

SKIP: {

    is_success_or_skip( $st, spaceflight => '-all', 'iss',
	'Human Space Flight data', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'spaceflight',
	"Content source is 'spaceflight'";

}

done_testing;

1;

__END__

# ex: set filetype=perl textwidth=72 :
