use strict;
use warnings;
use utf8;
use Test::More;

{
    package Foo;
}

{
    package MyApp;
    use Class::Data::Lazy qw(
        foo
    );

    sub _build_foo {
        my $class = shift;
        bless [], Foo::;
    }
}

ok(MyApp->can('foo'));
my $f1 = MyApp->foo();
my $f2 = MyApp->foo();
isa_ok $f1, "Foo";
is "$f1", "$f2", 'returns same instance';

done_testing;

