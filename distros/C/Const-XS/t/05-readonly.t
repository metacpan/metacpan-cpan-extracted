use Const::XS qw/all/;
use Test::More;

my $foo = 'a scalar value';
make_readonly($foo);

my $bar = [qw/a list value/, { hash => 1, deep => { one => 'nope' } }, [ 'nested', { hash => 2 } ]];
make_readonly($bar);

my $buz = {a => 'hash', of => 'something', array => [ 'nested', { hash => 1 } ], hash => { hash => 2, deep => { one => 'nope' } } };
make_readonly($buz);

my $sub = sub { return 1 };
make_readonly($sub);

my $factory = {
	one => sub { 1 },
	two => sub { 2 },
};
make_readonly($factory);

my $factory2 = {
	one => sub { 1 },
	two => sub { 2 },
};
make_readonly($factory2);

my $var = make_readonly_ref({ a => 1 });

is($foo, 'a scalar value');

eval { $foo = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

is($foo, 'a scalar value');

is($bar->[0], 'a');
is($bar->[1], 'list');
is($bar->[2], 'value');
is_deeply($bar->[3], { hash => 1, deep => { one => 'nope' } });
is_deeply($bar->[4], [ 'nested', { hash => 2 } ]);


eval { $bar->[0] = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $bar = [qw/1 2 3/] };

like($@, qr/Modification of a read-only value attempted/); 

eval { $bar->[3]->{hash} = 2 };

like($@, qr/Modification of a read-only value attempted/); 

eval { $bar->[3]->{deep} = { abc => 123 } };

like($@, qr/Modification of a read-only value attempted/); 

eval { $bar->[3]->{deep}->{one} = 2 };

like($@, qr/Modification of a read-only value attempted/); 

eval { $bar->[4][0] = 'abc' };
like($@, qr/Modification of a read-only value attempted/); 

eval { $bar->[4][1]{hash} = 'abc' };

like($@, qr/Modification of a read-only value attempted/); 

is_deeply($buz, {a => 'hash', of => 'something', array => [ 'nested', { hash => 1 } ], hash => { hash => 2, deep => { one => 'nope' } }});

eval { $buz->{a} = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{array}[0] = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{array}[1]{hash} = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{array}[1] = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{hash}{hash} = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{hash}{deep}{one} = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

eval { $buz->{something_new} = 123 };

like($@, qr/Attempt to access disallowed key \'something_new\' in a restricted hash/);

eval { $buz->{hash}{something_new} = 123 };

like($@, qr/Attempt to access disallowed key \'something_new\' in a restricted hash/);

eval { $buz->{hash}{deep}{something_new} = 123 };

like($@, qr/Attempt to access disallowed key \'something_new\' in a restricted hash/);

is(exists $buz->{something_new} ? 1 : 0, 0);

is($sub->(), 1);

eval { $sub = sub { return 2 } };

like($@, qr/Modification of a read-only value attempted/); 

is($sub->(), 1);

is($factory->{one}->(), 1);

eval { $factory->{three}->() };

like($@, qr/Attempt to access disallowed key \'three\' in a restricted hash/);

eval { $factory->{one} = sub { 3 } };

like($@, qr/Modification of a read-only value attempted/); 

is($factory->{one}->(), 1);

is($factory2->{one}->(), 1);

eval { $factory2->{three}->() };

like($@, qr/Attempt to access disallowed key \'three\' in a restricted hash/);

eval { $factory2->{one} = sub { 3 } };

like($@, qr/Modification of a read-only value attempted/); 

is($factory2->{one}->(), 1);

is($var->{a}, 1);

eval { $var->{b} = 2 };

like($@, qr/Attempt to access disallowed key 'b' in a restricted hash/);

ok($var = 2);

is($var, 2);

done_testing();
