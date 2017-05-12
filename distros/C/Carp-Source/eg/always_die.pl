#!/usr/bin/env perl
use warnings;
use strict;
use Carp::Source::Always;
sub f { die "arghh" }
sub g { f }
g();
