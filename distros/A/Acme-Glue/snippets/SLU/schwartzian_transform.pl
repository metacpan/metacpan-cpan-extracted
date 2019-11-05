#!/usr/bin/env perl
# https://en.wikipedia.org/wiki/Schwartzian_transform
# Sort list of words according to word length

print "$_\n" foreach
  map  { $_->[0] }
  sort { $a->[1] <=> $b->[1] or $a->[0] cmp $b->[0] }
  map  { [$_, length($_)] }
  qw(demo of schwartzian transform);
