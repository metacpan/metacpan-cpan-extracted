#!/usr/bin/env perl

use strict;
use warnings;

printf STDOUT 'perl: %s, Class::XSAccessor: %s%s', $], Class::XSAccessor->VERSION, $/;

package WithClassXSAccessor;

use blib;

use Class::XSAccessor {
    constructor => 'new',
};

package WithStdClass;

sub new { my $c = shift; bless {@_}, ref($c) || $c }

package main;

use Benchmark qw(cmpthese timethese :hireswallclock);

my $count = shift || -4;

print "Constructor benchmark:", $/;

cmpthese(timethese($count, {
    class_xs_accessor => sub {
        my $obj;
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
    },
    std_class => sub {
        my $obj;
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
    },
    class_xs_accessor_args => sub {
        my $obj;
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
        $obj = WithClassXSAccessor->new(foo => 'bar', baz => 'quux');
    },
    std_class_args => sub {
        my $obj;
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
        $obj = WithStdClass->new(foo => 'bar', baz => 'quux');
    },
}));
