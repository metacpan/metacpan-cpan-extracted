#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 5;

package Foo::Base;
use parent 'Data::Inherited';
use constant PLAN => 11;

sub planned_test_count {
    my $self = shift;
    my $plan;
    $plan += $_ for $self->every_list('PLAN');
    $plan;
}

package Foo::Bar;
our @ISA = qw/Foo::Base/;
use constant PLAN => 3;

package Foo::Bar::Baz;
our @ISA = qw/Foo::Bar/;
use constant PLAN => 5;

package Foo::Frobnule;
our @ISA = qw/Foo::Base/;
use constant PLAN => 7;

package Foo::Everything;

# test diamond inheritance as well
our @ISA = qw/Foo::Frobnule Foo::Bar::Baz/;

package main;
use Test::More;

sub plans_ok {
    my ($package, $expected_count) = @_;
    is($package->planned_test_count,
        $expected_count,
        sprintf("package %s plans %d in total", $package, $expected_count));
}
plans_ok('Foo::Base'     => 11);
plans_ok('Foo::Bar'      => 14);
plans_ok('Foo::Bar::Baz' => 19);
plans_ok('Foo::Frobnule' => 18);

# Note that with diamond inheritance, common superclasses are counted only
# once.
plans_ok('Foo::Everything' => 26);
