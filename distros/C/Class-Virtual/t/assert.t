#!/usr/bin/perl -w

# rt.cpan.org 6298
use Test::More tests => 1;

package Foo;

use base qw(Class::Virtually::Abstract);
eval {
    __PACKAGE__->virtual_methods(qw(assert affirm));
};
::is $@, '', 'assert and affirm do not leak';
