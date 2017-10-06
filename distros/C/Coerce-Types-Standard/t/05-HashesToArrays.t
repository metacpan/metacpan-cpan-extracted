use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/HashToArray/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [HashToArray, { coerce => 1 }],
		[qw/another/] => [HashToArray, { coerce => 1 }],
		[qw/test/] => [HashToArray, { coerce => 1 }],
		keys => [HashToArray->by('keys'), { coerce => 1 }],
		values => [HashToArray->by('values'), { coerce => 1 }],
		flat => [HashToArray->by('flat'), { coerce => 1 }]
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	thing => {red => 'bull'}, 
	another => {new => 'day'}, 
	test => {one => 'two', three => 'four'},
	keys => {one => 'two', three => 'four'},
	values => {one => 'two', three => 'four'},
	flat => {one => ['two'], three => ['four']}
);

is_deeply($thing->thing, [qw/red bull/]);

is_deeply($thing->another, [qw/new day/]);

is_deeply($thing->test, [qw/one two three four/]);

is_deeply($thing->keys, [qw/one three/]);

is_deeply($thing->values, [qw/four two/]);

is_deeply($thing->flat, [qw/one two three four/]);

done_testing();
