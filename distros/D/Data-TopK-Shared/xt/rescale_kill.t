use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::TopK::Shared;

# A decayed-mode add that crosses the rescale point rescales every counter.
# gdb single-steps it through this module's code, copying the backing file at
# every state change; each copy is then opened and read (which recovers the dead
# writer's lock), and its min-heap checked: a rescale killed part-way must be
# finished, not leave counters on two scales.

my $gdb = `command -v gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'topk.h' && -d 'blib';
my $probe = `$gdb -batch -ex 'python print(6*7)' -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb without python' unless $probe =~ /^42$/m;
plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;

my $dir = tempdir(CLEANUP => 1);
my ($CAP, $KS) = (15, 8);

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings;
use Data::TopK::Shared;
my ($path, $cap, $ks, $key) = @ARGV;
Data::TopK::Shared->new($path, $cap, $ks)->add($key, 49.2);
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
    my ($name, $key) = @_;
    my $file = "$dir/$name.tk";
    my $snaps = "$dir/$name.snap";
    mkdir $snaps or die $!;
    local @ENV{qw(SK_XS SK_FILE SK_SNAPS)} = ('XS_Data__TopK__Shared_add', $file, $snaps);
    my $log = `ulimit -v 1500000; timeout 600 $gdb -batch -x $dir/step.py --args $^X -Iblib/lib -Iblib/arch $dir/victim.pl $file $CAP $KS $key 2>&1`;
    like $log, qr/Breakpoint 1, .*\n(?s:.*)stepped \d+/, "$name: gdb stepped add" or diag $log;
    opendir my $d, $snaps or die $!;
    return map { "$snaps/$_" } sort grep { /^s\./ } readdir $d;
}

sub raw { open my $f, '<:raw', $_[0] or die $!; local $/; <$f> }

sub heap_state {
    my ($buf) = @_;
    my ($cap, $ks) = unpack 'x8 V V', $buf;
    my ($used, $slots_off) = unpack 'x24 Q< x8 Q<', $buf;
    my $heap_off = unpack 'x64 Q<', $buf;
    my $jsift = unpack 'x108 V', $buf;
    my $stride = 32 + (($ks + 7) & ~7);
    my @heap = unpack "x$heap_off V$used", $buf;
    my (@count, @pos);
    for my $s (0 .. $cap - 1) {
        ($count[$s], $pos[$s]) = unpack 'x' . ($slots_off + $s * $stride) . ' Q< x8 V', $buf;
    }
    return ($used, $jsift, \@heap, \@count, \@pos);
}

sub verify {
    my ($snap) = @_;
    my $tk = Data::TopK::Shared->new($snap, $CAP, $KS);
    my @top = $tk->top;
    my ($used, $jsift, $heap, $count, $pos) = heap_state(raw($snap));
    my @err;
    push @err, "journal left set ($jsift)" if $jsift;
    my %seen;
    for my $i (0 .. $used - 1) {
        my $s = $heap->[$i];
        push @err, "heap[$i]=$s out of range" and next if $s >= $used;
        push @err, "slot $s twice" if $seen{$s}++;
        push @err, "slot $s heap_pos $pos->[$s] != $i" if $pos->[$s] != $i;
        push @err, "heap order broken at $i" if $i && $count->[$heap->[($i - 1) >> 1]] > $count->[$s];
    }
    push @err, 'top() lost a key' if @top != $used;
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

# half-life 1 at t=49: the victim's add at t=49.2 crosses the rescale point
{
    my $tk = Data::TopK::Shared->new_decayed("$dir/rescale.tk", $CAP, $KS, 1);
    for my $r (1 .. 3) { for my $k (1 .. $CAP) { $tk->add("k$k", 49) for 1 .. ($k % 4) + 1 } }
}
my @s = snapshots('rescale', 'fresh');
check('rescale', \@s);
done_testing;
