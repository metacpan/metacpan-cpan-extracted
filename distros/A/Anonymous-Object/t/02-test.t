use Test::More;

use Anonymous::Object;

ok(my $an = Anonymous::Object->new({
	object_name => 'Colouring::In'
}));

my $obj = $an->hash_to_object({
	a => 1,
	b => 2,
	c => 3,
	another => [qw/a b c/],
	hash => (bless {
		a => 'b',
		c => 'd'
	}, 'Foo'),
	next => sub { return 1 }
});

is(ref $obj, 'Colouring::In::0');
is ($obj->a, 1);
is ($obj->b, 2);
is ($obj->c, 3);
is_deeply ($obj->another, [qw/a b c/]);
is_deeply ($obj->hash, { a => 'b', c => 'd' }); 
is_deeply ($obj->next->(), 1);

my $obj2 = $an->hash_to_object({
	a => 1,
	b => 2,
	c => 3,
	another => [qw/a b c/],
	hash => {
		a => 'b',
		c => 'd'
	},
	next => sub { return 1 }
});

is (ref $obj2, 'Colouring::In::1');
is ($obj2->a, 1);
is ($obj2->b, 2);
is ($obj2->c, 3);
is_deeply ($obj2->another, [qw/a b c/]);
is_deeply ($obj2->hash, { a => 'b', c => 'd' }); 
is_deeply ($obj2->next->(), 1);

done_testing;
