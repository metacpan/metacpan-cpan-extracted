#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::CountMinSketch::Shared;

# Word-frequency estimation over a stream with a Count-Min sketch. We count
# every word into a tiny fixed-size sketch (no per-word hash entry), then ask
# it for the estimated frequency of each distinct word and print the top few.
# The estimate never undercounts and overcounts only by a small bounded amount.

my $text = <<'END';
the quick brown fox jumps over the lazy dog
the dog barks and the fox runs the fox is quick
the lazy dog sleeps while the quick fox jumps again
the fox the fox the fox over and over the dog
END

my @words = split /\s+/, lc $text;

my $cms = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
$cms->add($_) for @words;

# Distinct words, ranked by their estimated frequency (then alphabetically).
my %seen;
my @distinct = grep { !$seen{$_}++ } @words;
my @ranked = sort { $cms->estimate($b) <=> $cms->estimate($a) or $a cmp $b } @distinct;

printf "stream of %d words, %d distinct\n\n", scalar(@words), scalar(@distinct);
print "top words by estimated frequency:\n";
for my $w (@ranked[0 .. ($#ranked < 6 ? $#ranked : 6)]) {
    printf "  %-8s %d\n", $w, $cms->estimate($w);
}

my $st = $cms->stats;
printf "\nsketch: width %d, depth %d, %d cells, total %d, memory %d bytes\n",
    @{$st}{qw(width depth cells total mmap_size)};
printf "guarantee: overestimate <= %.4g * total ~ %.2f, with prob >= %.4g\n",
    $st->{epsilon}, $st->{epsilon} * $st->{total}, 1 - $st->{delta};
