#!/usr/bin/env perl

use Atto qw(hello);

sub hello {
    my (%args) = @_;
    my $name = $args{name} // "world";
    return "hello $name";
}

Atto->psgi;
