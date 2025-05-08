use Const::XS qw/all/;
use Test::More;

my $foo = 'a scalar value';
make_readonly($foo);

eval { $foo = 'kaput' };
like($@, qr/Modification of a read-only value attempted/); 

is($foo, 'a scalar value');

unmake_readonly($foo);

is($foo, 'a scalar value');

$foo = 'kaput';

is($foo, 'kaput');

my $ref = [ qw/1 2 3/, { deep => { deeper => { one => 1 } } } ];

make_readonly($ref);

is($ref->[3]->{deep}->{deeper}->{one}, 1);

eval { $ref->[3]->{deep}->{deeper}->{one} = 'kaput' };

like($@, qr/Modification of a read-only value attempted/); 

unmake_readonly($ref);

$ref->[3]->{deep}->{deeper}->{one} = 'kaput';

is($ref->[3]->{deep}->{deeper}->{one}, 'kaput');

make_readonly($ref);

eval { $ref->[3]->{deep}->{deeper}->{one} = 'again' };

like($@, qr/Modification of a read-only value attempted/);

my $foo2 = 'abc';

make_readonly($foo2);

is($foo2, 'abc');

eval { $foo2 = 'nope' };

is($foo2, 'abc');

done_testing();
