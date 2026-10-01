use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Kill a writer running a random add / re-score / incr / remove / pop workload
# with gdb at points inside the B+tree code -- leaf, internal and root splits,
# merges, borrows, entry shifts, the index update -- and, in the last cases, the
# process repairing it too.  The next process must see exactly the set from
# before or after the operation in flight, with the index agreeing.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'sortedset.h' && -f 'Makefile.PL';
my $probe = `ulimit -v 1500000; timeout 60 $gdb -nx -batch -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb cannot trace a child here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my $src = do { open my $f, '<', 'sortedset.h' or die $!; [<$f>] };
sub anchor {                      # line of the $nth $re after the line matching $fn
    my ($fn, $re, $nth) = @_;
    my $in = 0;
    for my $i (0 .. $#$src) {
        $in ||= $src->[$i] =~ $fn;
        return "sortedset.h:" . ($i + 1) if $in && $src->[$i] =~ $re && !($nth && $nth--);
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

my ($SEED, $N1, $N2, $MAX) = (7, 1200, 1500, 4000);
open my $mf, '>', "$dir/model.pl" or die $!;
print $mf <<'EOF';
package M;
sub ops {
    my ($seed, $n1, $n2) = @_;
    srand $seed;
    my (%s, @m, %pos, @ops);
    my $ins = sub { $pos{$_[0]} = @m; push @m, $_[0]; $s{$_[0]} = $_[1] };
    my $del = sub {
        my $i = delete $pos{$_[0]}; my $last = pop @m;
        if ($i < @m) { $m[$i] = $last; $pos{$last} = $i }
        delete $s{$_[0]};
    };
    for my $k (0 .. $n1 + $n2 - 1) {
        my $r = $k < $n1 ? 0 : rand;
        my $sc = int(rand 2000) / 4;
        if ($r < 0.3 || !@m) {
            my $x; do { $x = int rand 100000 } while exists $s{$x};
            push @ops, ['add', $x, $sc]; $ins->($x, $sc);
        } elsif ($r < 0.55) { my $x = $m[rand @m]; push @ops, ['add', $x, $sc]; $s{$x} = $sc }
        elsif ($r < 0.65)   { my $x = $m[rand @m]; push @ops, ['incr', $x, $sc - 250]; $s{$x} += $sc - 250 }
        elsif ($r < 0.95)   { my $x = $m[rand @m]; push @ops, ['remove', $x]; $del->($x) }
        else {
            my $hi = $r >= 0.975;
            my ($x) = sort { $hi ? ($s{$b} <=> $s{$a} || $b <=> $a) : ($s{$a} <=> $s{$b} || $a <=> $b) } keys %s;
            push @ops, [$hi ? 'pop_max' : 'pop_min', $x]; $del->($x);
        }
    }
    return \@ops;
}
sub image {                       # the set after the first $j ops, in (score, member) order
    my ($ops, $j) = @_;
    my %s;
    for my $o (@$ops[0 .. $j - 1]) {
        if    ($o->[0] eq 'add')  { $s{$o->[1]} = $o->[2] }
        elsif ($o->[0] eq 'incr') { $s{$o->[1]} += $o->[2] }
        else                      { delete $s{$o->[1]} }
    }
    return join ' ', map { "$_:$s{$_}" } sort { $s{$a} <=> $s{$b} || $a <=> $b } keys %s;
}
1;
EOF
close $mf;

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings; use Data::SortedSet::Shared;
my ($model, $path, $log, $seed, $n1, $n2, $max) = @ARGV;
do $model or die $@ || $!;
my $ops = M::ops($seed, $n1, $n2);
my $z = Data::SortedSet::Shared->new($path, $max);
open my $l, '+>', $log or die $!;
for my $k (0 .. $#$ops) {
    sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", $k;
    my ($op, $x, $a) = @{ $ops->[$k] };
    if    ($op eq 'add')     { $z->add($x, $a) }
    elsif ($op eq 'incr')    { $z->incr($x, $a) }
    elsif ($op eq 'remove')  { $z->remove($x) }
    elsif ($op eq 'pop_min') { $z->pop_min }
    else                     { $z->pop_max }
}
sysseek $l, 0, 0; syswrite $l, sprintf "%08d\n", scalar @$ops;
EOF
close $v;

open my $c, '>', "$dir/check.pl" or die $!;
print $c <<'EOF';
use strict; use warnings; use Data::SortedSet::Shared;
my ($model, $path, $log, $seed, $n1, $n2, $max, $recover) = @ARGV;
my $z = Data::SortedSet::Shared->new($path, $max);
if ($recover) { $z->count; exit 0 }
do $model or die $@ || $!;
my $k = do { open my $f, '<', $log or die $!; 0 + <$f> };
my $ops = M::ops($seed, $n1, $n2);
my @l = $z->range_by_rank(0, -1, withscores => 1);
my (@got, $bad);
while (my ($m, $s) = splice @l, 0, 2) {
    push @got, "$m:$s";
    my $is = $z->score($m);
    $bad++ unless defined $is && $is == $s;
}
my $got = join ' ', @got;
my ($pre, $post) = (M::image($ops, $k), M::image($ops, $k + 1));
my $how = $got eq $pre ? 'pre' : $got eq $post ? 'post' : do {
    my %g = map { $_ => 1 } @got; my %p = map { $_ => 1 } split ' ', $pre;
    sprintf 'neither (%d missing, %d extra vs pre)', scalar(grep { !$g{$_} } keys %p), scalar(grep { !$p{$_} } @got);
};
printf "op=%d %s valid=%d index=%s count=%d\n", $k, $how, $z->_validate ? 1 : 0, $bad ? 'bad' : 'ok', $z->count;
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

my @args = ($SEED, $N1, $N2, $MAX);
sub state_of {
    my ($path, $log) = @_;
    my $s = `timeout 300 $^X @inc $dir/check.pl $dir/model.pl $path $log @args 2>&1`;
    chomp $s;
    return $s;
}

my $ADD = qr/^static void ss_tree_add\(/;
my $INS = qr/^static SsSplit ss_insert_rec\(/;
my $UND = qr/^static void ss_fix_underflow\(/;
my @steps = (0, 3, 12, 40, 120, 400);
# [label, location, calls to skip, instructions to step after the stop]
my @anchors = grep { defined $_->[1] } (
    [ 'tree add',       'ss_tree_add',  [190, 700, 1250, 1600, 2100], [1, 60, 250, 700, 1500, 3000] ],
    [ 'tree del',       'ss_tree_del',  [40, 150, 400, 700],          [1, 60, 250, 700, 1500, 3000] ],
    [ 'leaf split',     anchor($INS, qr/uint32_t ridx = ss_node_alloc\(h\);/, 0), [0, 5, 40], \@steps ],
    [ 'internal split', anchor($INS, qr/uint32_t ridx = ss_node_alloc\(h\);/, 1), [0, 2],     \@steps ],
    [ 'root split',     anchor($ADD, qr/uint32_t nr = ss_node_alloc\(h\);/),      [0],        \@steps ],
    [ 'merge',          'ss_merge',     [0, 6, 30],                   \@steps ],
    [ 'borrow left',    anchor($UND, qr/borrow from left/),           [0, 6, 30], \@steps ],
    [ 'borrow right',   anchor($UND, qr/borrow from right/),          [0, 6, 30], \@steps ],
    [ 'index set',      'ss_idx_set',   [300, 1500],                  [0, 5, 20] ],
    [ 'index del',      'ss_idx_del',   [10, 300],                    [0, 5, 20, 60] ],
);
ok @anchors, 'located breakpoints: ' . join ', ', map { "$_->[0]=$_->[1]" } @anchors;

sub intact {
    my ($s, $what) = @_;
    like $s, qr/^op=\d+ (pre|post) valid=1 index=ok count=\d+$/, $what or diag $s;
}

my ($runs, $hits) = (0, 0);
for my $a (@anchors) {
    for my $skip (@{ $a->[2] }) {
        for my $steps (@{ $a->[3] }) {
            my $tag = 'r' . $runs++;
            my ($path, $log) = ("$dir/$tag.ss", "$dir/$tag.log");
            my $hit = gdb_run($tag, $a->[1], $skip, $steps, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args, 0);
            $hits += $hit;
            intact(state_of($path, $log), "$a->[0], call " . ($skip + 1) . " + $steps instructions"
                                          . ($hit ? '' : ', not reached'));
        }
    }
}

# The process repairing a dead writer's set dies too: the next one repairs it.
my $replant = anchor(qr/^static void ss_rebuild_locked\(SsHandle \*h\) \{/, qr/ss_tree_add\(h, s->score, s->member\);/);
my $rebuild = anchor(qr/^static void ss_rebuild_from_tree\(/, qr/hdr->rightmost = rb\.prev_leaf;/);
my $leaf = (grep { $_->[0] eq 'leaf split' } @anchors)[0];
for my $r (grep { defined $_->[0] } [$replant, 0], [$replant, 400], [$replant, 1000], [$rebuild, 0]) {
    my $tag = 'rr' . $runs++;
    my ($path, $log) = ("$dir/$tag.ss", "$dir/$tag.log");
    my $h1 = gdb_run("$tag.a", $leaf->[1], 5, 12, "$dir/victim.pl", "$dir/model.pl", $path, $log, @args, 0);
    my $h2 = gdb_run("$tag.b", $r->[0], $r->[1], 0, "$dir/check.pl", "$dir/model.pl", $path, $log, @args, 1);
    $hits += $h1 && $h2;
    intact(state_of($path, $log), "writer killed mid leaf split, repairer at $r->[0] call " . ($r->[1] + 1)
                                  . ($h1 && $h2 ? '' : ' (not both reached)'));
}

ok $hits, "gdb hit $hits of $runs breakpoints" or diag 'no breakpoint was reached: these runs proved nothing';
note 'killed in: ' . join ', ', map { "$_=$where{$_}" } sort { $where{$b} <=> $where{$a} } keys %where;
done_testing;
