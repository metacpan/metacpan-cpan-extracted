use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# tombstone_at must retire the slot before releasing the entry's arena blocks:
# in the other order a writer killed in that window leaves states[idx] live
# while the key's block is on the free list, whose push overwrites its first 4
# bytes, so the key reads back mangled and the entry is unreachable. Both orders
# reach the same final state, so only a crash mid-call tells them apart: gdb
# stops the process on the line publishing the tombstone and SIGKILLs it.
# Asserted: every key the cursor yields round-trips through exists().

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'Makefile.PL';

# Anchor on the statement itself, not a line number.
my $line;
{
    open my $fh, '<', 'shm_generic.h' or die $!;
    my $in_fn = 0;
    while (<$fh>) {
        $in_fn = 1 if /^static void SHM_FN\(tombstone_at\)/;
        if ($in_fn && /^\s*h->states\[idx\] = SHM_TOMBSTONE;/) { $line = $.; last }
    }
    close $fh;
}
ok($line, "located the tombstone publish in shm_generic.h (line $line)")
    or BAIL_OUT('cannot anchor the breakpoint');

# Restore the default build even if we die partway: a stale -O0 tree would
# persist silently, since a later bare `make` sees the objects as up to date.
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

my $dir = tempdir(CLEANUP => 1);
my $map = "$dir/ordering.hm";
my @keys = map { "ordering-key-longer-than-inline-slot-$_" } 1 .. 3;

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings;
use Data::HashMap::Shared::SI;
my ($path, @keys) = @ARGV;
my $m = Data::HashMap::Shared::SI->new($path, 1024);
$m->put($_, 42) for @keys;
$m->remove($keys[2]);   # seed the free list so the next push writes a real head
$m->remove($keys[1]);   # gdb kills us inside this one
VEOF
close $v;

my $cmds = "$dir/gdb.cmds";
open my $c, '>', $cmds or die $!;
print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
         "break shm_generic.h:$line\nignore 1 1\nrun\nkill\nquit\n";
close $c;

my $log = "$dir/gdb.log";
system("$gdb -batch -x $cmds --args $^X -Iblib/lib -Iblib/arch $victim $map @keys > $log 2>&1");
my $gdblog = do { local $/; open my $l, '<', $log or die $!; <$l> };

# Positive control: without a bound-and-hit breakpoint the victim runs to
# completion and the invariant below would pass vacuously.
like $gdblog, qr/Breakpoint 1[.,]/, 'gdb bound and hit the breakpoint'
    or diag $gdblog;

my $out = `$^X -Iblib/lib -Iblib/arch -MData::HashMap::Shared::SI -e '
    my \$m = Data::HashMap::Shared::SI->new(q{$map}, 1024);
    my \$c = \$m->cursor; my \$bad = 0; my \$n = 0;
    while (my (\$k, \$v) = \$c->next) { \$n++; \$bad++ unless \$m->exists(\$k) }
    print "n=\$n bad=\$bad\n";
' 2>&1`;

like $out, qr/^n=\d+ bad=0$/m, 'no live entry left holding a freed (clobbered) key'
    or diag "cursor walk after mid-remove SIGKILL: $out";

diag 'restoring the default build (END block)...';
done_testing;
