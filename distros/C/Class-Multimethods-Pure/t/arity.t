use Test::More tests => 8;

BEGIN { use_ok('Class::Multimethods::Pure') }

multi foo => (Any) => sub { "ok @_" };

is(foo(1), "ok 1", "sanity check");
is(foo(1,2), "ok 1 2", "can pass additional arguments");
ok(!eval { foo(); 1 }, "no arguments dies");

package Foo;
sub new { bless {} => shift }
package Bar;
sub new { bless {} => shift }
package main;

multi bar => (Foo) => sub { "one" };
multi bar => (Foo, Foo) => sub { "two" };

is(bar(Foo->new),           "one", "single argument");
is(bar(Foo->new, Foo->new), "two", "double argument");
is(bar(Foo->new, Bar->new), "one", "single argument+extraneous");

multi qsort => () => sub { () };
multi qsort => (Any) => sub {
    my $x = shift;
    my @pre  = grep { $_ <  $x } @_;
    my @post = grep { $_ >= $x } @_;
    return qsort(@pre), $x, qsort(@post);
};

is_deeply([qsort(5,3,7,1,2,6,4)], [1..7], "quicksort");

# vim: ft=perl :
