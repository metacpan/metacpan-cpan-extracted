use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Compaction moves a live arena block and then rewrites the node offset that
# points at it.  Between those two the node still names the source, so the whole
# design rests on one rule: relocate only when the destination lies entirely
# below the source, and the copy can never touch the bytes the node is still
# reading.  Killing a compacting writer at random cannot test that -- the window
# between the copy and the store is nanoseconds wide -- so stop exactly there
# with a breakpoint and kill it, once for each of the first relocations.
#
# Break after the memcpy and before the store: at -O2 neither can move across
# the other, because both write memory the compiler cannot prove disjoint.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'Makefile.PL';

my $line;
{
    open my $fh, '<', 'shm_generic.h' or die $!;
    my $in_fn = 0;
    while (<$fh>) {
        $in_fn = 1 if /static uint64_t SHM_FN\(arena_compact\)/;
        if ($in_fn && /__atomic_store_n\(offp,/) { $line = $.; last }
    }
    close $fh;
}
ok $line, "located the offset publish in arena_compact (line $line)"
    or BAIL_OUT('cannot anchor the breakpoint');

my $restore = 0;
END {
    if ($restore) {
        `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make 2>&1`;
        warn "the plain rebuild failed: blib still holds the debug build\n" if $?;
    }
}
my $build = `make clean 2>/dev/null; $^X Makefile.PL 2>&1 && make OPTIMIZE='-O2 -g' 2>&1`;
$restore = 1;
is $?, 0, '-O2 -g build succeeded' or BAIL_OUT("build failed:\n$build");

my $dir = tempdir(CLEANUP => 1);

# The fixture has to force the case the rule exists for: a hole smaller than the
# block above it, so the destination would overlap the source.  Alternating
# like-sized entries does not -- every gap is then wider than the block that
# follows, the rule never bites, and a build without it behaves identically.
# A 32-byte hole under a 1024-byte block does.  Values are position-sensitive,
# so a copy that slid over itself cannot read back as the original.
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings;
use Data::HashMap::Shared::SS;
my $m = Data::HashMap::Shared::SS->new($ARGV[0], 8192, 0, 0, 0, 262144);
my $i = 0;
while ($m->arena_used + 4096 < $m->arena_cap) {
    last unless $m->put(sprintf('small%05d', $i), 'z' x 10);
    last unless $m->put(sprintf('large%05d', $i), sprintf('%09d', $i) x 100);
    $i++;
}
$m->remove(sprintf 'small%05d', $_) for 0 .. $i - 1;
$m->compact;
VEOF
close $v;

sub check {                       # every survivor must read back its own value
    my ($map) = @_;
    my $out = `$^X -Iblib/lib -Iblib/arch -MData::HashMap::Shared::SS -e '
        my \$m = Data::HashMap::Shared::SS->new(q{$map}, 8192, 0, 0, 0, 262144);
        my (\$bad, \$n) = (0, 0);
        for my \$k (\$m->keys) {
            \$n++;
            my (\$i) = \$k =~ /^large(\\d+)\$/ or do { \$bad++; next };
            \$bad++ if (\$m->get(\$k) // "") ne sprintf("%09d", \$i) x 100;
        }
        printf "n=%d bad=%d size=%d\n", \$n, \$bad, \$m->size;
    ' 2>&1`;
    chomp $out;
    return $out;
}

my $hit_any = 0;
for my $skip (0, 1, 2, 3, 7, 15, 31, 63, 127) {
    my $map  = "$dir/c$skip.shm";
    my $cmds = "$dir/gdb$skip.cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "break shm_generic.h:$line\n",
             ($skip ? "ignore 1 $skip\n" : ''),
             "run\nkill\nquit\n";
    close $c;
    my $log = "$dir/gdb$skip.log";
    system("$gdb -batch -x $cmds --args $^X -Iblib/lib -Iblib/arch $victim $map > $log 2>&1");
    my $gdblog = do { local $/; open my $l, '<', $log or die $!; <$l> };
    my $hit = $gdblog =~ /Breakpoint 1[.,]/;
    $hit_any ||= $hit;

    my $state = check($map);
    like $state, qr/\bbad=0\b/,
        "killed between the copy and the publish, relocation $skip: every entry intact"
        or diag "gdb: " . substr($gdblog, -400) . "\ncheck: $state";
    like $state, qr/\bn=[1-9]/, "  ... and the map still holds entries (relocation $skip)"
        or diag $state;
}
ok $hit_any, 'gdb bound and hit the breakpoint at least once'
    or diag 'the breakpoint never bound: these runs proved nothing';

diag 'restoring the default build (END block)...';
done_testing;
