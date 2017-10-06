use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/StrToArray/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [StrToArray->by(' '), { coerce => 1 }],
		[qw/another/] => [StrToArray->by(', '), { coerce => 1 }],
		[qw/test testing/] => [StrToArray->by('--'), { coerce => 1 }],
		[qw/again/] => [StrToArray->by('--'), { coerce => 1 }]
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	thing => 'red bull', 
	another => 'new, day', 
	test => 'one--two--three', 
	testing => 'one--two--three', 
	again => 'one--two--three' 
);
is_deeply($thing->thing, [qw/red bull/]);

is_deeply($thing->another, [qw/new day/]);

is_deeply($thing->test, [qw/one two three/]);

is_deeply($thing->testing, [qw/one two three/]);

is_deeply($thing->again, [qw/one two three/]);

done_testing();
