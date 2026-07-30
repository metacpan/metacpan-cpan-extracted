use strict; use warnings; use Test::More; use Config; use POSIX (); use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

# F1: rebuild-over-a-mapped-file must be atomic (temp file + rename), never an
# in-place O_TRUNC rewrite of the very inode a reader has mmap'd. A process that
# has load()ed an image keeps the OLD inode alive (open fd + mapping); rebuilding
# the same path must leave that reader seeing the OLD data, not crash it with
# SIGBUS (which is what O_TRUNC on a mapped file does) and not silently show it
# the NEW file's bytes. This runs under xt/asan.t too (it globs t/*.t).
#
# The post-rebuild query is isolated in a forked child: a SIGBUS is a signal,
# not a Perl exception eval{} can trap, so we inspect how the child died. Same
# fork / POSIX::_exit / ($? & 127) pattern as t/02_corrupt.t.
plan skip_all => 'fork required' unless $Config{d_fork};

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/rebuild.phs";

# 1. build the OLD image ([1..200]) and load (mmap) it.
Data::PerfectHash::Shared->build_int($path, [1 .. 200]);
my $set = Data::PerfectHash::Shared->load($path);
ok  $set->has(50),   'sanity: old member 50 present before rebuild';
ok !$set->has(1000), 'sanity: 1000 absent before rebuild';

# 2. REBUILD the same path with a DISJOINT key set ([1000..1200]). With the
#    atomic temp+rename build this creates a NEW inode and renames it over
#    $path; the OLD inode stays alive for the already-loaded $set. With the old
#    O_TRUNC write it would truncate/rewrite the inode $set has mapped.
Data::PerfectHash::Shared->build_int($path, [1000 .. 1200]);

# 3. query the OLD mapping in a child; it MUST still answer from the OLD data.
my $rf  = "$dir/result";
my $kid = fork;
plan skip_all => "fork failed: $!" unless defined $kid;
if (!$kid) {
    my $old = $set->has(50)   ? 1 : 0;   # old member -> must stay 1
    my $new = $set->has(1000) ? 1 : 0;   # new-file key -> must stay 0 via old inode
    if (open my $w, '>', $rf) { print $w "$old,$new"; close $w }
    POSIX::_exit(0);   # skip END/DESTROY: don't unmap/touch the parent's view
}
waitpid $kid, 0;
my $sig = $? & 127;
ok $sig == 0, "old mapping queried after rebuild does not crash (signal=$sig)"
    or diag "child terminated by signal $sig (raw \$?=$?) -- O_TRUNC would SIGBUS here";

SKIP: {
    skip 'child crashed before writing result', 2 unless $sig == 0 && -e $rf;
    open my $r, '<', $rf or skip "cannot read result: $!", 2;
    my ($old, $new) = split /,/, scalar(<$r>); close $r;
    ok  $old, 'old member has(50) still true via the old mapping (temp+rename kept the old inode)';
    ok !$new, 'new-file key has(1000) still false via the old mapping (never saw the new file)';
}

# 4. a FRESH load of $path sees the NEW data -- the rename did take effect.
{
    my $fresh = Data::PerfectHash::Shared->load($path);
    ok  $fresh->has(1000), 'a fresh load sees the new key set';
    ok !$fresh->has(50),   'a fresh load no longer has the old keys';
}

done_testing;
