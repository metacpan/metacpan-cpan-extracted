#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Binding;

our $a = 1;

sub foo {
    our $b = 2;
    bar();
}

sub bar {
    my $vars = Binding->of_caller->our_vars;
    is_deeply($vars, { '$a' => \1, '$b' => \2});
}

foo();



