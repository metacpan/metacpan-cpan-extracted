use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/StrSR/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [StrSR->by(['_', ':']), { coerce => 1 }],
		[qw/okay/] => [StrSR->by(['_', ':']), { coerce => 1 }],
		[qw/special/] => [StrSR->by(['*', '/']), { coerce => 1 }],
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	thing => 'morning_world', 
	okay => 'another_longer_example_is_okay',
	special => 'okay*this*works'
);

is($thing->thing, 'morning:world');
is($thing->okay, 'another:longer:example:is:okay');
is($thing->special, 'okay/this/works');

done_testing();
