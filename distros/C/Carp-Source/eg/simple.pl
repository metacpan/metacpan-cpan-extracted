#!/usr/bin/env perl
use warnings;
use strict;
use Carp::Source 'source_cluck';

sub foo {
    my $value = shift;
    my $x     = 1;
    if ($value % 2) {
        $x++;
    } else {
        bar(25, 42);
        $x += 2;
    }
}

sub bar {
    my ($x, $y) = @_;
    our $z = $x + baz($y);
}

sub baz {
    my $x = shift;
    source_cluck 'baz';
    return $x * 2;
}
foo(4);
