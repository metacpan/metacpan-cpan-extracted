#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 16;

package Foo;
use parent 'Class::Accessor::Constructor';
__PACKAGE__->mk_constructor_with_dirty->mk_accessors(qw(firstname lastname));

package Bar;
use parent 'Class::Accessor::Constructor';
__PACKAGE__->mk_constructor->mk_accessors(qw(firstname lastname));

package main;

sub is_dirty {
    my ($obj, $testname) = @_;
    ok($obj->dirty, sprintf("[%s] %s: dirty", ref $obj, $testname));
}

sub isnt_dirty {
    my ($obj, $testname) = @_;
    ok(!$obj->dirty, sprintf("[%s] %s: not dirty", ref $obj, $testname));
}

sub clean {
    my $obj = shift;
    $obj->clear_dirty;
    isnt_dirty($obj, 'cleared dirty flag');
}

# run some tests on an object whose class uses the dirty flag
{
    my $o = Foo->new(firstname => 'John');
    is_dirty($o, 'setting firstname');
    clean($o);
    my $firstname = $o->firstname;
    isnt_dirty($o, 'reading firstname');
    $o->lastname('Smith');
    is_dirty($o, 'setting lastname');
    clean($o);
    $o->lastname('Smith');
    is_dirty($o, 'setting lastname to same value');
    clean($o);
    $o->{lastname} = 'Foobar';
    is_dirty($o, 'setting lastname via hash key');
}

# now run the same tests on an object whose class doesn't use the dirty flag
{
    my $o = Bar->new(firstname => 'John');
    isnt_dirty($o, 'setting firstname');
    clean($o);
    my $firstname = $o->firstname;
    isnt_dirty($o, 'reading firstname');
    $o->lastname('Smith');
    isnt_dirty($o, 'setting lastname');
    clean($o);
    $o->lastname('Smith');
    isnt_dirty($o, 'setting lastname to same value');
    clean($o);
    $o->{lastname} = 'Foobar';
    isnt_dirty($o, 'setting lastname via hash key');
}
