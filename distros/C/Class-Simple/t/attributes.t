# $Id: attributes.t,v 1.1 2007/08/23 19:12:29 sullivan Exp $

package Foo;
use Test::More tests => 5;
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

1;
