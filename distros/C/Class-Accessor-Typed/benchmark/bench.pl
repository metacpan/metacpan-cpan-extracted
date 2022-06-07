#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Benchmark qw(:all);

{
    package Fast::Obj;
    use parent 'Class::Accessor::Fast';
    Fast::Obj->mk_accessors(qw(foo));
}
{
    package Lite::Obj;
    use Class::Accessor::Lite (
        rw  => [qw/foo/],
        new => 1,
    );
}
{
    package Moo::Obj;
    use Moo;
    has foo => ( is => 'rw' );
}
{
    package Moo::WithISA::Obj;
    use Moo;
    has foo => ( is => 'rw', isa => sub { 1 } );
}
{
    package Typed::Obj;
    use Class::Accessor::Typed (
        rw  => {
            foo => 'Int',
        },
        new => 1,
    );
}
{
    package Moose::Obj;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');
}
{
    package Mouse::Obj;
    use Mouse;

    has 'foo' => (is => 'rw', isa => 'Int');
}

cmpthese -1, {
    'C::A::Fast' => sub {
        my $fast_obj = Fast::Obj->new({ foo => 1 });
        $fast_obj->foo(2);
        $fast_obj->foo();
    },
    'C::A::Lite' => sub {
        my $lite_obj = Lite::Obj->new( foo => 1 );
        $lite_obj->foo(2);
        $lite_obj->foo();
    },
    'C::A::Typed' => sub {
        my $typed_obj = Typed::Obj->new( foo => 1 );
        $typed_obj->foo(2);
        $typed_obj->foo();
    },
    'Moose' => sub {
        my $moose_obj = Moose::Obj->new( foo => 1 );
        $moose_obj->foo(2);
        $moose_obj->foo();
    },
    'Moo' => sub {
        my $moo_obj = Moo::Obj->new( foo => 1 );
        $moo_obj->foo(2);
        $moo_obj->foo();
    },
    'Moo(ISA)' => sub {
        my $isa_moo_obj = Moo::WithISA::Obj->new( foo => 1 );
        $isa_moo_obj->foo(2);
        $isa_moo_obj->foo();
    },
    'Mouse' => sub {
        my $mouse_obj = Mouse::Obj->new( foo => 1 );
        $mouse_obj->foo(2);
        $mouse_obj->foo();
    },
};
