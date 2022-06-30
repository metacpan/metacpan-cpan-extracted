package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $skip;
$skip = site_check( 'celestrak.org' )
    and plan skip_all => $skip;
$skip = site_check( 'rod.sladen' )
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

$st->set(
    iridium_status_format	=> 'sladen',
);

SKIP: {

    is_success_or_skip( $st,
	'iridium_status', 'Get Iridium status (Sladen)', 2 );

    is $st->content_type(), 'iridium-status',
	"Content type is 'iridium-status'";

    is $st->content_source(), 'sladen', "Content source is 'sladen'";
}


done_testing;

1;

__END__

# ex: set filetype=perl textwidth=72 :
