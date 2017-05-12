#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Binding;

local $TODO = "Not implemented";

sub add_x {
    my $binding = shift;
    $binding->eval('$x + 1');
}

sub add {
    my $x = 5;
    my $b = Binding->of_caller;
    add_x($b);                    # Expecting
}

my $x = 3;
my $ret = add;

is $ret, 4;



