use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Data::DPath::Flatten', qw/flatten/ ); }

sub compare {
	my ($test, $data, $expected) = @_;

	my $got = flatten( $data );
	is_deeply( $got, $expected, $test );
}

compare( 'Hash reference',
	{
		A => 1,
		B => 2,
		C => {D => 3, E => 4},
		F => [5, 6],
		G => [{H => 7}, {I => 8}],
		J => {K => [9, {L => 10}]},
	}, {
		'/A'          => 1,
		'/B'          => 2,
		'/C/D'        => 3,
		'/C/E'        => 4,
		'/F/*[0]'     => 5,
		'/F/*[1]'     => 6,
		'/G/*[0]/H'   => 7,
		'/G/*[1]/I'   => 8,
		'/J/K/*[0]'   => 9,
		'/J/K/*[1]/L' => 10,
	}
);
compare( 'Array reference',
	[
		1,
		{A => 2},
		{B => {C => 3, D => 4}},
		[5, 6],
		[{E => 7}, {F => 8}],
		{G => [9, {H => 10}]},
	], {
		'/*[0]'          => 1,
		'/*[1]/A'        => 2,
		'/*[2]/B/C'      => 3,
		'/*[2]/B/D'      => 4,
		'/*[3]/*[0]'     => 5,
		'/*[3]/*[1]'     => 6,
		'/*[4]/*[0]/E'   => 7,
		'/*[4]/*[1]/F'   => 8,
		'/*[5]/G/*[0]'   => 9,
		'/*[5]/G/*[1]/H' => 10,
	}
);

subtest 'Infinite loop' => sub {
	my (@a, @b);
	@a = (1, \@b);
	@b = (2, \@a);
	compare( 'Array', \@a, {
		'/*[0]'      => 1,
		'/*[1]/*[0]' => 2,
	} );

	my (%a, %b);
	%a = (A => 1, B => \%b);
	%b = (C => 2, D => \%a);
	compare( 'Hash', \%a, {
		'/A'   => 1,
		'/B/C' => 2,
	} );
};

done_testing();
