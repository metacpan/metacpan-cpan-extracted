#!perl

sub ::RT_CHECKS(){0};

package MyClass::Foo;

use Class::Root "isa";

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use declare class_attribute ca10 => setopts {
    check_value => sub {
	( 10 < $_ and $_ < 25 ) ? "" : return "10 < X < 25";
    },
};

class_initialize;

class_verify;

package main;

use Test::More tests => 1;
use English;

use strict;
use warnings;

use MyClass::Foo;

eval "MyClass::Foo->ca10 = 9";

#1
is($EVAL_ERROR, "", "RT_CHECKS => 0: $foo->ca10 = 9");
