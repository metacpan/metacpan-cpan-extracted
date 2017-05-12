# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-Nooo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 3;
require Acme::Nooo;
ok(1, 'loaded');

package Annoying;

sub new
{
    bless [], Annoying;
}

sub f
{
    shift; "OO";
}

package Annoying2;

our $foo;

sub new
{
    shift;
    bless { blah => shift }, Annoying2;
}

sub f2
{
    shift->{blah}
}

package main;
use Acme::Nooo 'Annoying';
use Acme::Nooo ['Annoying2', 'blah'];

sub g { f(); }

sub h { g; }

ok(h() eq 'OO', 'no-args');
ok(f2() eq 'blah', 'with-args');
