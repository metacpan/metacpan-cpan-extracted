#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Clone::Closure qw/clone/;

my $tests;
my $gone;

package Test::Hash;

our @ISA = qw( Clone::Closure );

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
}

sub DESTROY {
    $gone++;
}

package main;

BEGIN { $tests += 1 }
$gone = 0;
{
    my $x = Test::Hash->new();
    my $y = $x->clone;
}
is  $gone,  2,          'both clone and orig are destroyed';

# benchmarking bug
BEGIN { $tests += 2 }
$gone = 0;
{
    my $x = Test::Hash->new();
    my $sref = sub { my $y = clone $x };
    $sref->();
    is $gone, 1,        'clone is destroyed, orig remains';
}
is $gone,   2,          'both are destroyed';

# test for cloning unblessed ref
BEGIN { $tests += 1 }
$gone = 0;
{
    my $x = {};
    my $y = clone $x;
    bless $x, 'Test::Hash';
    bless $y, 'Test::Hash';
}
is $gone,   2,          'unblessed {} has correct refcnt';

# test for cloning unblessed ref
BEGIN { $tests += 1 }
$gone = 0;
{
    my $x = [];
    my $y = clone $x;
    bless $x, 'Test::Hash';
    bless $y, 'Test::Hash';
}
is $gone,   2,          'unblessed [] has correct refcnt';

BEGIN { plan tests => $tests }
