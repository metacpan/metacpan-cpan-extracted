use strict;
use warnings;
use Test::More;

{
    package L;
    use Class::Accessor::Lite::Lazy;

    Class::Accessor::Lite::Lazy->mk_new;
    Class::Accessor::Lite::Lazy->mk_lazy_accessors('foo');

    sub _build_foo { rand() }
}

my $l = new_ok 'L';
is $l->foo, $l->foo;

done_testing;
