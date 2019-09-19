use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package
        Foo;
    use Mouse::Role;

    package
        Bar;
    use Mouse;
    with 'Foo';

    package
        Baz;
    use Mouse;

    package
        L;

    use Class::Accessor::Typed (
        rw => {
            hoge => 'Foo',
        },
        new => 1,
    );
}

my $obj = L->new(hoge => Bar->new());
isa_ok $obj->hoge, 'Bar';

throws_ok {
    L->new(hoge => Baz->new());
} qr/'hoge': Validation failed for 'Foo' with value Baz/;

done_testing;
