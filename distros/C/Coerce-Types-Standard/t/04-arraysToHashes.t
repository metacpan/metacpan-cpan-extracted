use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/ArrayToHash/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [ArrayToHash, { coerce => 1 }],
		[qw/another/] => [ArrayToHash, { coerce => 1 }],
		[qw/test/] => [ArrayToHash, { coerce => 1 }],
		'odd' => [ArrayToHash->by('odd'), { coe }],
		'even' => [ArrayToHash->by('even'), { coe }],
		'reverse' => [ArrayToHash->by('reverse'), { coe }],
		'flat' => [ArrayToHash->by('flat'), { coe }],
		'merge' => [ArrayToHash->by('merge'), { coe }],
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	thing => [qw/red bull/], 
	another => [qw/new day/], 
	test => [qw/one two three four/],
	odd => [qw/one two three four/],
	even => [qw/one two three four/],
	reverse => [qw/one two three four/],
	flat => [{ one => 'two' }, [qw/three four/]],
	merge => [{ one => 'two' }, {three => 'four'}]
);

is_deeply($thing->thing, {red => 'bull'});

is_deeply($thing->another, {new => 'day'});

is_deeply($thing->test, {one => 'two', three => 'four'});

# by indexxxx
is_deeply($thing->odd, {two => 'four'});

is_deeply($thing->even, {one => 'three'});

is_deeply($thing->reverse, {two => 'one', four => 'three'});

is_deeply($thing->flat, {one => 'two', three => 'four'});

is_deeply($thing->merge, {one => 'two', three => 'four'});


done_testing();
