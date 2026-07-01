use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Intern::Shared;

# Children intern overlapping string sets into a fork-shared table; afterwards
# every process agrees on one id per string. Crucially, the write lock must make
# concurrent interning of the SAME new string assign exactly one id (no
# double-insert), so count == the number of distinct keys.
my $in = Data::Intern::Shared->new(undef, 100_000, 8 << 20);
my $NKIDS  = 4;
my $SHARED = 500;                    # shared key space -> heavy contention
my @pids;
for my $k (0 .. $NKIDS - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        srand($k * 131 + 1);
        $in->intern("key-" . int(rand($SHARED))) for 1 .. 5000;   # overlapping
        $in->intern("kid-$k-unique");                             # disjoint
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $rt = 1;
my $drawn = 0;
for my $i (0 .. $SHARED - 1) {
    my $id = $in->id_of("key-$i");
    next unless defined $id;
    $drawn++;
    $rt = 0, last unless $in->string($id) eq "key-$i";
}
ok $rt, 'every shared key round-trips (id -> string) after concurrent interning';
ok defined($in->id_of("kid-$_-unique")), "child $_ unique key visible to parent" for 0 .. $NKIDS - 1;

my $dense = 1;
for my $id (0 .. $in->count - 1) { $dense = 0, last unless defined $in->string($id) }
ok $dense, 'all ids 0..count-1 map to a string (dense, no gaps)';
is $in->count, $drawn + $NKIDS,
    'count == exactly the distinct keys (no double-insert of a string under contention)';

done_testing;
