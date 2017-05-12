use strict;
use warnings;

use Acme::Method::CaseInsensitive;

package MyClass;

sub Foo {
	return 1
}

sub baR {
	return 1
}

sub Foo_Bar {
	return 1
}

sub ggjhgJKHgasAS {
	return 1
}


sub hgfkjgjhgHJGFhjGa {
	return 1
}


package main;

use Test::Simple tests => 11;

my $obj = bless {}, "MyClass";

ok(MyClass->foo);
ok($obj->foo);

ok($obj->baR);
ok($obj->BAR);
ok($obj->bar);

ok($obj->foo_bar);
ok($obj->FOO_BAR);
ok($obj->fOO_bAR);

ok($obj->GgjHgJkHgasAs);
ok($obj->hgfkjgjhgHJGFhjGA);

eval { $obj->Doesnt_Exist };

ok($@);