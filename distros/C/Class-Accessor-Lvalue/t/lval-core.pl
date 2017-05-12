#!perl -w
use strict;
use Test::More tests => 12;
my $class;

BEGIN {
    $class = $ENV{'CLASS_ACCESSOR_LVALUE_CLASS'};
    require_ok( $class );
}

package Foo;
use base $class;
__PACKAGE__->mk_accessors(qw( foo bar ));
__PACKAGE__->mk_ro_accessors(qw( baz ));
__PACKAGE__->mk_wo_accessors(qw( quux ));
package main;

my $foo = Foo->new;

isa_ok( $foo, 'Foo' );
eval { $foo->bar = "test" };
is( $@, '', "assigned without errors" );
is( $foo->bar, "test", "got what I expected back" );

eval { $foo->baz = "test" };
like( $@, qr/^'main' cannot alter the value of 'baz' on objects of class 'Foo'/,
      "assigning to a readonly accessor fails" );

eval { $foo->quux = "test" };
is( $@, "", "wo: assign to an lvalue" );
is( $foo->{quux}, "test", "wo: really set it" );

eval { $foo->quux };
like( $@, qr/^'main' cannot access the value of 'quux' on objects of class 'Foo'/,
      "wo: read fails" );

# The ->foo = ->bar might have failed, handily though, the order of
# evalution is
#  LVAL(bar) FETCH LVAL(bar) STORE
# otherwise our speed cheat of reusing the same tie would fall over

$foo->foo = 'foo';
$foo->bar = 'bar';
$foo->foo = $foo->bar;
is( $foo->foo, 'bar', "accessor = accessor" );
is( $foo->bar, 'bar' );


# for C<$foo->foo = $foo->bar = 'constant';> it does fall over,
# the order of evaluation is probably
#   LVAL(bar) LVAL(foo) STORE STORE
$foo->foo = $foo->bar = 'chain';
is( $foo->foo, 'chain', "accessor = accessor = val" );
is( $foo->bar, 'chain');
