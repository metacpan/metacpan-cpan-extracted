#!/usr/bin/perl

use warnings;
use strict;
use CSS::LESSp;

my $file = $ARGV[0];

die "you must specify file" if !$file;

my $buffer;
open(IN, $file);
for ( <IN> ) { $buffer .= $_ };
close(IN);

my @css = CSS::LESSp->parse($buffer);

print join("", @css);
