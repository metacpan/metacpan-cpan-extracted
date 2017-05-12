#!perl -w

# NOTE:
# 5.10.0 leak an AV about weak refs.
# 5.8.x seems to leak some SVs, but it's just a cache.

use strict;

use constant HAS_LEAKTRACE => eval q{ use Test::LeakTrace 0.08; 1 };

use Test::More HAS_LEAKTRACE ? (tests => 3) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use Class::Monadic;

{
	package Foo;
	my $i;

	sub new{
		bless [], shift;
	}
	sub bar{ $i++ }
}

no_leaks_ok{
	my $o = Foo->new();

	Class::Monadic->initialize($o)->add_method(hello => sub {
		my $i;
		$i++;
	});
	$o->bar();
	$o->hello();

} 'add_method';


no_leaks_ok{
	my $o = Foo->new();

	Class::Monadic->initialize($o)->add_field(foo => [qw(banana apple)]);
	$o->bar();
	$o->set_foo('banana');

} 'add_field';

leaks_cmp_ok{
	my $o = Foo->new();
	{ package X; package Y; }

	Class::Monadic->initialize($o)->inject_base('X', 'Y');
} '<=', ($] < 5.010 ? 1 : 0), 'inject_base';
