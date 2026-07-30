use strict; use warnings; use Test::More; use File::Temp 'tempdir';
use Data::PerfectHash::Shared;
my $dir=tempdir(CLEANUP=>1); my $p="$dir/s.phs";
my @w = map { "key-$_-" . ("x" x ($_ % 17)) } 0..2000;   # varied lengths
push @w, "has\0nul";                                     # embedded NUL
Data::PerfectHash::Shared->build_str($p, \@w);
my $set = Data::PerfectHash::Shared->load($p);
is $set->type, 'str', 'type';
my $ok=0; $ok += $set->has($_) for @w; is $ok, scalar(@w), 'all str members present';
ok !$set->has('key-0-NOPE'), 'non-member absent';
ok $set->has("has\0nul"), 'embedded NUL member present';

my %seen; $set->each_key(sub { $seen{$_[0]}++ });
is scalar(keys %seen), scalar(@w), 'each_key visits every str key exactly once';
is_deeply [sort keys %seen], [sort @w], 'each_key keys match the input set exactly';

done_testing;
