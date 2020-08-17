package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $skip;
$skip = site_check( 'www.amsat.org' )
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

SKIP: {

    is_success_or_skip( $st,
	'amsat', 'Radio Amateur Satellite Corporation', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'amsat', "Content source is 'amsat'";
}

done_testing;

1;

__END__

# ex: set filetype=perl textwidth=72 :
