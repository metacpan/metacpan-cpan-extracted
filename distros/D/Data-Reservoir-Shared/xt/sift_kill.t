use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::Reservoir::Shared;

# A writer killed mid-sift must leave a weighted heap the next locker repairs.
# gdb single-steps one weighted add through this module's code, copying the
# backing file at every state change; each copy is then opened and sampled
# (which recovers the dead writer's lock), and its A-Res min-heap checked: the
# entries index every kept cell exactly once and every parent's key is at most
# its children's.

my $gdb = `command -v gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'reservoir.h' && -d 'blib';
my $probe = `$gdb -batch -ex 'python print(6*7)' -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb without python' unless $probe =~ /^42$/m;
plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;

my $dir = tempdir(CLEANUP => 1);
my ($K, $IS) = (15, 8);

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings;
use Data::Reservoir::Shared;
my ($path, $k, $is, $item, $w) = @ARGV;
Data::Reservoir::Shared->new_weighted($path, $k, $is)->add($item, $w);
EOF
close $v;

# Steps into calls that stay inside the XS module and over everything else.
open my $py, '>', "$dir/step.py" or die $!;
print $py <<'EOF';
import gdb, os, re
xs, file, snaps = os.environ['SK_XS'], os.environ['SK_FILE'], os.environ['SK_SNAPS']
gdb.execute('set pagination off')
gdb.execute('set confirm off')
gdb.execute('set breakpoint pending on')
gdb.execute('break ' + xs)
gdb.execute('run')
pc = lambda: int(gdb.parse_and_eval('$pc'))
so = gdb.solib_name(pc())
last = open(file, 'rb').read()
n = 0
while n < 50000 and gdb.solib_name(pc()) == so:
    asm = gdb.selected_frame().architecture().disassemble(pc())[0]['asm']
    m = re.match(r'call\w*\s+(0x[0-9a-f]+)', asm)
    into = m and '@plt' not in asm and gdb.solib_name(int(m.group(1), 16)) == so
    gdb.execute('stepi' if into else 'nexti', to_string=True)
    cur = open(file, 'rb').read()
    if cur != last:
        open('%s/s.%05d' % (snaps, n), 'wb').write(cur)
        last = cur
    n += 1
print('stepped %d' % n)
gdb.execute('kill')
EOF
close $py;

sub snapshots {
    my ($name, $item, $w) = @_;
    my $file = "$dir/$name.rsv";
    my $snaps = "$dir/$name.snap";
    mkdir $snaps or die $!;
    local @ENV{qw(SK_XS SK_FILE SK_SNAPS)} = ('XS_Data__Reservoir__Shared_add', $file, $snaps);
    my $log = `ulimit -v 1500000; timeout 600 $gdb -batch -x $dir/step.py --args $^X -Iblib/lib -Iblib/arch $dir/victim.pl $file $K $IS $item $w 2>&1`;
    like $log, qr/Breakpoint 1, .*\n(?s:.*)stepped \d+/, "$name: gdb stepped add" or diag $log;
    opendir my $d, $snaps or die $!;
    return map { "$snaps/$_" } sort grep { /^s\./ } readdir $d;
}

sub raw { open my $f, '<:raw', $_[0] or die $!; local $/; <$f> }

sub verify {
    my ($snap) = @_;
    my $r = Data::Reservoir::Shared->new_weighted($snap, $K, $IS);
    my @sample = $r->sample;
    my $buf = raw($snap);
    my $k = unpack 'x16 Q<', $buf;
    my ($seen, undef, $heap_off, $jsift) = unpack 'x96 Q< Q< Q< V', $buf;
    my $n = $seen < $k ? $seen : $k;
    my @e = map { [unpack 'x' . ($heap_off + 16 * $_) . ' d< Q<', $buf] } 0 .. $n - 1;
    my (@err, %seen);
    push @err, "journal left set ($jsift)" if $jsift;
    for my $i (0 .. $n - 1) {
        my ($key, $cell) = @{ $e[$i] };
        push @err, "entry $i cell $cell out of range" if $cell >= $n;
        push @err, "cell $cell twice" if $seen{$cell}++;
        push @err, "heap order broken at $i" if $i && $e[($i - 1) >> 1][0] > $key;
    }
    push @err, 'sample() size ' . @sample . " != $n" if @sample != $n;
    return @err ? join('; ', @err) : 'ok';
}

sub check {
    my ($name, $snaps) = @_;
    my @snaps = @$snaps;
    my $held = grep { unpack('x72 V', raw($_)) } @snaps;
    while (my @batch = splice @snaps, 0, 8) {
        my @kids;
        for my $s (@batch) {
            my $pid = fork // die $!;
            if (!$pid) {
                my $r = eval { verify($s) } // "died: $@";
                open my $o, '>', "$s.out" or _exit(1);
                print $o $r; close $o;
                _exit(0);
            }
            push @kids, $pid;
        }
        waitpid $_, 0 for @kids;
    }
    my @bad;
    for my $s (@$snaps) {
        open my $o, '<', "$s.out" or do { push @bad, "$s: no result"; next };
        my $r = <$o> // '';
        push @bad, "$s: $r" unless $r eq 'ok';
    }
    cmp_ok $held, '>=', 4, "$name: captured states with the write lock held ($held of " . @$snaps . ')';
    ok !@bad, "$name: every killed state recovers to a consistent heap"
        or diag join "\n", grep defined, @bad[0 .. 9];
}

sub seed {
    my ($name, $n, $w) = @_;
    my $r = Data::Reservoir::Shared->new_weighted("$dir/$name.rsv", $K, $IS);
    $r->seed(42);
    $r->add("i$_", $w) for 1 .. $n;
}

sub kept { grep { $_ eq $_[1] } Data::Reservoir::Shared->new_weighted("$dir/$_[0].rsv", $K, $IS)->sample }

# Filling: a near-zero key rises from the last leaf to the root.
seed('fill', $K - 1, 1e9);
check('fill', [snapshots('fill', 'light', 1e-9)]);
ok kept('fill', 'light'), 'fill: the add kept its item';

# Eviction: a near-one key replaces the root and sinks to a leaf.
seed('evict', $K, 1);
check('evict', [snapshots('evict', 'heavy', 1e9)]);
ok kept('evict', 'heavy'), 'evict: the add kept its item';

done_testing;
