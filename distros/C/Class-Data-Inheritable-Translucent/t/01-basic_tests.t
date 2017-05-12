#!perl -T

use 5.008001;

use Test::More tests => 18;

package Foo;
use base 'Class::Data::Inheritable::Translucent';

__PACKAGE__->mk_translucent(foo => "base");
__PACKAGE__->mk_translucent(bar => "inherited");
__PACKAGE__->mk_translucent(baz => "object");
__PACKAGE__->mk_translucent(attr => 1);
sub attr { return 2 }
sub _attr_accessor { return 3 }

sub new {
    return bless {}, shift;
}

package Bar;
use base 'Foo';

package main;

is(Foo->foo, "base", "mk_translucent Ok");
Foo->foo("foobar");
is(Foo->foo, "foobar", "class data Ok");

is(Bar->bar, "inherited", "inheritance Ok");
Bar->bar("seedy bar");
is(Bar->bar, "seedy bar", "inheritance 2 Ok");

my $obj  = Foo->new;
is($obj->baz, "object", "see thru Ok");
$obj->baz("object a");
is($obj->baz, "object a", "translucency Ok");
is(Foo->baz, "object", "class default Ok");
$obj->baz(undef);
is($obj->baz, "object", "undef Ok");
is(Foo->baz, "object", "class default still Ok");

my $subobj = Bar->new;
is($subobj->baz, "object", "sub-class see thru Ok");
$subobj->baz("object a");
is($subobj->baz, "object a", "sub-class translucency Ok");
is(Bar->baz, "object", "sub-class default Ok");
Foo->baz("whatever");
is(Bar->baz, "whatever", "sub-class default not overridden");
$subobj->baz(undef);
is($subobj->baz, "whatever", "sub-class undef Ok");
is(Bar->baz, "whatever", "sub-class default still Ok");
Foo->baz("object");
is(Bar->baz, "object", "sub-class default still not overridden");

is(Foo->attr, "2", "Existing name is not ovewrwritten");
is(Foo->_attr_accessor, "3", "Existing alias is not ovewrwritten");
