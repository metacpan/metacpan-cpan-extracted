use Test::More;

use Anonymous::Object;

ok(my $an = Anonymous::Object->new());

my $obj = $an->hash_to_object({
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

is(ref $obj, 'Anonymous::Object::0');
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

is (ref $obj2, 'Anonymous::Object::1');
is ($obj2->a, 1);
is ($obj2->b, 2);
is ($obj2->c, 3);
is_deeply ($obj2->another, [qw/a b c/]);
is_deeply ($obj2->hash, { a => 'b', c => 'd' }); 
is_deeply ($obj2->next->(), 1);

my $obj3 = $an->hash_to_object({
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

is (ref $obj3, 'Anonymous::Object::2');
is ($obj3->a, 1);
is ($obj3->b, 2);
is ($obj3->c, 3);
is_deeply ($obj3->another, [qw/a b c/]);
is_deeply ($obj3->hash, { a => 'b', c => 'd' }); 
is_deeply ($obj3->next->(), 1);


done_testing;
