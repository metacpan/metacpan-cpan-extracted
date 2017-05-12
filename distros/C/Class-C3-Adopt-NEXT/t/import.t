use strict;
use warnings;
use Test::More tests => 1;

use Class::C3::Adopt::NEXT;

{
    package BaseClass;
    sub foo { 42 }
}

{
    package Derived;

#    no warnings 'Class::C3::Adopt::NEXT';
    use Class::C3::Adopt::NEXT -no_warn;

    sub foo {
        return shift->NEXT::foo(@_);
    }
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

Derived->foo;

is(scalar @warnings, 0, '-no_warn disables warnings');
