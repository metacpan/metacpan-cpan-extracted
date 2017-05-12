#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Binding;

sub foo {
    my ($a, $b) = (1,2);
    bar();
}

sub bar {
    my $vars = Binding->of_caller->my_vars;
    is_deeply($vars, { '$a' => \1, '$b' => \2});
}

foo();
