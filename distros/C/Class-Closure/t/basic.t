use strict; use warnings;

use Test::More tests => 18;

my ( $foodestr, $bardestr );

package Foo;

use Class::Closure;

sub CLASS {
	destroy { $foodestr++ };

	my $a = 1;              # Private
	has( my $b ) = 2;       # Read Only
	public( my $c ) = 3;    # Er, yep, public
	accessor d => (         # Magic accessor.
		set => sub { $b = $_[1] },
		get => sub { $c },
	);
	method e => sub { 2*$_[1] };
	method f => sub { 2*$_[0]->g };
};

package Baz;

sub new { bless { x => 42 } => $_[0] }

sub g : lvalue { $_[0]->{x} }

package Bar;

use Class::Closure;

sub CLASS {
	destroy { $bardestr++ };

	extends 'Foo';
	extends 'Baz';

	has my $b;

	method BUILD => sub { $b = 13; };
	method FALLBACK => sub { 69 };
}

package main;

Bar->new;
is $bardestr, 1, 'Destroy';
is $foodestr, 1, 'Destroy';

Foo->new;
is $bardestr, 1, 'Destroy';
is $foodestr, 2, 'Destroy';

my $foo = Foo->new;
my $bar = Bar->new;
ok !eval { $foo->a },      'Private Read';
is $foo->b, 2,             'Read Only Read';
ok !eval { $foo->b = 50 }, 'Read Only Write';
is $foo->c, 3,             'Public Read';
is $foo->c = 4, 4,         'Public Write';
is $foo->c, 4,             'Public Readback';
is $foo->d, $foo->c,       'Accessor Read';
is $foo->d = 10, $foo->c,  'Accessor Write';
is $foo->b, 10,            'Accessor Readback';
is $foo->e(21), 42,        'Method Call';
is $bar->nada, 69,         'Fallback';
is $bar->c, 3,             'Extends';
is $bar->b, 13,            'Build/Extends';
is $bar->f, 84,            'Extends/Represents';
