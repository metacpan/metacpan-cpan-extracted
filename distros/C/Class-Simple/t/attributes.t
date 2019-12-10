# $Id: attributes.t,v 1.1 2007/08/23 19:12:29 sullivan Exp $

package Foo;
use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok('Class::Simple') };		##

use base qw(Class::Simple);

sub ATTRIBUTES
{
	return qw(foo bar _baz);
}

my $f = Foo->new();

eval { $f->set_foo(1) };
ok(!$@, 'foo() exists');			##

eval { $f->set_bar(1) };
ok(!$@, 'bar() exists');			##

eval { $f->_baz(1) };
ok(!$@, 'baz() exists');			##

eval { $f->set_moo(1) };
like($@, qr/moo is not a defined attribute/,
  'moo() does not exist');			##

my $b = Foo->new(foo => 2, bar => 1);
is($b->bar, 1, 'initializer worked');           ##

throws_ok { Foo->new(wombat => 1) } qr/wombat is not a defined attribute/,
  'caught bad attribute in initialization';     ##

1;
