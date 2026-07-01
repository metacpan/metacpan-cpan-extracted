#!/usr/bin/env perl
# Word-frequency counter via interning: each distinct word is interned to a dense
# id, and a plain array indexed by that id holds the count -- so the per-word
# bookkeeping is an integer-indexed array rather than a string-keyed hash, and the
# id<->word mapping is shareable across processes.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Intern::Shared;

my $in = Data::Intern::Shared->new(undef, 100_000, 4 << 20);
my @count;

my $text = <<'TXT';
the quick brown fox the lazy dog the fox jumps the dog sleeps
the quick fox the brown dog the lazy fox the quick brown dog
TXT

$count[ $in->intern($_) // die "intern: table full\n" ]++ for split ' ', lc $text;

printf "%d distinct words in %d arena bytes\n", $in->count, $in->arena_used;
my @top = sort { $count[$b] <=> $count[$a] } 0 .. $in->count - 1;
printf "  %-7s %d\n", $in->string($_), $count[$_] for @top[0 .. 4];
