package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Astro::Coord::ECI::VSOP87D'
    or BAIL_OUT $@;

foreach my $name ( qw{
	_Inferior _Superior
	Sun Mercury Venus
	Mars Jupiter Saturn Uranus Neptune
    } ) {
    my $class = "Astro::Coord::ECI::VSOP87D::$name";

    require_ok $class
	or BAIL_OUT $@;

    $name =~ m/ \A _ /smx
	and next;

    my $body = eval { $class->new() };
    isa_ok $body, $class
	or BAIL_OUT $@;

    is $body->get( 'name' ), $name, qq<Body name is '$name'>;

    is $body->get( 'model_cutoff' ), 'Meeus',
	qq<Default $name model cutoff is 'Meeus'>;

}

done_testing;

1;
