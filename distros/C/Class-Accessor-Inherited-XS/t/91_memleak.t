use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? ('no_plan') : (skip_all => 'requires Test::LeakTrace');
use Test::LeakTrace;

$SIG{__WARN__} = \&CORE::die;

{
    package Jopa;
    use parent 'Class::Accessor::Inherited::XS::Compat';
}

Jopa->mk_inherited_accessors('foo');

no_leaks_ok {
    for (1..100) {
        undef *{Jopa::foo};
        Jopa->mk_inherited_accessors("foo");
    }
};

no_leaks_ok {
    for (1..100) {
        undef *{Jopa::foo};
        my $bar;
        Jopa->mk_type_accessors(class => [foo => sub {$bar; 42}]);
        Jopa->foo;
    }
};

no_leaks_ok {
    for (1..100) {
        undef *{Jopa::foo};
        my $bar;
        Jopa->mk_type_accessors(class => [foo => sub {$bar; 42}]);
    }
};

no_leaks_ok {
    for (1..100) {
        Jopa->mk_inherited_accessors("foo_$_");
        undef *{"Jopa::foo_$_"};
    }
};

my $obj = bless {}, 'Jopa';
no_leaks_ok {
    $obj->foo;
};

$obj->{foo} = 42;
no_leaks_ok {
    $obj->foo;
};

no_leaks_ok {
    my $z = \($obj->foo(24));
};

no_leaks_ok {
    $obj->foo(24);
};

no_leaks_ok {
    Jopa->foo;
};

no_leaks_ok {
    Jopa->foo('bar');
};

Jopa->mk_inherited_accessors("foobaz");

no_leaks_ok {
    Jopa->foobaz('bar');
};

no_leaks_ok {
    Jopa->foobaz;
};
