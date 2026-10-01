use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Kill a writer running a random range_add / range_assign / add / set workload
# with gdb inside its push-downs and range walks -- and, in the last cases, the
# process repairing it too.  A range op may land on some positions and not
# others, but every position must hold its value from before or after the op in
# flight, and every range query must agree with the point values.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'segtree.h' && -f 'Makefile.PL';
my $probe = `ulimit -v 1500000; timeout 60 $gdb -nx -batch -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb cannot trace a child here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my $src = do { open my $f, '<', 'segtree.h' or die $!; [<$f>] };
sub anchor {                      # line of the first $re after the line matching $fn
    my ($fn, $re) = @_;
    my $in = 0;
    for my $i (0 .. $#$src) {
        $in ||= $src->[$i] =~ $fn;
        return "segtree.h:" . ($i + 1) if $in && $src->[$i] =~ $re;
    }
    return;
}

my $dir = tempdir(CLEANUP => 1);
my $bd = "$dir/build";
mkdir $bd or die $!;
system('cp', '-r', 'Makefile.PL', 'Shared.xs', glob('*.h'), 'lib', $bd) == 0 or die 'cp failed';
my $build = `cd $bd && $^X Makefile.PL 2>&1 && make OPTIMIZE='-O2 -g' 2>&1`;
is $?, 0, '-O2 -g build' or BAIL_OUT($build);
my @inc = ("-I$bd/blib/lib", "-I$bd/blib/arch");

my ($SEED, $OPS, $N) = (11, 600, 100);
open my $mf, '>', "$dir/model.pl" or die $!;
print $mf <<'EOF';
package M;
sub ops {
    my ($seed, $nops, $n) = @_;
    srand $seed;
    my @ops;
    for (1 .. $nops) {
        my $r = rand;
        my ($l, $h) = sort { $a <=> $b } int rand $n, int rand $n;
        my $d = (1 + int rand 50) * (rand() < 0.5 ? -1 : 1);
        push @ops, $r < 0.4 ? ['range_add', $l, $h, $d] : $r < 0.6 ? ['range_assign', $l, $h, int(rand 201) - 100]
                 : $r < 0.8 ? ['add', $l, $d] : ['set', $l, int(rand 201) - 100];
    }
    return \@ops;
}
sub values_after {
    my ($ops, $j, $n) = @_;
    my @v = (0) x $n;
    for my $o (@$ops[0 .. $j - 1]) {
        my ($op, @a) = @$o;
        if    ($op eq 'range_add')    { $v[$_] += $a[2] for $a[0] .. $a[1] }
        elsif ($op eq 'range_assign') { $v[$_]  = $a[2] for $a[0] .. $a[1] }
        elsif ($op eq 'add')          { $v[$a[0]] += $a[1] }
        else                          { $v[$a[0]]  = $a[1] }
    }
    return \@v;
}
1;
EOF
close $mf;

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings; use Data::SegmentTree::Shared;
my ($model, $path, $log, $seed, $nops, $n) = @ARGV;
do $model or die $@ || $!;
my $ops = M::ops($seed, $nops, $n);
my $t = Data::SegmentTree::Shared->new($path, $n);
open my $l, '+>', $log or die $!;
for my $k (0 .. $#$ops) {
    sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", $k;
    my ($op, @a) = @{ $ops->[$k] };
    $t->$op(@a);
}
sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", scalar @$ops;
EOF
close $v;

open my $c, '>', "$dir/check.pl" or die $!;
print $c <<'EOF';
use strict; use warnings; use Data::SegmentTree::Shared;
my ($model, $path, $log, $seed, $nops, $n, $recover) = @ARGV;
my $t = Data::SegmentTree::Shared->new($path, $n);
if ($recover) { $t->sum(0, 0); exit 0 }
do $model or die $@ || $!;
my $k = do { open my $f, '<', $log or die $!; 0 + <$f> };
my $ops = M::ops($seed, $nops, $n);
my ($pre, $post) = (M::values_after($ops, $k, $n), M::values_after($ops, $k + 1, $n));
my @p = map { $t->get($_) } 0 .. $n - 1;
my @off = grep { $p[$_] != $pre->[$_] && $p[$_] != $post->[$_] } 0 .. $n - 1;
my $bad = 0;
for my $l (0 .. $n - 1) {
    my ($s, $mn, $mx) = (0, $p[$l], $p[$l]);
    for my $r ($l .. $n - 1) {
        $s += $p[$r]; $mn = $p[$r] if $p[$r] < $mn; $mx = $p[$r] if $p[$r] > $mx;
        my $q = $t->query($l, $r);
        $bad++ if $q->{sum} != $s || $q->{min} != $mn || $q->{max} != $mx;
    }
}
printf "op=%d %s off=%d%s ranges_bad=%d\n", $k, $ops->[$k] ? $ops->[$k][0] : 'none', scalar @off,
    @off ? " (pos $off[0]: $p[$off[0]], want $pre->[$off[0]] or $post->[$off[0]])" : '', $bad;
EOF
close $c;

my %where;
sub gdb_run {
    my ($tag, $at, $skip, $steps, @args) = @_;
    my $cmds = "$dir/$tag.gdb";
    open my $g, '>', $cmds or die $!;
    print $g "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak $at\n", ($skip ? "ignore 1 $skip\n" : ''), "run\n",
             ($steps ? "stepi $steps\n" : ''), "bt 1\nkill\nquit\n";
    close $g;
    my $log = `ulimit -v 1500000; timeout 600 $gdb -nx -batch -x $cmds --args $^X @inc @args 2>&1`;
    return 0 unless $log =~ /Breakpoint 1[,.]/;
    $where{$1}++ if $log =~ /^#0\s+(?:0x\S+ in )?(\w+)/m;
    return 1;
}

my @args = ($SEED, $OPS, $N);
sub state_of {
    my ($path, $log) = @_;
    my $s = `timeout 300 $^X @inc $dir/check.pl $dir/model.pl $path $log @args 2>&1`;
    chomp $s;
    return $s;
}

my $PUSH = qr/^static inline void st_pushdown\(/;
my @steps = (0, 2, 5, 9, 14, 20, 30, 45);
# [label, location, calls to skip, instructions to step after the stop]
my @anchors = grep { defined $_->[1] } (
    [ 'push add',      anchor($PUSH, qr/st_apply_add\(&nodes\[2\*v\],/),    [0, 7, 40, 150], \@steps ],
    [ 'push assign',   anchor($PUSH, qr/st_apply_assign\(&nodes\[2\*v\],/), [0, 7, 40],      \@steps ],
    [ 'range add',     'st_range_add_rec',    [3, 300, 1500],  [1, 30, 90, 200, 400] ],
    [ 'range assign',  'st_range_assign_rec', [3, 300, 1500],  [1, 30, 90, 200, 400] ],
);
ok @anchors, 'located breakpoints: ' . join ', ', map { "$_->[0]=$_->[1]" } @anchors;

sub intact {
    my ($s, $what) = @_;
    like $s, qr/^op=\d+ \w+ off=0 ranges_bad=0$/, $what or diag $s;
}

my ($runs, $hits) = (0, 0);
for my $a (@anchors) {
    for my $skip (@{ $a->[2] }) {
        for my $steps (@{ $a->[3] }) {
            my $tag = 'r' . $runs++;
            my ($path, $log) = ("$dir/$tag.st", "$dir/$tag.log");
            my $hit = gdb_run($tag, $a->[1], $skip, $steps, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args);
            $hits += $hit;
            intact(state_of($path, $log), "$a->[0], call " . ($skip + 1) . " + $steps instructions"
                                          . ($hit ? '' : ', not reached'));
        }
    }
}

# The process repairing a dead writer's tree dies too: the next one repairs it.
my $replay = anchor(qr/^static void st_repair_locked\(StHandle \*h\) \{/, qr/nodes\[pv\]\.lazy = 0;/);
my $pull   = anchor(qr/^static void st_repair_locked\(StHandle \*h\) \{/, qr/st_pull\(nodes, v\);/);
my $push = (grep { $_->[0] eq 'push add' } @anchors)[0];
for my $r (grep { defined $_->[0] } [$replay, 0], [$pull, 0], [$pull, 40]) {
    for my $steps (9, 20) {
        my $tag = 'rr' . $runs++;
        my ($path, $log) = ("$dir/$tag.st", "$dir/$tag.log");
        my $h1 = gdb_run("$tag.a", $push->[1], 7, $steps, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args);
        my $h2 = gdb_run("$tag.b", $r->[0], $r->[1], 0, "$dir/check.pl", "$dir/model.pl", $path, $log, @args, 1);
        $hits += $h1 && $h2;
        intact(state_of($path, $log), "writer killed mid push-down (+$steps), repairer at $r->[0] call "
                                      . ($r->[1] + 1) . ($h1 && $h2 ? '' : ' (not both reached)'));
    }
}

ok $hits, "gdb hit $hits of $runs breakpoints" or diag 'no breakpoint was reached: these runs proved nothing';
note 'killed in: ' . join ', ', map { "$_=$where{$_}" } sort { $where{$b} <=> $where{$a} } keys %where;
done_testing;
