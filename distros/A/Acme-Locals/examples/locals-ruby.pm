#!/usr/local/bin/perl

use strict;
use warnings;

use Acme::Locals qw(-ruby sayx);

sub hi {
    my $x = 10;
    my $y = 200;

    my $name = "George Constanza";

    sayx "x: #{x} y: #{y} name: #{name}";
}


hi();
