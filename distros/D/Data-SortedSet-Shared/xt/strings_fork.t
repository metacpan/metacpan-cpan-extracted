use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
BEGIN {
    plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
    eval { require Data::Intern::Shared; 1 }
        or plan skip_all => 'Data::Intern::Shared is required for string-keyed sets';
}
use Data::SortedSet::Shared::Strings;

# Both backing stores are anonymous MAP_SHARED, inherited across fork; children
# add string-keyed scores concurrently and the parent resolves every key. This
# is the cross-process string<->id agreement the wrapper exists for.
my $z = Data::SortedSet::Shared::Strings->new(max => 100_000, max_keys => 100_000, arena => 8 << 20);
my @pids;
for my $k (0 .. 3) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $z->add("p$k-$_", $k * 1000 + $_) for 1 .. 500;   # disjoint key ranges
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $z->count, 4 * 500, 'all child string-keyed adds visible to parent';
ok $z->exists("p2-250"), 'a specific child key is resolvable by string in the parent';
is $z->score("p3-1"), 3001, 'cross-process score by string key';
ok !defined($z->score("never-added")), 'absent key resolves to undef';

my @each;
$z->each(sub { push @each, $_[0] });
is scalar(@each), $z->count, 'each() decodes every id back to its string';
my $rank_ok = 1;
for my $i (0 .. $#each) { $rank_ok = 0, last unless $z->rank($each[$i]) == $i }
ok $rank_ok, 'ranks consistent after concurrent multi-process adds';
my %u = map { $_ => 1 } @each;
is scalar(keys %u), scalar(@each), 'every member key is distinct (no double-intern under contention)';

done_testing;
