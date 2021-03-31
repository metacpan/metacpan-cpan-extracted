use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/Count/;
	use MooX::LazierAttributes;

	attributes (
		[qw/count_array/] => [Count, { coe }],
		[qw/count_hash/] => [Count, { coe }],
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	count_array => [ qw/a b c/ ],
	count_hash => {
		a => 1,
		b => 2
	}
);

is($thing->count_array, 3);
is($thing->count_hash, 2);

done_testing();
