package main;

use strict;
use warnings;

use Test::More 0.88;

sub instantiate ($);

require_ok 'Astro::Coord::ECI::TLE::Iridium'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Iridium';

done_testing;

sub instantiate ($) {
    my ( $class ) = @_;
    my $pass = eval {
	$class->new();
    };
    @_ = ( $pass, "Instantiate $class" );
    goto &ok;
}

1;

# ex: set textwidth=72 :
