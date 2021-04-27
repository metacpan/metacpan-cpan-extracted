#!/usr/bin/env perl
use strict;
use warnings;

my $file = shift;
open my $IN,  '<', $file       or die $!;
open my $OUT, '>', "$file.out" or die $!;
while (<$IN>) {
  s!(\d+):34:12!{sprintf "%02d:34:12", $1 + 1}!e;
  print {$OUT} $_;
}

close $OUT;
rename "$file.out", "$file" or die $!;
exit 0;
