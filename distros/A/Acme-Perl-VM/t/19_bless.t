#!perl -w

use strict;
use Test::More tests => 15;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

apvm_extern 'Test::More';

{
    package Foo;

    sub new{
        my $class = shift;
        return bless {@_}, $class;
    }
    sub bar{ 'Foo::bar' }

    sub attr{
        $_[0]->{attr};
    }
    sub set_attr{
        $_[0]->{attr} = $_[1];
    }

    package DerivedFoo;
    our @ISA = qw(Foo);

    sub bar(){ 'DerivedFoo::bar' }
}

    

run_block{
    my $x = Foo->new(attr => 42);

    ok $x->isa('Foo');
    is $x->bar, 'Foo::bar';
    is $x->attr, 42;
    $x->set_attr(3.14);
    is $x->attr, 3.14;

    my $y = DerivedFoo->new(attr => 10);
    ok $y->isa('DerivedFoo');
    is $y->bar, 'DerivedFoo::bar';
    is $y->attr, 10;
    $y->set_attr(20);
    is $y->attr, 20;

    is $x->attr, 3.14;
};

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
