use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep time);

# flush_deferred must re-test the seal under the write lock: testing it first
# lets a call parked on that lock resize a map freeze() sealed meanwhile, and a
# sealed file is served by new_readonly with no lock at all precisely because it
# cannot change.  It is reachable without writing -- an exhausted each(), a
# cursor reset or destroyed (including at process exit), a sharded cursor
# advancing -- so "quiesce your writers" does not cover it.
#
# The window is two adjacent statements, so only stopping the process inside it
# tells the orderings apart: gdb parks the victim on the lock, this process
# freezes, then the victim is released.  The invariant asserted is the one the
# bug breaks: the sealed table's capacity must not change afterwards.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'Makefile.PL';

# Anchor on the statement, not a line number: the fix itself moves the line.
my $line;
{
    open my $fh, '<', 'shm_generic.h' or die $!;
    my $in_fn = 0;
    while (<$fh>) {
        $in_fn = 1 if /^static inline void SHM_FN\(flush_deferred\)/;
        if ($in_fn && /^\s*shm_rwlock_wrlock\(h\);/) { $line = $.; last }
    }
    close $fh;
}
ok($line, "located flush_deferred's write lock in shm_generic.h (line $line)")
    or BAIL_OUT('cannot anchor the breakpoint');

my $restore = 0;
END {
    if ($restore) {
        `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make 2>&1`;
        warn "the plain rebuild failed: blib still holds the debug build\n" if $?;
    }
}

my $build = `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make OPTIMIZE='-g3 -O0' 2>&1`;
$restore = 1;
is $?, 0, 'debug build succeeded'
    or BAIL_OUT("debug build failed:\n$build");

my $dir  = tempdir(CLEANUP => 1);
my $map  = "$dir/seal.hm";
my ($ready, $go) = ("$dir/ready", "$dir/go");

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings;
use Data::HashMap::Shared::II;
my $m = Data::HashMap::Shared::II->new($ARGV[0], 1000);
# Removing during each() defers the shrink; exhausting the loop flushes it.
my $n = 0;
while (my ($k, $v) = $m->each) { $m->remove($k) if ++$n <= 90 }
VEOF
close $v;

require Data::HashMap::Shared::II;
my $seed = Data::HashMap::Shared::II->new($map, 1000);
$seed->put($_, $_) for 1 .. 100;
my $cap_seeded = $seed->capacity;
undef $seed;

my $log = "$dir/gdb.log";
my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDOUT, '>', $log; open STDERR, '>&', \*STDOUT;
    exec $gdb, '-batch', '-nx',
        '-ex', 'set pagination off', '-ex', 'set confirm off',
        '-ex', 'set breakpoint pending on',
        '-ex', "break shm_generic.h:$line",
        '-ex', 'run',
        '-ex', "shell touch $ready; while [ ! -f $go ]; do sleep 0.05; done",
        '-ex', 'continue',
        '--args', $^X, '-Iblib/lib', '-Iblib/arch', $victim, $map;
    die;
}

my $deadline = time + 60;
sleep 0.1 until -e $ready or time > $deadline;
unless (-e $ready) {
    kill 'KILL', $pid; waitpid $pid, 0;
    my $out = do { local $/; open my $l, '<', $log or die $!; <$l> };
    BAIL_OUT("victim never reached flush_deferred's lock:\n$out");
}

my $f = Data::HashMap::Shared::II->new($map, 1000);
# Control: the deferred resize must still be pending, or the test proves nothing.
is $f->capacity, $cap_seeded, 'control: table not yet resized when freeze runs';

$f->freeze;
my $ro = Data::HashMap::Shared::II->new_readonly($map);
my $cap_sealed = $ro->capacity;

open my $g, '>', $go or die $!; close $g;
waitpid $pid, 0;

my $gdblog = do { local $/; open my $l, '<', $log or die $!; <$l> };
like $gdblog, qr/Breakpoint 1[.,]/, 'gdb bound and hit the breakpoint'
    or diag $gdblog;

is $ro->capacity, $cap_sealed, 'sealed table was not resized by the deferred flush'
    or diag "capacity went $cap_sealed -> " . $ro->capacity . " after the seal";

diag 'restoring the default build (END block)...';
done_testing;
