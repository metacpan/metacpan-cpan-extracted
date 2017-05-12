#!/usr/bin/perl

# tests stolen from Class::Data::Inheritable
use strict;
use warnings;

use Test::More tests => 11;

{
    package Ray;
    use base qw(Class::Data::Reloadable);

    package Gun;
    use base qw(Ray);

    package Suitcase;
    use base qw(Gun);
}

ok( Ray->can('mk_classdata') );
Ray->mk_classdata('Ubu');
ok( Ray->can('Ubu') );
ok( Ray->can('_Ubu_accessor') );

ok( Gun->can('Ubu') );
Gun->Ubu('Pere');
ok( Gun->Ubu eq 'Pere');

# Test that superclasses effect children.
ok( Suitcase->can('Ubu') );
ok( Suitcase->Ubu('Pere'));
ok( Suitcase->can('_Ubu_accessor') );

# Test that superclasses don't effect overriden children.
Ray->Ubu('Squonk');
ok( Ray->Ubu eq 'Squonk');
ok( Gun->Ubu eq 'Pere');
ok( Suitcase->Ubu eq 'Pere');
