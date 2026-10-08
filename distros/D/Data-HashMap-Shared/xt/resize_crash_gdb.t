use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Config;

# Kill the resizing writer with gdb at points of its loops and header-record
# stores (and the process finishing it too), then check the next process sees
# every entry with its value, TTL and LRU position.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'MANIFEST';
my $probe = `$gdb -batch -ex run --args /bin/true 2>&1`;
plan skip_all => 'gdb cannot run a process here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my $src = do { open my $f, '<', 'shm_generic.h' or die $!; [<$f>] };
sub anchor {                      # line of the first $re after the line matching $fn
    my ($fn, $re, $off) = @_;
    my $in = 0;
    for my $i (0 .. $#$src) {
        $in ||= $src->[$i] =~ $fn;
        return $i + 1 + ($off // 0) if $in && $src->[$i] =~ $re;
    }
    return;
}

my $RESIZE = qr/^static int SHM_FN\(resize\)/;
my $RUN    = qr/^static void SHM_FN\(rz_run\)\(ShmHandle \*h\) \{/;
my $MOVE   = qr/^void SHM_FN\(rz_move\)/;
my $SETTLE = qr/^void SHM_FN\(rz_settle\)/;
my $PLACE  = qr/^static int SHM_FN\(rz_place\)/;
my $PHASE  = qr/uint8_t phase = __atomic_load_n\(&hdr->rz_phase/;
my @loop = (0, 9, 60, 250);
# [label, function, line, offset, hits to skip or % of the table, watched state byte]
my @anchors = map { [ $_->[0], scalar anchor(@$_[1 .. 3]), @$_[4, 5] ] } (
    [ 'record payload',       $RESIZE, qr/hdr->rz_seq = __atomic_load_n/,          0, [0] ],
    [ 'phase set',            $RESIZE, qr/rz_phase, SHM_RZ_CLEAN,/,                0, [0] ],
    [ 'clean pass',           $RUN,    $PHASE,                                        0, [10, 50, 90], '== 1' ],
    [ 'clean done',           $RUN,    qr/phase = SHM_RZ_MARK/,                     0, [0] ],
    [ 'mark pass',            $RUN,    $PHASE,                                        0, [10, 50, 90], '>= 2' ],
    [ 'mark done',            $RUN,    qr/rz_phase, SHM_RZ_PLACE,/,                 0, [0] ],
    [ 'move record',          $MOVE,   qr/nodes\[dst\] = nodes\[src\];/,            0, \@loop ],
    [ 'move commit',          $MOVE,   qr/shm_publish_tag\(h->states, dst, st\);/,  0, \@loop ],
    [ 'relink',               $SETTLE, qr/h->lru_next\[p\] = dst;/,                 0, \@loop ],
    [ 'free source',          $SETTLE, qr/h->states\[src\] = SHM_EMPTY;/,           0, \@loop ],
    [ 'source cleared',       $SETTLE, qr/h->expires_at\[src\] = 0;/,               0, [0, 60] ],
    [ 'park',                 $PLACE,  qr/SHM_FN\(rz_move\)\(h, t, e, SHM_MOVE\);/, 0, [0, 1, 2] ],
    [ 'parked, not placed',   $PLACE,  qr/SHM_FN\(rz_move\)\(h, t, e, SHM_MOVE\);/, 1, [0, 1, 2] ],
    [ 'cursor',               $RUN,    qr/rz_cursor, i \+ 1,/,                      0, [0, 60] ],
    [ 'table_cap',            $RUN,    qr/&hdr->table_cap, new_cap,/,               0, [0] ],
    [ 'phase clear',          $RUN,    qr/hdr->table_gen\+\+;/,                     1, [0] ],
);
my @lost = map { $_->[0] } grep { !defined $_->[1] } @anchors;
ok !@lost, 'located every resize breakpoint: ' . join ', ', map { "$_->[0]=" . ($_->[1] // '?') } @anchors
    or BAIL_OUT("no line in shm_generic.h for: @lost");

# A debug build in a scratch copy, so blib is left alone.
my $dir = tempdir(CLEANUP => 1);
my $bld = "$dir/build";
{
    open my $m, '<', 'MANIFEST' or die $!;
    while (<$m>) {
        my ($f) = split ' ';
        next unless defined $f && -f $f && $f !~ m{^(t|xt|eg|bench)/};
        make_path(dirname("$bld/$f"));
        copy($f, "$bld/$f") or die "copy $f: $!";
    }
}
my $out = `cd $bld && $^X Makefile.PL 2>&1 && make OPTIMIZE='-O2 -g' 2>&1`;
is $?, 0, '-O2 -g build' or BAIL_OUT("build failed:\n$out");
my @inc = ("-I$bld/blib/lib", "-I$bld/blib/arch");

# Keys homed at the last three of 2048 slots overflow and wrap to slot 0, so a
# resize reaches them before their new home is placed and must park what holds
# it; the first three keys hold 1021-1023, where the shrink folds those homes.
my $wrapkeys = "$dir/wrapkeys";
{
    open my $h, '>', "$dir/wrap.c" or die $!;
    print $h <<'C';
#define XXH_INLINE_ALL
#include "xxhash.h"
#include <stdio.h>
static unsigned key(unsigned mask, unsigned home, unsigned from) {
    char k[32];
    for (unsigned i = from;; i++) {
        int n = snprintf(k, sizeof k, "wrap%u_%u", home, i);
        if (((unsigned)XXH3_64bits(k, (size_t)n) & mask) == home) { puts(k); return i + 1; }
    }
}
int main(void) {
    unsigned from[3] = { 0, 0, 0 };
    for (unsigned h = 1021; h <= 1023; h++) key(2047, h, 0);
    for (int r = 0; r < 3; r++)
        for (unsigned h = 2045; h <= 2047; h++) from[h - 2045] = key(4095, h, from[h - 2045]);
    return 0;
}
C
    close $h;
    my $o = `$Config{cc} -O1 -I$bld -o $dir/wrap $dir/wrap.c 2>&1 && $dir/wrap > $wrapkeys`;
    is $?, 0, 'wrap-key generator' or BAIL_OUT("wrap-key generator failed:\n$o");
}
$ENV{HMS_WRAP_KEYS} = $wrapkeys;

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'EOF';
use strict; use warnings;
my ($path, $scen, $manifest) = @ARGV;
my $cls = $scen =~ /^ii/ ? 'II' : 'SS';
eval "require Data::HashMap::Shared::$cls; 1" or die $@;
my $max = $scen =~ /compact/ ? 1500 : 8000;
my $m = "Data::HashMap::Shared::$cls"->new($path, $max, $cls eq 'SS' ? $max : 0, 3600);
my $n = $scen =~ /compact/ ? 1500 : 1000;
my $key = $cls eq 'SS' ? sub { "key$_[0]" . ('k' x ($_[0] % 9)) } : sub { $_[0] * 7919 };
my $val = $cls eq 'SS' ? sub { "val$_[0]" . ('v' x ($_[0] % 23)) } : sub { $_[0] * 31 - 5 };
my (%gone, $last);
$m->put_ttl($key->($_), $val->($_), 1000 + $_ % 700) or die "put $_" for 0 .. $n - 1;
my @wrap;
if ($scen =~ /wrap/) {
    open my $w, '<', $ENV{HMS_WRAP_KEYS} or die $!;
    chomp(@wrap = <$w>);
    $m->put_ttl($_, "w$_", 1500) or die "put $_" for @wrap;
}
if ($scen =~ /shrink/) {                # the last remove shrinks 2048 -> 1024
    for my $i ((grep { $_ % 2 } 0 .. $n - 1), (grep { !($_ % 2) } 0 .. $n - 1)) {
        if ($m->size <= 512) { $gone{$last = $i} = 1; last }
        $m->remove($key->($i)); $gone{$i} = 1;
    }
} elsif ($scen =~ /compact/) {          # at max capacity; the next put compacts
    for my $i (0 .. 519) { $m->remove($key->($i * 2)); $gone{$i * 2} = 1 }
} else {                                # tombstones for the grow to clear
    for my $i (grep { $_ % 7 == 3 } 0 .. $n - 1) { $m->remove($key->($i)); $gone{$i} = 1 }
}
open my $f, '>', $manifest or die $!;
printf $f "%s\t%s\t%d\t%d\n", $key->($_), $val->($_), 1000 + $_ % 700, time
    for grep { !$gone{$_} } 0 .. $n - 1;
printf $f "%s\t%s\t%d\t%d\n", $_, "w$_", 1500, time for @wrap;
close $f;
my $ppid = getppid();                   # gdb arms the breakpoint here
if    ($scen =~ /grow/)   { $m->reserve(3000) or die 'reserve' }
elsif ($scen =~ /shrink/) { $m->remove($key->($last)) or die 'remove' }
else                      { $m->put_ttl($key->(99999), $val->(99999), 1000 + 99999 % 700) }
EOF
close $v;

my $check = "$dir/check.pl";
open my $c, '>', $check or die $!;
print $c <<'EOF';
use strict; use warnings;
my ($path, $scen, $manifest, $recover) = @ARGV;
my $cls = $scen =~ /^ii/ ? 'II' : 'SS';
eval "require Data::HashMap::Shared::$cls; 1" or die $@;
my $max = $scen =~ /compact/ ? 1500 : 8000;
my $m = "Data::HashMap::Shared::$cls"->new($path, $max, $cls eq 'SS' ? $max : 0, 3600);
if ($recover) { my $ppid = getppid(); my @k = $m->keys; exit 0 }
my (@want, %want);
open my $f, '<', $manifest or die $!;
while (<$f>) { chomp; my @r = split /\t/; push @want, $r[0]; $want{$r[0]} = \@r }
my ($missing, $badval, $badttl, $extra) = (0, 0, 0, 0);
my $opt = $cls eq 'SS' ? 'key99999' . ('k' x (99999 % 9)) : 99999 * 7919;
for my $k (@want) {
    my $v = $m->get($k);
    if (!defined $v) { $missing++; next }
    $badval++ if $v ne $want{$k}[1];
    my $r = $m->ttl_remaining($k);
    $badttl++ unless defined $r && $r <= $want{$k}[2] && $r >= $want{$k}[2] - (time - $want{$k}[3]) - 2;
}
my %have = map { $_ => 1 } $m->keys;
$extra = grep { !$want{$_} && $_ ne $opt } keys %have;
my $size = $m->size;
my $lru = 'n/a';
if ($cls eq 'SS') {                     # pop takes the LRU tail: insertion order
    my @order;
    while (my ($k) = $m->pop) { push @order, $k }
    pop @order if @order && $order[-1] eq $opt;
    $lru = "@order" eq "@want" ? 'ok' : 'bad';
}
printf "n=%d missing=%d badval=%d badttl=%d extra=%d size=%d lru=%s\n",
    scalar @want, $missing, $badval, $badttl, $extra, $size, $lru;
EOF
close $c;

# Run a script under gdb and kill it at the (p+1)th hit of a line or, for a
# vectorised pass no line breakpoint lands in, once the resize rewrites the first
# state byte matching $watch at p% of the old table.
sub gdb_run {
    my ($tag, $a, $p, @args) = @_;
    my (undef, $line, undef, $watch) = @$a;
    my $cmds = "$dir/$tag.gdb";
    open my $g, '>', $cmds or die $!;
    print $g "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "catch syscall getppid\nrun\ndelete 1\n",
             "break shm_generic.h:$line\n", (!$watch && $p ? "ignore 2 $p\n" : ''), "continue\n";
    print $g "delete 2\nset \$st = (unsigned char *) h->states\nset \$n = 1 << h->hdr->rz_old_log2\n",
             "set \$k = \$n * $p / 100\nwhile \$k < \$n && !(\$st[\$k] $watch)\nset \$k = \$k + 1\nend\n",
             "if \$k < \$n\nwatch -l \$st[\$k]\ncontinue\nend\n" if $watch;
    print $g "kill\nquit\n";
    close $g;
    my $log = `ulimit -v 1500000; $gdb -batch -x $cmds --args $^X @inc @args 2>&1`;
    return $log =~ ($watch ? qr/New value/ : qr/Breakpoint 2[,.]/) ? 1 : 0;
}
sub where { my ($a, $p) = @_; $a->[3] ? "$a->[0] at $p%" : "$a->[0] (line $a->[1], hit " . ($p + 1) . ')' }

sub state_of {
    my ($map, $scen, $man) = @_;
    my $s = `$^X @inc $check $map $scen $man 2>&1`;
    chomp $s;
    return $s;
}

sub intact {
    my ($s, $what) = @_;
    like $s, qr/^n=[1-9]\d* missing=0 badval=0 badttl=0 extra=0 size=\d+ lru=(ok|n\/a)$/, $what
        or diag $s;
    my ($n, $size) = $s =~ /^n=(\d+).*size=(\d+)/;
    ok defined $n && ($size == $n || $size == $n + 1), "  ... and size agrees ($what)";
}

my ($runs, $hits, %reached) = (0, 0);
for my $a (@anchors) {
    for my $scen (qw(grow shrink compact ii-grow ii-compact wrap-grow wrap-shrink)) {
        next if $scen =~ /^ii/ && $a->[0] =~ /relink/;
        next if $scen =~ /^wrap/ && $a->[0] !~ /park/;
        for my $p (@{ $a->[2] }) {
            my $tag = "r$runs"; $runs++;
            my ($map, $man) = ("$dir/$tag.shm", "$dir/$tag.man");
            my $hit = gdb_run($tag, $a, $p, $victim, $map, $scen, $man);
            $hits += $hit;
            $reached{$a->[0]}{$scen} ||= $hit;
            intact(state_of($map, $scen, $man),
                   "$scen, killed at " . where($a, $p) . ($hit ? '' : ', not reached'));
        }
    }
}

# A breakpoint no scenario reaches tests nothing, and its runs still pass.
ok scalar(grep { $_ } values %{ $reached{$_->[0]} }), "$_->[0] is reached by some scenario"
    for @anchors;
for my $name ('park', 'parked, not placed') {
    ok $reached{$name}{$_}, "$name is reached in $_" for qw(wrap-grow wrap-shrink);
}

# The process finishing a dead writer's resize dies too: the next one finishes it.
my %at = map { $_->[0] => $_ } @anchors;
if ($at{'free source'}) {
    for my $case (['free source', 60, 'free source', 20], ['mark pass', 50, 'mark pass', 90],
                  ['parked, not placed', 0, 'move commit', 0], ['clean pass', 50, 'move commit', 40]) {
        my ($a1, $p1, $a2, $p2) = ($at{$case->[0]}, $case->[1], $at{$case->[2]}, $case->[3]);
        my $both = 0;
        for my $scen ($case->[0] =~ /park/ ? qw(wrap-grow wrap-shrink) : qw(grow shrink compact)) {
            my $tag = "rr$runs"; $runs++;
            my ($map, $man) = ("$dir/$tag.shm", "$dir/$tag.man");
            my $h1 = gdb_run("$tag.a", $a1, $p1, $victim, $map, $scen, $man);
            my $h2 = gdb_run("$tag.b", $a2, $p2, $check, $map, $scen, $man, 1);
            $hits += $h1 && $h2;
            $both ||= $h1 && $h2;
            intact(state_of($map, $scen, $man),
                   "$scen, writer killed at " . where($a1, $p1) . ', recoverer at ' . where($a2, $p2)
                   . ($h1 && $h2 ? '' : ' (not both reached)'));
        }
        ok $both, "$case->[0], then the recoverer at $case->[2], is reached by some scenario";
    }
}
ok $hits, "gdb hit $hits of $runs breakpoints"
    or diag 'no breakpoint was reached: these runs proved nothing';
done_testing;
