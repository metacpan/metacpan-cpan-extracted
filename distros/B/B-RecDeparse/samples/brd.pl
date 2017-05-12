#!/usr/bin/env perl

use strict;
use warnings;

use lib qw<blib/lib>;
use B::RecDeparse;

my $deparser = B::RecDeparse->new(deparse => [ '-sCi0v1' ], level => 1);

sub spec (&) {
 return unless defined $_[0] and ref $_[0] eq 'CODE';
 my $deparsed = $deparser->coderef2text($_[0]);
 print STDERR "$deparsed\n";
 my $code = eval 'sub ' . $deparsed;
 die if $@;
 $code;
}

sub add ($$) { $_[0] + $_[1] }

sub mul ($$) { $_[0] * $_[1] }

sub fma ($$$) { add +(mul $_[0], $_[1]), $_[2] }

print STDERR '### ', fma(1, 3, 2), "\n";
my $sfma = spec sub { my $x = \&mul; fma $_[0], 3, $_[1] };
print STDERR '### ', $sfma->(1, 2), "\n";
