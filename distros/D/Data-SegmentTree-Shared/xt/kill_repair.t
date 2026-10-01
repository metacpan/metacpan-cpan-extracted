use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# A writer killed mid range op leaves a node's aggregate disagreeing with its
# children and lazy tags.  Stop it at exactly such a boundary with gdb, kill it,
# and check that the next process -- whose lock call recovers the dead writer's
# lock -- sees a tree whose range queries agree with its point values, and a
# killed clear as done.  The last case also kills the recovering process
# mid-repair.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'segtree.h' && -f 'Makefile.PL';

my $dir = tempdir(CLEANUP => 1);
my $probe = `ulimit -v 1500000; timeout 60 $gdb -nx -batch -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb cannot trace a child here (ptrace denied?)'
    unless $probe =~ /exited normally/;

# -O0 -g: breakpoints need line info, and -O0 keeps each line's stores on its side of the stop.
my $bd = "$dir/build";
mkdir $bd or die $!;
system('cp', '-r', 'Makefile.PL', 'Shared.xs', glob('*.h'), 'lib', $bd) == 0 or die 'cp failed';
my $build = `cd $bd && $^X Makefile.PL 2>&1 && make OPTIMIZE='-O0 -g' 2>&1`;
is $?, 0, 'debug build' or BAIL_OUT($build);
my @inc = ("-I$bd/blib/lib", "-I$bd/blib/arch");

sub line_in {
    my ($fn, $pat) = @_;
    open my $fh, '<', 'segtree.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my $N = 16;
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings; use Data::SegmentTree::Shared;
my ($path, $op) = @ARGV;
my $t = Data::SegmentTree::Shared->new($path, 16);
if ($op eq 'recover') { $t->sum(0, 15); exit 0 }
$t->range_assign(0, 15, 4);
$t->range_add(0, 15, 1);
if    ($op eq 'add')    { $t->range_add(3, 10, 5) }
elsif ($op eq 'assign') { $t->range_assign(2, 9, -7) }
elsif ($op eq 'clear')  { $t->clear }
VEOF
close $v;

sub run_gdb {
    my ($path, $op, $line, $ignore) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak segtree.h:$line\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\nkill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/;
}

# every range's sum/min/max must equal what its point values give
sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::SegmentTree::Shared -e '
        my \$t = Data::SegmentTree::Shared->new(q{$path}, $N);
        \$t->sum(0, 0);
        my \@p = map { \$t->get(\$_) } 0 .. $N - 1;
        my \$bad = 0;
        for my \$l (0 .. $N - 1) { for my \$r (\$l .. $N - 1) {
            my \$q = \$t->query(\$l, \$r);
            my (\$s, \$mn, \$mx) = (0, \$p[\$l], \$p[\$l]);
            for (\@p[\$l .. \$r]) { \$s += \$_; \$mn = \$_ if \$_ < \$mn; \$mx = \$_ if \$_ > \$mx }
            \$bad++ if \$q->{sum} != \$s || \$q->{min} != \$mn || \$q->{max} != \$mx;
        } }
        print "bad=\$bad values=\@p\n";
    ' 2>&1`;
    chomp $out;
    return $out;
}

my @cases = (
    [ 'range_add: children updated, node not pulled', 'add',    'st_range_add_rec',    'st_pull(nodes, v);', 0 ],
    [ 'range_add: covered node half-applied',         'add',    'st_apply_add',        'nd->max += delta;',  2 ],
    [ 'range_assign: children updated, node not',     'assign', 'st_range_assign_rec', 'st_pull(nodes, v);', 1 ],
    [ 'clear: root assigned, nodes not zeroed',       'clear',  'st_clear_locked',     'memset(nodes + 2, 0,', 0, '(0 ){15}0' ],
    [ 'clear: nodes zeroed, root not',                'clear',  'st_clear_locked',     'memset(nodes, 0, 2 *', 0, '(0 ){15}0' ],
);
my $k = 0;
for my $case (@cases) {
    my ($name, $op, $fn, $pat, $ignore, $want) = @$case;
    my $line = line_in($fn, $pat);
    ok $line, "$name: anchored at segtree.h:" . ($line // '?') or next;
    my $path = "$dir/t" . $k++ . '.st';
    my $warm = $fn eq q{st_apply_add} ? 1 : 0;
    ok run_gdb($path, $op, $line, $ignore + $warm), "$name: writer stopped there and killed";
    my $st = check($path);
    like $st, qr/^bad=0 /, "$name: next process sees consistent ranges" or diag $st;
    like $st, qr/ values=$want$/, "$name: ... and the values it must" or diag $st if $want;
}

{
    my $name = 'recovery killed mid-repair';
    my $path = "$dir/t" . $k++ . '.st';
    my $l1 = line_in('st_range_add_rec', 'st_pull(nodes, v);');
    my $l2 = line_in("st_repair_locked", "nd->gcd = st_gcd2(nd->sum, 0);");
    ok $l1 && $l2, "$name: anchored" or diag 'no st_repair_locked';
    ok run_gdb($path, "add", $l1, 0), "$name: writer killed mid range_add";
    ok $l2 && run_gdb($path, 'recover', $l2, 1), "$name: recovering process killed mid-repair";
    my $st = check($path);
    like $st, qr/^bad=0 /, "$name: third process sees consistent ranges" or diag $st;
}

done_testing;
