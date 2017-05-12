use Test::More tests => 11;
use Data::Typed::Expression;

my %tests = (
	abc => { op => 'V', arg => 'abc' },
	1 => { op => 'I', arg => '1' },
	12.3 => { op => 'D', arg => '12.3' },
);

$tests{'a[b]'} = {
	op => '[]',
	arg => [
		{ op => 'V', arg => 'a' },
		{ op => 'V', arg => 'b' }
	]
};

$tests{'a[b][c]'} = {
	op => '[]',
	arg => [
		{ op => 'V', arg => 'a' },
		{ op => 'V', arg => 'b' },
		{ op => 'V', arg => 'c' }
	]
};

$tests{'a[b][c.d[123]]'} = {
	op => '[]',
	arg => [
		{ op => 'V', arg => 'a' },
		{ op => 'V', arg => 'b' },
		{ op => '[]', arg => [
			{ op => '.', arg => [
				{ op => 'V', arg => 'c' },
				{ op => 'V', arg => 'd' }
			]},
			{ op => 'I', arg => '123' }
		]}
	]
};

$tests{'a[b].c'} = {
	op => '.',
	arg => [ $tests{'a[b]'}, { op => 'V', arg => 'c' } ]
};
$tests{'((a[(b)].c))'} = $tests{'a[b].c'};

# operators priority
$tests{'a.b+c.d[e+f+g]'} = {
	op => '+',
	arg => [
		{
			op => '.',
			arg => [
				{ op => 'V', arg => 'a' },
				{ op => 'V', arg => 'b' },
			]
		},


		{ op => '[]', arg => [
			{ op => '.', arg => [
					{ op => 'V', arg => 'c' },
					{ op => 'V', arg => 'd' }					
				]
			}, 
			{ op => '+', arg => [
				{ op => 'V', arg => 'e' },
				{ op => '+', arg => [
					{ op => 'V', arg => 'f' },
					{ op => 'V', arg => 'g' }
				]}
			]}
		]}
	]
};

# multiple dots
$tests{'a.b.c'} = {
	op => '.',
	arg => [
		{ op => '.', arg => [
			{ op => 'V', arg => 'a' },
			{ op => 'V', arg => 'b' }
		]},
		{ op => 'V', arg => 'c' }
	]
};

for (keys %tests) {
	my $resu = Data::Typed::Expression::_make_ast($_);
	use Data::Dumper;
#	print Dumper($resu);
	is_deeply($resu, $tests{$_}, "e := $_");
}

pass;

# jedit :mode=perl:

