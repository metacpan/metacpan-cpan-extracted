use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/Str ArrayRef HashRef/;
	use MooX::LazierAttributes;

	attributes (
		[qw/thing/] => [Str],
		[qw/another/] => [ArrayRef],
		[qw/test/] => [HashRef]
	);
}

use Have::Fun;
my $thing = Have::Fun->new( thing => 'red bull', another => ['new', 'day'], test => {one => 'two', three => 'four'});
is_deeply($thing->thing, 'red bull');

is_deeply($thing->another, [qw/new day/]);

is_deeply($thing->test, {one => 'two', three => 'four'});

done_testing();
