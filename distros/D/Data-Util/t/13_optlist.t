#!perl -w

use strict;
use Test::More tests => 48;
use Test::Exception;

use Data::Util qw(:all);

use constant PP_ONLY => $INC{'Data/Util/PurePerl.pm'};

BEGIN{
	package Foo;
	sub new{
		bless {}, shift;
	}

	package MyArray;
	our @ISA = qw(Foo);
	use overload
		bool  => sub{ 1 },
		'@{}' => sub{  ['ARRAY'] },
	;
	package MyHash;
	our @ISA = qw(Foo);
	use overload
		bool  => sub{ 1 },
		'%{}' => sub{ +{ foo => 'ARRAY' } },
	;

	package BadHash;
		our @ISA = qw(Foo);
	use overload
		bool => sub{ 1 },
		'%{}' => sub{ ['ARRAY'] },
	;
}

use constant true  => 1;
use constant false => 0;

# mkopt

is_deeply mkopt(undef), [], 'mkopt()';

is_deeply mkopt([]), [];
is_deeply mkopt(['foo']), [ [foo => undef] ];
is_deeply mkopt([foo => undef]), [ [foo => undef] ];
is_deeply mkopt([foo => [42]]), [ [foo => [42]] ];
is_deeply mkopt([qw(foo bar baz)]), [ [foo => undef], [bar => undef], [baz => undef]];

is_deeply mkopt({foo => undef}), [ [foo => undef] ];
is_deeply mkopt({foo => [42]}),  [ [foo => [42]] ];

is_deeply mkopt([qw(foo bar baz)], undef, true), [[foo => undef], [bar => undef], [baz => undef]], 'unique';

is_deeply mkopt([foo => [], qw(bar)], undef, false, 'ARRAY'), [[foo => []], [bar => undef]], 'validation';
is_deeply mkopt([foo => [], qw(bar)], undef, false, ['CODE', 'ARRAY']), [[foo => []], [bar => undef]];
is_deeply mkopt([foo => anon_scalar], undef, false, 'SCALAR'), [[foo => anon_scalar]];
is_deeply mkopt([foo => \&ok],       undef, false, 'CODE'),   [[foo => \&ok]];
is_deeply mkopt([foo => Foo->new], undef, false, 'Foo'), [[foo => Foo->new]];

is_deeply mkopt(MyArray->new()), [ [ARRAY => undef] ], 'overloaded data (ARRAY)';

is_deeply mkopt([foo => [], qw(bar)], undef, false, {foo => 'ARRAY'}),   [[foo => []], [bar => undef]];
is_deeply mkopt([foo => [], bar => {}], undef, false, {foo => ['CODE', 'ARRAY'], bar => 'HASH'}), [[foo => []], [bar => {}]];

is_deeply mkopt([foo => [42]], undef, false, MyArray->new()), [[foo => [42]]], 'overloaded validator (ARRAY)';

is_deeply mkopt([foo => [42]], 'test', false, MyHash->new()),  [[foo => [42]]], 'overloaded validator (HASH)';
dies_ok{
	mkopt([foo => {}], 'test', false, MyHash->new());
};

# mkopt_hash

is_deeply mkopt_hash(undef), {}, 'mkopt_hash()';

is_deeply mkopt_hash([]), {};
is_deeply mkopt_hash(['foo']), { foo => undef };
is_deeply mkopt_hash([foo => undef]), { foo => undef };
is_deeply mkopt_hash([foo => [42]]), { foo => [42] };
is_deeply mkopt_hash([qw(foo bar baz)]), { foo => undef, bar => undef, baz => undef };

is_deeply mkopt_hash({foo => undef}), { foo => undef };
is_deeply mkopt_hash({foo => [42]}),  { foo => [42] };

is_deeply mkopt_hash([foo => [], qw(bar)], undef, 'ARRAY'), {foo => [], bar => undef}, 'validation';
is_deeply mkopt_hash([foo => [], qw(bar)], undef, ['CODE', 'ARRAY']), {foo => [], bar => undef};
is_deeply mkopt_hash([foo => Foo->new], undef, 'Foo'), {foo => Foo->new};

is_deeply mkopt_hash([foo => [], qw(bar)], undef, {foo => 'ARRAY'}),   {foo => [], bar => undef};
is_deeply mkopt_hash([foo => [], bar => {}], undef, {foo => ['CODE', 'ARRAY'], bar => 'HASH'}), {foo => [], bar => {}};

# XS specific misc. check
my $key = 'foo';
my $ref = mkopt([$key]);
$ref->[0][0] .= 'bar';
is $key, 'foo';
$ref = mkopt_hash([$key]);
$key .= 'bar';
is_deeply $ref, {foo => undef};

sub f{
	return mkopt(@_);
}

{
	my $a = mkopt(my $foo = ['foo']); push @$foo, 42;
	my $b = mkopt(my $bar = ['bar']); push @$bar, 42;
	is_deeply $a, [[foo => undef]], '(use TARG)';
	is_deeply $b, [[bar => undef]], '(use TARG)';
}
# unique
throws_ok{
	mkopt [qw(foo foo)], "mkopt", 1;
} qr/multiple definitions/i, 'unique-mkopt';
throws_ok{
	mkopt_hash [qw(foo foo)], "mkopt", 1;
} qr/multiple definitions/i, 'unique-mkopt_hash';

# validation

throws_ok{
	mkopt [foo => []], "test", 0, 'HASH';
} qr/ARRAY-ref values are not valid.* in test opt list/;
throws_ok{
	mkopt [foo => []], "test", 0, [qw(SCALAR CODE HASH GLOB)];
} qr/ARRAY-ref values are not valid.* in test opt list/;
throws_ok{
	mkopt [foo => []], "test", 0, 'Bar';
} qr/ARRAY-ref values are not valid.* in test opt list/;

throws_ok{
	mkopt [foo => Foo->new], "test", 0, 'Bar';
} qr/Foo-ref values are not valid.* in test opt list/;
throws_ok{
	mkopt [foo => Foo->new], "test", 0, ['CODE', 'Bar'];
} qr/Foo-ref values are not valid.* in test opt list/;


# bad uses

dies_ok{
	mkopt [], 'test', 0, anon_scalar();
};

dies_ok{
	mkopt anon_scalar();
};
dies_ok{
	mkopt_hash anon_scalar();
};

dies_ok{
	mkopt(BadHash->new(), 'test');
};
