use Test::Most tests => 7;

use strict;
use warnings;

use PDL;
use PDL::StringfiableExtension;

is( sequence(10)->element_stringify_max_width, 1 );
is( sequence(11)->element_stringify_max_width, 2 );
is( sequence(12)->element_stringify_max_width, 2 );
is( sequence(100)->element_stringify_max_width, 2 );
is( sequence(101)->element_stringify_max_width, 3 );

my @each = (
	{ val => 1.23         , },
	{ val => 1.23456      , },
	{ val => 1.23456789   , },
	{ val => 1.234567890  , },
	{ val => 1.2345678901 , },
	{ val => 1.23456789012, },
);
for (@each) {
	# get string lengths
	$_->{zerodim} = length( pdl(  $_->{val}  )->string );
	# subtract 2 because of '[' and ']'
	$_->{ndim}    = length( pdl([ $_->{val} ])->string ) - 2;
}

subtest 'lengths' => sub {
	plan tests => 3 * @each;
	for my $data (@each) {
		note $data->{val};
		is( pdl($data->{val})->element_stringify_max_width, $data->{zerodim} );
		is( pdl([ $data->{val} ])->element_stringify_max_width, $data->{ndim} );
		is( pdl([ [ $data->{val} ] ])->element_stringify_max_width, $data->{ndim} );
	}
};

note "\$PDL::toolongtoprint = $PDL::toolongtoprint";
is( sequence($PDL::toolongtoprint + 1)->element_stringify_max_width, length "$PDL::toolongtoprint" );

done_testing;
