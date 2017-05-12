use warnings;
use strict;
use lib qw(lib);
use Test::More;
use Class::Accessor::Fast::WithBuilder;

plan tests => 10;

{
    eval q[
        package Class;
        use base 'Class::Accessor::Fast::WithBuilder';
        __PACKAGE__->mk_accessors('foo');
        1;
    ];

    like($@, qr{Class::_build_foo}, '_build_foo() is required');
}

{
    eval q[
        package Class;
        __PACKAGE__->mk_accessors('foo');
        sub _build_foo { 42 }
        1;
    ];

    is($@, '', '_build_foo() is defined');
    is(Class->new->foo, 42, 'foo() has 42 as default value');
}

{
    my $obj = Class->new({ foo => 123 });
    is($obj->foo, 123, 'foo() got 123 from constructor');
    is($obj->foo(234), 234, 'foo() is set to 234');
}

{
    eval q[
        package Class;
        use base 'Class::Accessor::Fast::WithBuilder';
        __PACKAGE__->mk_ro_accessors('bar');
        sub _build_bar { 'BAR!' }
        1;
    ];

    is($@, '', '_build_bar() is defined');
    is(Class->new->bar, 'BAR!', 'bar() has BAR! as default value');

    my $obj = Class->new({ bar => 567 });
    is($obj->bar, 567, 'bar() got 567 from constructor');

    eval { $obj->bar("some value") };
    like($@, qr{cannot alter}, 'bar() is read-only');
}

TODO: {
    eval { Class->make_wo_accessor('some_accessor') };
    like($@, qr{not implemented}, 'make_wo_accessor() is not implemented');
}
