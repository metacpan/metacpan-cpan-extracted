#!perl -w

use strict;

use Class::ClassDecorator;

use Test::More tests => 27;

{
    package Foo::Base;

    sub new { bless {}, shift }

    sub foo { 'base' }
}

{
    package Foo::Bar;

    sub foo { 'bar' }

    sub bar { 'also bar' }

    sub other { 'in bar' }
}

{
    package Foo::Baz;

    sub baz { 'baz' }

    sub other { 'in baz' }
}

{
    my $class = Class::ClassDecorator::decorate( 'Foo::Base', 'Foo::Bar', 'Foo::Baz' );

    my $object = $class->new;

    foreach my $c ( qw( Foo::Base Foo::Bar Foo::Baz ) )
    {
        isa_ok( $object, $c );
    }

    foreach my $m ( qw( foo bar baz other ) )
    {
        can_ok( $object, $m );
    }

    is( $object->foo,   'bar' );
    is( $object->bar,   'also bar' );
    is( $object->baz,   'baz' );
    is( $object->other, 'in baz' );
}

{
    my $class = Class::ClassDecorator::decorate( 'Foo::Base', 'Foo::Baz', 'Foo::Bar' );

    my $object = $class->new;

    foreach my $c ( qw( Foo::Base Foo::Bar Foo::Baz ) )
    {
        isa_ok( $object, $c );
    }

    foreach my $m ( qw( foo bar baz other ) )
    {
        can_ok( $object, $m );
    }

    is( $object->foo,   'bar' );
    is( $object->bar,   'also bar' );
    is( $object->baz,   'baz' );
    is( $object->other, 'in bar' );
}

{
    package Super::Base;

    sub new { bless {}, shift }

    sub meth { 'base' }
}

{
    package Super::Foo;

    sub new { bless {}, shift }

    sub meth { join ' ', 'foo', shift->NEXT::meth() }
}

{
    package Super::Bar;

    sub new { bless {}, shift }

    sub meth { join ' ', 'bar', shift->NEXT::meth() }
}

{
    my $class = Class::ClassDecorator::decorate( 'Super::Base', 'Super::Foo', 'Super::Bar' );

    is( $class->meth, 'bar foo base' );
}

{
    my $class = Class::ClassDecorator::decorate( 'Super::Base', 'Super::Bar', 'Super::Foo' );

    is( $class->meth, 'foo bar base' );
}

{
    package Super::NoMeth;

    sub new { bless {}, shift }
}

{
    package Super::HasMeth;

    sub new { bless {}, shift }

    sub meth { join ' ', 'has', shift->NEXT::meth() }
}

{
    my $class =
        Class::ClassDecorator::decorate( 'Super::Base', 'Super::NoMeth', 'Super::HasMeth' );

    is( $class->meth, 'has base' );
}

{
    my $class =
        Class::ClassDecorator::decorate( 'Super::Base', 'Super::HasMeth', 'Super::NoMeth' );

    is( $class->meth, 'has base' );
}

{
    my $class1 =
        Class::ClassDecorator::decorate( 'Super::Base', 'Super::NoMeth', 'Super::HasMeth' );

    my $class2 =
        Class::ClassDecorator::decorate( 'Super::Base', 'Super::NoMeth', 'Super::HasMeth' );

    is( $class1, $class2, 'generated classes are cached' );
}
