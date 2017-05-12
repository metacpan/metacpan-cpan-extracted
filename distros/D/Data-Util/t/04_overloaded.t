#!perl-w

use strict;
use Test::More tests => 36;
use Test::Exception;

use Data::Util qw(:all);

BEGIN{
	package Foo;
	use overload fallback => 1;
	sub new{
		bless {} => shift;
	}


	package MyArray;
	use overload
		'@{}' => 'as_array',
		fallback => 1;

	sub new{
		bless {array => []} => shift;
	}
	sub as_array{
		shift()->{array};
	}
	package AnyRef;
	use overload
		'@{}' => 'as_array',
		'%{}' => 'as_hash',
		'${}' => 'as_scalar',
		'*{}' => 'as_glob',
		'&{}' => 'as_code',
		fallback => 1;

	my $s;
	my @a;
	my %h;
	my $gref; select select $gref;
	sub c{1}

	sub new{
		bless {} => shift;
	}
	sub as_scalar{
		\$s;
	}
	sub as_array{
		\@a;
	}
	sub as_hash{
		\%h;
	}
	sub as_glob{
		$gref;
	}
	sub as_code{
		\&c;
	}

	package DerivedAnyRef;
	our @ISA = qw(AnyRef);

}

# :check

my $foo = Foo->new();
ok !is_array_ref($foo), 'check with overloaded';
ok !is_hash_ref($foo);

my $ma = MyArray->new();
ok  is_array_ref($ma);
ok !is_hash_ref($ma);
ok !is_scalar_ref($ma);
ok !is_code_ref($ma);
ok !is_glob_ref($ma);
ok !is_regex_ref($ma);

for my $ref(AnyRef->new(), DerivedAnyRef->new()){
	ok is_array_ref($ref);
	ok is_hash_ref($ref);
	ok is_scalar_ref($ref);
	ok is_code_ref($ref);
	ok is_glob_ref($ref);

}

# :validate

$foo = Foo->new();
dies_ok{
	array_ref($foo);
} 'validate with overloaded';
dies_ok{
	hash_ref($foo);
};

$ma = MyArray->new();
lives_and{
	ok  array_ref($ma);
};
dies_ok{ hash_ref($ma) };
dies_ok{ scalar_ref($ma) };
dies_ok{ code_ref($ma) };
dies_ok{ glob_ref($ma) };
dies_ok{ regex_ref($ma) };

for my $ref(AnyRef->new(), DerivedAnyRef->new()){
	lives_and{
		ok array_ref($ref);
		ok hash_ref($ref);
		ok scalar_ref($ref);
		ok code_ref($ref);
		ok glob_ref($ref);
	};
}
