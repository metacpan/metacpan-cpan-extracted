use strict;
use lib "t/lib";
use Test::More (tests => 11);
use Catalyst::Test 'TestApp';

my $o = TestApp->model('Orochi');
ok($o);

{ # check injections
    ok($o->has_injections);
    isa_ok( $o->injections, 'HASH' );
    is($o->injections->{foo}, "foo_001");
    is($o->injections->{bar}, "bar_001");
}

{ # check classes
    ok($o->has_classes);
    isa_ok( $o->classes, 'ARRAY' );
    is( $o->classes->[0], 'TestApp::Component::Foo' );
}

{ # now the actual materialization
    my $foo = $o->get('component/foo');
    ok($foo);
    isa_ok( $foo, 'TestApp::Component::Foo' );
    is( $foo->foo, 'foo_001' );
}