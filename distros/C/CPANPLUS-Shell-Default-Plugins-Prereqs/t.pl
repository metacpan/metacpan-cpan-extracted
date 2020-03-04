#!/usr/bin/env perl

use 5.020;
use strict;
use warnings;
use Perl6::Junction qw(all);

my $r = qr{/prereqs};
my $x = "\n   /prereqs  \nasdf";
say "hi";
say "ok" if $x =~ $r;

