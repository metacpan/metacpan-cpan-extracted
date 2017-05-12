#!perl -w
use strict;
use Test::More tests => 32;

use Test::Exception;

use constant HAS_SCOPE_GUARD => eval{ require Scope::Guard };

use Data::Util qw(:all);

sub foo{ @_ }

ok is_code_ref(curry(\&foo, 42)), 'curry()';

is_deeply [curry(\&foo, 42)->()],   [42], 'without placeholders, in list context';
is_deeply [curry(\&foo, 42)->(38)], [42];

is_deeply [curry(\&foo, \0,  2)->(3)],    [3, 2], 'with subscriptive placeholders';
is_deeply [curry(\&foo, \1, \0)->(2, 3)], [3, 2];
is_deeply [curry(\&foo, \0, 2, \1)->(1, 3)], [1, 2, 3];
is_deeply [curry(\&foo, \0, \0, \0)->(42)], [42, 42, 42];

is_deeply [scalar curry(\&foo, \(0 .. 2))->(1, 2, 3)], [3], 'in scalar context';

is_deeply [curry(\&foo, *_)->(1 .. 10)], [1 .. 10], 'with *_';

is_deeply [curry(\&foo, *_, 3)->(1, 2)], [1, 2, 3], '*_, x';
is_deeply [curry(\&foo, 1, *_)->(2, 3)], [1, 2, 3], 'x, *_';
is_deeply [curry(\&foo, *_, 1, *_)->(2, 3)], [2, 3, 1, 2, 3], '*_, x, *_';
is_deeply [curry(\&foo, *_, \0, \1)->(1, 2, 3, 4)], [3, 4, 1, 2], '*_, \\0, \\1';
is_deeply [curry(\&foo, \1, \0, *_)->(1, 2, 3, 4)], [2, 1, 3, 4], '\\0, \\1, *_';


{
	package Foo;
	sub new{ bless {}, shift }
	sub foo{ @_ }
}

my $o = Foo->new;
is_deeply [curry($o, foo => 42)->()],   [$o, 42], 'method curry';
is_deeply [curry($o, foo => \0)->(38)], [$o, 38];
is_deeply [curry($o, foo => *_)->(1, 2, 3)], [$o, 1, 2, 3];
is_deeply [curry(\0, foo => 1, 2, 3)->($o)], [$o, 1, 2, 3];
is_deeply [curry(\0, \1, *_)->($o, foo  => 1, 2, 3)], [$o, 1, 2, 3];
is_deeply [curry(\1, \0, *_)->(foo => $o,  1, 2, 3)], [$o, 1, 2, 3];

# has normal argument semantics
sub incr{
	$_++ for @_;
}
{
	my $i = 0;
	curry(\&incr, $i)->();
	is $i, 1, 'argument semantics (alias)';

	curry(\&incr, \0)->($i);
	is $i, 2;

	curry(\&incr, *_)->($i);
	is $i, 3;
}

SKIP:{
	skip 'requires Scope::Gurard for testing GC', 5 unless HAS_SCOPE_GUARD;

	my $i = 0;

	curry(\&foo, Scope::Guard->new(sub{ $i++ }))->()  for 1 .. 3;

	is $i, 3, 'GC';

	curry(\&foo, \0)->(Scope::Guard->new(sub{ $i++ })) for 1 .. 3;

	is $i, 6;

	curry(\&foo, *_)->(Scope::Guard->new(sub{ $i++ })) for 1 .. 3;

	is $i, 9;

	curry(Foo->new, 'foo', Scope::Guard->new(sub{ $i++ }))->() for 1 .. 3;

	is $i, 12;

	for(1 .. 3){
		curry( Scope::Guard->new(sub{ $i++ }) );
	}

	is $i, 15;
}

is_deeply [curry(\&foo, \undef)->(42)], [\undef], 'not a placeholder';

throws_ok {
	curry(\&undefined_function)->();
} qr/Undefined subroutine/;

throws_ok {
	curry($o, 'undefined_method')->();
} qr/Can't locate object method/;

dies_ok{
	no warnings 'uninitialized';
	curry(undef, undef)->();
} 'bad arguments';
