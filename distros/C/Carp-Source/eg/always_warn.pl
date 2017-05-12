#!/usr/bin/env perl
use warnings;
use strict;
use Carp::Source::Always 'lines', 5, 'number', 0, 'color', 'yellow on_blue';
sub f { my $a = shift; my @a = @$a }
sub g { f(undef) }
g()
