use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Kill a writer running a random add / cancel / advance workload with gdb inside
# those operations and the cascades -- and, in the last cases, the process
# repairing it too.  Afterwards every timer must fire exactly on its due tick,
# the pool must be whole, and the operation in flight must have happened or
# not; an interrupted advance may lose what its current tick had fired.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'hiertimingwheel.h' && -f 'Makefile.PL';
my $probe = `ulimit -v 1500000; timeout 60 $gdb -nx -batch -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb cannot trace a child here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my $src = do { open my $f, '<', 'hiertimingwheel.h' or die $!; [<$f>] };
sub anchor {                      # line of the first $re after the line matching $fn
    my ($fn, $re) = @_;
    my $in = 0;
    for my $i (0 .. $#$src) {
        $in ||= $src->[$i] =~ $fn;
        return "hiertimingwheel.h:" . ($i + 1) if $in && $src->[$i] =~ $re;
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

my ($SEED, $OPS, $NS, $LV, $CAP, $MAXD) = (5, 500, 8, 3, 64, 500);
open my $mf, '>', "$dir/model.pl" or die $!;
print $mf <<'EOF';
package M;
sub ops {                         # [op, arg, payload]; also returns the pending set before each op
    my ($seed, $nops, $cap) = @_;
    srand $seed;
    my (@ops, @before, %due, $now, $next);
    ($now, $next) = (0, 1000);
    for (1 .. $nops) {
        push @before, [{%due}, $now];
        my $r = rand;
        if ($r < 0.45 && keys %due < $cap) {
            my $d = 1 + int rand 500;
            push @ops, ['add', $d, $next]; $due{$next++} = $now + $d;
        } elsif ($r < 0.65 && %due) {
            my @p = sort { $a <=> $b } keys %due;
            my $p = $p[rand @p];
            push @ops, ['cancel', 0, $p]; delete $due{$p};
        } elsif ($r > 0.97) {
            push @ops, ['clear', 0, 0]; %due = (); $now = 0;
        } else {
            my $t = 1 + int rand 40;
            push @ops, ['advance', $t, 0]; $now += $t;
            delete $due{$_} for grep { $due{$_} <= $now } keys %due;
        }
    }
    push @before, [{%due}, $now];
    return (\@ops, \@before);
}
1;
EOF
close $mf;

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings; use Data::HierTimingWheel::Shared;
my ($model, $path, $log, $seed, $nops, $ns, $lv, $cap) = @ARGV;
do $model or die $@ || $!;
my ($ops) = M::ops($seed, $nops, $cap);
my $tw = Data::HierTimingWheel::Shared->new($path, $ns, $lv, $cap);
open my $l, '+>', $log or die $!;
my %id;
for my $k (0 .. $#$ops) {
    sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", $k;
    my ($op, $a, $p) = @{ $ops->[$k] };
    if    ($op eq 'add')    { $id{$p} = $tw->add($a, $p) }
    elsif ($op eq 'cancel') { $tw->cancel($id{$p}) or die "cancel $p" }
    elsif ($op eq 'clear')  { $tw->clear }
    else                    { $tw->advance($a) }
}
sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", scalar @$ops;
EOF
close $v;

open my $c, '>', "$dir/check.pl" or die $!;
print $c <<'EOF';
use strict; use warnings; use Data::HierTimingWheel::Shared;
my ($model, $path, $log, $seed, $nops, $ns, $lv, $cap, $maxd, $recover) = @ARGV;
my $tw = Data::HierTimingWheel::Shared->new($path, $ns, $lv, $cap);
if ($recover) { $tw->stats; exit 0 }
do $model or die $@ || $!;
my $k = do { open my $f, '<', $log or die $!; 0 + <$f> };
my ($ops, $before) = M::ops($seed, $nops, $cap);
my ($due, $now0) = @{ $before->[$k] };
my ($op, $arg, $pay) = $ops->[$k] ? @{ $ops->[$k] } : ('none', 0, 0);
my %due = %$due;
$due{$pay} = $now0 + $arg if $op eq 'add';
my ($now, $count) = ($tw->now, $tw->count);
my @err;
my %fired;
my $n = 0;
my $end = $now + $maxd + 2;
while ($tw->now < $end) { $fired{$_} = $tw->now for $tw->advance(1) }
my $cleared = $op eq 'clear' && !grep { exists $fired{$_} } keys %due;
push @err, "now $now" unless $op eq 'advance' ? $now >= $now0 && $now <= $now0 + $arg
                           : $now == ($cleared ? 0 : $now0);
for my $p (sort { $a <=> $b } keys %due) {
    my ($d, $f) = ($due{$p}, delete $fired{$p});
    my $ok = $op eq 'advance' ? ($d <= $now ? !defined $f : $d == $now + 1 ? !defined $f || $f == $d : defined $f && $f == $d)
           : $cleared ? !defined $f
           : ($op eq 'add' || $op eq 'cancel') && $p == $pay ? !defined $f || $f == $d
           : defined $f && $f == $d;
    $n++ if defined $f;
    push @err, "$p due $d fired " . ($f // 'never') unless $ok;
}
push @err, 'unknown ' . join ',', keys %fired if %fired;
push @err, "count $count, $n fired" unless $count == $n;
my $free = 0;
$free++ while $free < $cap + 1 && defined eval { $tw->add(1, 1) };
push @err, "pool $free" unless $free == $cap;
printf "op=%d %s %s\n", $k, $op, @err ? "bad: @err[0 .. ($#err < 3 ? $#err : 3)]" : 'ok';
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

my @args = ($SEED, $OPS, $NS, $LV, $CAP, $MAXD);
sub state_of {
    my ($path, $log) = @_;
    my $s = `timeout 300 $^X @inc $dir/check.pl $dir/model.pl $path $log @args 2>&1`;
    chomp $s;
    return $s;
}

my $LINK = qr/^static void hw_link\(/;
my $ADV  = qr/^static uint64_t hw_advance_locked\(/;
my $CAS  = qr/^static void hw_cascade\(/;
my $CLR  = qr/^static inline void hw_clear_locked\(/;
my @steps = (0, 2, 5, 9, 14, 20, 30);
# [label, location, calls to skip, instructions to step after the stop]
my @anchors = grep { defined $_->[1] } (
    [ 'add',          'hw_add_locked',     [5, 60, 150],     [1, 10, 20, 30, 45, 70] ],
    [ 'link publish', anchor($LINK, qr/hw_slots\(h\)\[b\] = t;/), [3, 90, 300], \@steps ],
    [ 'cancel',       'hw_cancel_locked',  [2, 30, 80],      [1, 10, 20, 30, 45, 70] ],
    [ 'unlink',       'hw_unlink',         [4, 50, 120],     \@steps ],
    [ 'free',         'hw_free',           [4, 50, 120],     \@steps ],
    [ 'advance',      'hw_advance_locked', [10, 70, 150],    [1, 15, 40, 80, 150, 300] ],
    [ 'cascade',      anchor($CAS, qr/hw_slots\(h\)\[b\] = HW_NIL;/), [2, 20, 60], [0, 3, 10, 25, 60, 120] ],
    [ 'tick commit',  anchor($ADV, qr/h->hdr->now = now;/), [20, 200], [0, 1, 3] ],
    [ 'clear',        anchor($CLR, qr/slots\[s\] = HW_NIL;/),    [0, 2, 5], [0, 5, 20, 60, 150] ],
    [ 'clear timers', anchor($CLR, qr/tm->next   = \(i \+ 1 < cap\)/), [10, 150], [0, 3] ],
);
ok @anchors, 'located breakpoints: ' . join ', ', map { "$_->[0]=$_->[1]" } @anchors;

my ($runs, $hits) = (0, 0);
for my $a (@anchors) {
    for my $skip (@{ $a->[2] }) {
        for my $steps (@{ $a->[3] }) {
            my $tag = 'r' . $runs++;
            my ($path, $log) = ("$dir/$tag.tw", "$dir/$tag.log");
            my $hit = gdb_run($tag, $a->[1], $skip, $steps, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args);
            $hits += $hit;
            like state_of($path, $log), qr/^op=\d+ \w+ ok$/,
                "$a->[0], call " . ($skip + 1) . " + $steps instructions" . ($hit ? '' : ', not reached');
        }
    }
}

# The process repairing a dead writer's wheel dies too: the next one repairs it.
my $relink = anchor(qr/^static void hw_repair_locked\(HwHandle \*h\) \{/, qr/hw_link\(h, \(uint32_t\)i,/);
my $cascade = (grep { $_->[0] eq 'cascade' } @anchors)[0];
for my $r (grep { defined $_->[0] } [$relink, 0], [$relink, 20]) {
    my $tag = 'rr' . $runs++;
    my ($path, $log) = ("$dir/$tag.tw", "$dir/$tag.log");
    my $h1 = gdb_run("$tag.a", $cascade->[1], 20, 10, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args);
    my $h2 = gdb_run("$tag.b", $r->[0], $r->[1], 0, "$dir/check.pl", "$dir/model.pl", $path, $log, @args, 1);
    $hits += $h1 && $h2;
    like state_of($path, $log), qr/^op=\d+ \w+ ok$/, "writer killed mid cascade, repairer at $r->[0] call "
                                                     . ($r->[1] + 1) . ($h1 && $h2 ? '' : ' (not both reached)');
}

ok $hits, "gdb hit $hits of $runs breakpoints" or diag 'no breakpoint was reached: these runs proved nothing';
note 'killed in: ' . join ', ', map { "$_=$where{$_}" } sort { $where{$b} <=> $where{$a} } keys %where;
done_testing;
