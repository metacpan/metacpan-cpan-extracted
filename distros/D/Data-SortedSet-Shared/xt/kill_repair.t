use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# A writer killed between the B+tree update and the member-index update (or
# mid count propagation, or mid clear) leaves the two disagreeing.  Stop it at
# exactly such a boundary with gdb, kill it, and check that the next process --
# whose lock call recovers the dead writer's lock -- sees a set whose tree,
# index, count and free list agree.  The last case also kills the recovery.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'sortedset.h' && -f 'Makefile.PL';

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
    open my $fh, '<', 'sortedset.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my ($MAX, $N) = (200, 100);
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'EOF';
use strict; use warnings; use Data::SortedSet::Shared;
my ($path, $op) = @ARGV;
my $z = Data::SortedSet::Shared->new($path, 200);
if ($op eq 'recover') { $z->count; $z->_validate; exit 0 }
$z->add($_, $_ * 1.5) for 0 .. 99;
if    ($op eq 'add')    { $z->add(1000 + $_, $_ + 0.25) for 0 .. 4 }
elsif ($op eq 'remove') { $z->remove($_ * 7) for 0 .. 4 }
elsif ($op eq 'rescore'){ $z->add(5, 500) }
elsif ($op eq 'clear')  { $z->clear }
EOF
close $v;

sub run_gdb {
    my ($path, $op, $where, $ignore) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak $where\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\nkill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/;
}

sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::SortedSet::Shared -e '
        my \$z = Data::SortedSet::Shared->new(q{$path}, $MAX);
        my \$ok = \$z->_validate ? 1 : 0;
        my \%sc = \$z->range_by_rank(0, -1, withscores => 1);
        my \$img = join q{ }, map { "\$_:\$sc{\$_}" } sort { \$a <=> \$b } keys \%sc;
        my \@m = \$z->range_by_rank(0, -1);
        my \%in = map { \$_ => 1 } \@m;
        my \$bad = 0;
        for my \$x (0 .. 99, 1000 .. 1004) {
            \$bad++ if (\$in{\$x} ? 1 : 0) != (\$z->exists(\$x) ? 1 : 0);
            \$bad++ if \$in{\$x} && !defined \$z->score(\$x);
        }
        my \$n = \$z->count;
        my \$i = 0;
        \$i++ while \$z->count < $MAX && defined \$z->add(10_000 + \$i, \$i) && \$i < 1000;
        printf "valid=%d count=%d listed=%d bad=%d full=%d set=%s\n", \$ok, \$n, scalar(\@m), \$bad, \$z->count, \$img;
    ' 2>&1`;
    chomp $out;
    return $out;
}

# consistent, and exactly the set from before or after the write in flight
sub consistent {
    my ($st, $pre, $post) = @_;
    my ($ok, $n, $l, $b, $f, $set) = $st =~ /valid=(\d) count=(\d+) listed=(\d+) bad=(\d+) full=(\d+) set=(.*)$/ or return 0;
    return $ok && $n == $l && !$b && $f == $MAX && ($set eq img($pre) || $set eq img($post));
}
sub img { my ($h) = @_; join ' ', map { "$_:$h->{$_}" } sort { $a <=> $b } keys %$h }

my %base = map { $_ => $_ * 1.5 } 0 .. 99;
my %two  = (%base, 1000 => 0.25, 1001 => 1.25);
my %rm2  = %base; delete @rm2{0, 7};
my %rm3  = %rm2;  delete $rm3{14};
my %rm1  = %base; delete $rm1{0};
my @cases = (
    [ 'add: in the tree, not the index',   'add',     'ss_put_locked',    'int ok = ss_idx_set(h, member, score);', $N, undef,
      \%base, { %base, 1000 => 0.25 } ],
    [ 'add: mid count propagation',        'add',     'ss_insert_rec',    'if (!cr.split) { nd->counts[c]++; return r; }', 0, 'member == 1002',
      \%two, { %two, 1002 => 2.25 } ],
    [ 'remove: out of the tree, not index','remove',  'ss_drop_locked',   'ss_idx_del(h, member);', 2, undef, \%rm2, \%rm3 ],
    [ 'rescore: deleted, not re-added',    'rescore', undef,              'ss_tree_add', 1, 'member == 5',
      \%base, { %base, 5 => 500 } ],
    [ 'clear: tree dropped, index intact', 'clear',   'ss_clear_locked',  'memset(h->index, 0,', 0, undef, \%base, {} ],
);

my $k = 0;
for my $case (@cases) {
    my ($name, $op, $fn, $pat, $ignore, $cond, $pre, $post) = @$case;
    my $where = $pat;
    if (defined $fn) {
        my $line = line_in($fn, $pat);
        ok $line, "$name: anchored at sortedset.h:" . ($line // '?') or next;
        $where = "sortedset.h:$line";
    }
    $where .= " if $cond" if $cond;
    my $path = "$dir/z" . $k++ . '.ss';
    ok run_gdb($path, $op, $where, $ignore), "$name: writer stopped there and killed";
    my $st = check($path);
    ok consistent($st, $pre, $post), "$name: next process sees the set from before or after" or diag $st;
}

{
    my $name = 'recovery killed mid-rebuild';
    my $path = "$dir/z" . $k++ . '.ss';
    my $l1 = line_in('ss_drop_locked', 'ss_idx_del(h, member);');
    my $l2 = line_in('ss_rebuild_from_tree', 'hdr->rightmost = rb.prev_leaf;');
    ok $l1 && $l2, "$name: anchored" or diag 'no ss_rebuild_from_tree';
    ok run_gdb($path, 'remove', "sortedset.h:$l1", 0), "$name: writer killed mid-remove";
    ok $l2 && run_gdb($path, 'recover', "sortedset.h:$l2", 0), "$name: recovering process killed mid-rebuild";
    my $st = check($path);
    ok consistent($st, \%base, \%rm1), "$name: third process sees the set from before or after" or diag $st;
}

done_testing;
