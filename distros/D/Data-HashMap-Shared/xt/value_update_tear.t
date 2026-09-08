use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# A string's (off, len_field) pair must never be observable as the new offset
# with the old length: the update path never touches states[idx], so the entry
# stays live and recovery cannot detect it, and a later shm_str_free would take
# the size class from the stale length and file the block on the wrong free
# list -- after which that class hands out an undersized block and the next
# value written overruns a neighbouring entry.
#
# Both stores go through an interim inline-empty state, which shm_str_free
# treats as a no-op, so every observable pair is fully-old, fully-new, or safe.
# Built at -O2 on purpose: the interim store is dead by ordinary dataflow and
# survives only because it is an __atomic_store_n.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'Makefile.PL';

my $line;
{
    open my $fh, '<', 'shm_generic.h' or die $!;
    my $in_fn = 0;
    while (<$fh>) {
        $in_fn = 1 if /^static inline int shm_str_store/;
        if ($in_fn && /SHM_PACK_LEN\(slen, utf8\)/) { $line = $.; last }
    }
    close $fh;
}
ok($line, "located the value publish in shm_str_store (line $line)")
    or BAIL_OUT('cannot anchor the breakpoint');

# Restore the default build even if we die partway.
my $restore = 0;
END {
    if ($restore) {
        `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make 2>&1`;
        warn "the plain rebuild failed: blib still holds the debug build\n" if $?;
    }
}

my $build = `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make OPTIMIZE='-O2 -g' 2>&1`;
$restore = 1;
is $?, 0, '-O2 -g build succeeded'
    or BAIL_OUT("build failed:\n$build");

my $dir = tempdir(CLEANUP => 1);
my $map = "$dir/tear.hm";

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings;
use Data::HashMap::Shared::IS;
my $m = Data::HashMap::Shared::IS->new($ARGV[0], 1024);
$m->put(1, 'A' x 100);   # target: 100-byte arena block
$m->put(2, 'C' x 100);   # canary in a neighbouring block
$m->put(1, 'B' x 32);    # in-place update into a SMALLER size class
VEOF
close $v;

my $cmds = "$dir/gdb.cmds";
open my $c, '>', $cmds or die $!;
print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
         "break shm_generic.h:$line\nignore 1 2\nrun\nkill\nquit\n";
close $c;

my $log = "$dir/gdb.log";
system("$gdb -batch -x $cmds --args $^X -Iblib/lib -Iblib/arch $victim $map > $log 2>&1");
my $gdblog = do { local $/; open my $l, '<', $log or die $!; <$l> };

# Positive control: an unbound breakpoint would let the victim finish and make
# the assertions below pass vacuously.
like $gdblog, qr/Breakpoint 1[.,]/, 'gdb bound and hit the breakpoint'
    or diag $gdblog;

my $out = `$^X -Iblib/lib -Iblib/arch -MData::HashMap::Shared::IS -e '
    my \$m = Data::HashMap::Shared::IS->new(q{$map}, 1024);
    my \$t = \$m->get(1); my \$c = \$m->get(2);
    printf "target_len=%d canary_ok=%d\n",
        (defined \$t ? length \$t : -1),
        ((defined \$c && \$c eq ("C" x 100)) ? 1 : 0);
' 2>&1`;

# Post-fix the interim state is inline-empty (length 0).  Pre-fix the node kept
# the stale 100-byte length while pointing at the new 32-byte block, so get()
# reads 100 bytes out of a 32-byte allocation -- i.e. a neighbour's bytes.
like $out, qr/target_len=0\b/, 'torn update left a self-consistent inline-empty value'
    or diag "after SIGKILL mid-update: $out";
like $out, qr/canary_ok=1/, 'neighbouring entry intact'
    or diag "after SIGKILL mid-update: $out";

diag 'restoring the default build (END block)...';
done_testing;
