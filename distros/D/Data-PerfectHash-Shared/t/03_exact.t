use strict; use warnings; use Test::More; use File::Temp 'tempdir';
use Data::PerfectHash::Shared;
my $dir = tempdir(CLEANUP=>1); my $p="$dir/e.phs";
my %in = map { ($_*2) => 1 } 0..4999;           # even numbers 0..9998
Data::PerfectHash::Shared->build_int($p, [keys %in]);
my $set = Data::PerfectHash::Shared->load($p);
my ($fp,$fn)=(0,0);
for my $k (0..20000) { my $h=$set->has($k); if ($in{$k}) { $fn++ unless $h } else { $fp++ if $h } }
is $fn, 0, 'no false negatives'; is $fp, 0, 'no false positives (exact)';
done_testing;
