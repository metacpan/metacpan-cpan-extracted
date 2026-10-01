use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::Heap::Shared;

# A holder killed mid-sift must leave a heap the next locker repairs.  gdb
# single-steps one pop and one push through this module's code, copying the
# backing file at every state change; each copy is then opened (which recovers
# the dead holder's lock) and drained.  Every copy must drain sorted, holding
# either the old or the new contents -- nothing lost, nothing twice.

my $gdb = `command -v gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'heap.h' && -d 'blib';
my $probe = `$gdb -batch -ex 'python print(6*7)' -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb without python' unless $probe =~ /^42$/m;
plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;

my $dir = tempdir(CLEANUP => 1);
my $CAP = 32;

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings;
use Data::Heap::Shared;
my ($path, $cap, $op, @arg) = @ARGV;
my $h = Data::Heap::Shared->new($path, $cap);
$op eq 'pop' ? $h->pop : $h->push(@arg);
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

sub val { $_[0] * 1000 + 7 }

sub snapshots {
    my ($name, $xs, $op, @arg) = @_;
    my $file = "$dir/$name.heap";
    my $snaps = "$dir/$name.snap";
    mkdir $snaps or die $!;
    local @ENV{qw(SK_XS SK_FILE SK_SNAPS)} = ($xs, $file, $snaps);
    my $log = `ulimit -v 1500000; timeout 600 $gdb -batch -x $dir/step.py --args $^X -Iblib/lib -Iblib/arch $dir/victim.pl $file $CAP $op @arg 2>&1`;
    like $log, qr/Breakpoint 1, .*\n(?s:.*)stepped \d+/, "$name: gdb stepped $xs" or diag $log;
    opendir my $d, $snaps or die $!;
    return map { "$snaps/$_" } sort grep { /^s\./ } readdir $d;
}

sub drain {
    my ($snap) = @_;
    my $h = Data::Heap::Shared->new($snap, $CAP);
    my @out;
    while (my ($p, $v) = $h->pop) {
        push @out, $v == val($p) ? $p : "bad($p,$v)";
        last if @out > $CAP;
    }
    return join ',', @out;
}

sub check {
    my ($name, $snaps, $before, $after) = @_;
    my @snaps = @$snaps;
    my %want = map { (join(',', @$_), 1) } $before, $after;
    my $held = 0;
    for my $s (@snaps) {
        open my $f, '<:raw', $s or die $!;
        read $f, my $hdr, 128;
        $held++ if unpack('x68 V', $hdr);
    }
    # The drains wait out the dead holder's 2 s lock timeout, so run them side by side.
    while (my @batch = splice @snaps, 0, 16) {
        my @kids;
        for my $s (@batch) {
            my $pid = fork // die $!;
            if (!$pid) {
                my $r = eval { drain($s) } // "died: $@";
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
        push @bad, "$s: $r" unless $want{$r};
    }
    open my $fin, '<', "$snaps->[-1].out" or die $!;
    is scalar(<$fin>), join(',', @$after), "$name: the op itself completed";
    cmp_ok $held, '>=', 4, "$name: captured states with the lock held ($held of " . @$snaps . ')';
    ok !@bad, "$name: every killed state recovers to the old or the new heap"
        or diag join "\n", grep defined, @bad[0 .. 9];
}

sub seed {
    my ($name, @p) = @_;
    my $h = Data::Heap::Shared->new("$dir/$name.heap", $CAP);
    $h->push($_, val($_)) for @p;
}

seed('pop', 1 .. 31);
check('pop', [snapshots('pop', 'XS_Data__Heap__Shared_pop', 'pop')], [1 .. 31], [2 .. 31]);

seed('push', 1 .. 30);
check('push', [snapshots('push', 'XS_Data__Heap__Shared_push', 'push', 0, val(0))], [1 .. 30], [0 .. 30]);

done_testing;
