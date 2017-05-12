#!perl


use strict;
use warnings;
use Test::More tests => 28;

use_ok( 'Acme::Tango' );

my @flavours = qw( orange lemon apple );

for (
	# Input,      as: orange,    lemon,     apple      description
	[ 'FF0000',       'FFAA00',  'FFFF00',  '3FFF00',  'Red' ],
	[ 'FF0000',       'FFAA00',  'FFFF00',  '3FFF00',  'Yellow' ],
	[ '00FF00',       'FFAA00',  'FFFF00',  '3FFF00',  'Green' ],
	[ '00B2EB',       'EB9C00',  'EBEB00',  '3AEB00',  'Dark Cyan' ],
	[ '000000',       '000000',  '000000',  '000000',  'Black' ],
	[ 'FFFFFF',       'FFFFFF',  'FFFFFF',  'FFFFFF',  'White' ],
	[ 'fff',          'FFFFFF',  'FFFFFF',  'FFFFFF',  'Red, three char form' ],
	[ '#0f0',         '#FFAA00', '#FFFF00', '#3FFF00', 'Green, three char form with hash' ],
	[ '#FFFF00',      '#FFAA00', '#FFFF00', '#3FFF00', 'Yellow, with hash' ],

) {
	my @reference   = @$_;
	my $input       = shift @reference;
	my $description = pop   @reference;

	for my $flavour ( @flavours ) {
		my $expected = shift @reference;
		is(
			Acme::Tango::drink( $input, $flavour ),
			$expected,
			"$flavour: $description [$input]->[$expected]" );
	}
}
