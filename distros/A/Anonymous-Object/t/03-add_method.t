use Test::More;

use Anonymous::Object;

ok(my $an = Anonymous::Object->new({}));

ok($an->add_method({
	name => 'test',
	clearer => 1,
	predicate => 1,
	get => 1,
	set => 1,
	ref => 1,
	reftype => 1,
	default => 'abc',	
}));

my $obj = $an->build;

is($obj->get_test, 'abc');
is($obj->has_test, 1);
ok($obj->clear_test);
is($obj->has_test, '');
is_deeply($obj->set_test([qw/a b c/]), [qw/a b c/]);
is_deeply($obj->get_test, [qw/a b c/]);
is($obj->has_test, 1);
is($obj->ref_test, 'ARRAY');
is($obj->reftype_test, 'ARRAY');

ok($an->add_method({
	name => 'testing',
	type => 'Str',
	set => 1,
	default => 'abc',
}));

$obj = $an->build;

is($obj->get_test, 'abc');
is($obj->has_test, 1);
ok($obj->clear_test);
is($obj->has_test, '');
is_deeply($obj->set_test([qw/a b c/]), [qw/a b c/]);
is_deeply($obj->get_test, [qw/a b c/]);
is($obj->has_test, 1);
is($obj->ref_test, 'ARRAY');
is($obj->reftype_test, 'ARRAY');

is($obj->testing, 'abc');
eval {
	$obj->set_testing([qw/a b c/]);
};

like($@, qr/did not pass type constraint/);


done_testing;
