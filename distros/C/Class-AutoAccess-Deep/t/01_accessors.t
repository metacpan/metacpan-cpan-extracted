#$Id: 01_accessors.t 22 2005-09-10 14:48:45Z kentaro $

use strict;
use Test::More tests => 8;
use Test::Exception;

package MyClass;

use base qw(Class::AutoAccess::Deep);

sub to_check { 'my own method called correctly' }

package main;

my $data = {
    foo => undef,
    bar => {
        baz => undef,
    },
    to_check => undef,
};

my ($foo, $baz) = qw(aaa bbb);

my $obj = MyClass->new($data);

isa_ok $obj     , 'Class::AutoAccess::Deep';
isa_ok $obj->bar, 'Class::AutoAccess::Deep';

# setters
$obj->foo($foo);
$obj->bar->baz($baz);

# getters
is $obj->foo     , $foo;
is $obj->bar->baz, $baz;

# my own method
is $obj->to_check, 'my own method called correctly';

# access undefined field
dies_ok {$obj->undefined};

# throws exception when constructor is called with the illegal value
dies_ok {MyClass->new};
dies_ok {MyClass->new('string')};
