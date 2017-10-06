use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/StrToHash/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [StrToHash->by(' '), { coerce => 1 }],
		[qw/another/] => [StrToHash->by(', '), { coerce => 1 }],
		[qw/test/] => [StrToHash->by('--'), { coerce => 1 }]
	);
}

use Have::Fun;
my $thing = Have::Fun->new( thing => 'red bull', another => 'new, day', test => 'one--two--three--four');
is_deeply($thing->thing, {red => 'bull'});

is_deeply($thing->another, {new => 'day'});

is_deeply($thing->test, {one => 'two', three => 'four'});

done_testing();
