use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# reset rewrites every element's parent and size in one pass under the write
# lock; a writer killed part-way used to leave sizes and num_sets disagreeing
# with the parent forest.  The header's op word marks a reset in progress, and
# the process that recovers the dead writer's lock re-runs it.  Stop a reset at
# a store boundary with gdb, kill it, and check the next process sees all
# singletons.  A union killed between its link and the size and count updates
# must leave a partition whose sizes and num_sets agree with its links.  The
# recovery cases also kill the recovering process mid-rerun.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'dsu.h' && -f 'Makefile.PL';

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
    open my $fh, '<', 'dsu.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my $N = 64;
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings; use Data::DisjointSet::Shared;
my ($path, $op) = @ARGV;
my $d = Data::DisjointSet::Shared->new($path, 64);
if ($op eq 'recover') { $d->num_sets; $d->find(0); exit 0 }
$d->union($_, $_ + 32) for 0 .. 31;
$d->union($_, $_ + 1) for 40 .. 50;
if ($op eq q{union}) { $d->union(0, 40); exit 0 }
$d->reset;
VEOF
close $v;

sub run_gdb {
    my ($path, $op, $line, $ignore, $mid) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak dsu.h:$line\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\n",
             ($mid ? "watch -l i if i == $mid\ncontinue\n" : ''), "kill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/ && (!$mid || $log =~ /atchpoint 2: /);
}

sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::DisjointSet::Shared -e '
        my \$d = Data::DisjointSet::Shared->new(q{$path}, $N);
        my \%m; push \@{ \$m{ \$d->find(\$_) } }, \$_ for 0 .. $N - 1;
        my \$bad = grep { \$d->set_size(\$_) != \@{ \$m{\$_} } } keys \%m;
        printf "sets=%d roots=%d badsize=%d\n", \$d->num_sets, scalar(keys \%m), \$bad;
    ' 2>&1`;
    chomp $out;
    return $out;
}

sub consistent { $_[0] =~ /^sets=$N roots=$N badsize=0$/ }

my @cases = (
    [ 'reset: part of the elements rewritten', 'for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }', 0, 20 ],
    [ 'reset: num_sets not rewritten',         'h->hdr->num_sets = n;',                                      0 ],
);
my $k = 0;
for my $case (@cases) {
    my ($name, $pat, $ignore, $mid) = @$case;
    my $line = line_in('dsu_reset_locked', $pat);
    ok $line, "$name: anchored at dsu.h:" . ($line // '?') or next;
    my $path = "$dir/d" . $k++ . '.dsu';
    ok run_gdb($path, "reset", $line, $ignore, $mid), "$name: writer stopped there and killed";
    my $st = check($path);
    ok consistent($st), "$name: next process sees all singletons" or diag $st;
}

{
    my $name = 'recovery killed mid-rerun';
    my $path = "$dir/d" . $k++ . '.dsu';
    my $line = line_in('dsu_reset_locked', 'for (uint32_t i = 0; i < n; i++) { p[i] = i; sz[i] = 1; }');
    ok run_gdb($path, "reset", $line, 0, 20), "$name: writer killed mid-reset";
    ok run_gdb($path, "recover", $line, 0, 5), "$name: recovering process killed mid-rerun";
    my $st = check($path);
    ok consistent($st), "$name: third process sees all singletons" or diag $st;
}

# 43 unions precede union(0, 40), which leaves 20 sets; 21 if it did not happen
sub partition { $_[0] =~ /^sets=(\d+) roots=(\d+) badsize=0$/ && $1 == $2 && ($1 == 20 || $1 == 21) }
for my $case (['union: linked, size not updated', 'sz[ra] += sz[rb];'],
              ['union: sized, num_sets not dropped', 'h->hdr->num_sets--;']) {
    my ($name, $pat) = @$case;
    my $line = line_in('dsu_union_locked', $pat);
    ok $line, "$name: anchored at dsu.h:" . ($line // '?') or next;
    my $path = "$dir/d" . $k++ . '.dsu';
    ok run_gdb($path, 'union', $line, 43), "$name: writer stopped there and killed";
    my $st = check($path);
    ok partition($st), "$name: next process sees sizes and num_sets agreeing with the links" or diag $st;
}

{
    my $name = 'recount killed before num_sets';
    my $path = "$dir/d" . $k++ . '.dsu';
    my $l1 = line_in('dsu_union_locked', 'sz[ra] += sz[rb];');
    my $l2 = line_in('dsu_repair_locked', 'h->hdr->num_sets = sets;');
    ok $l1 && $l2, "$name: anchored" or diag 'no recount in dsu_repair_locked';
    ok run_gdb($path, 'union', $l1, 43), "$name: writer killed mid-union";
    ok $l2 && run_gdb($path, 'recover', $l2, 0), "$name: recovering process killed mid-recount";
    my $st = check($path);
    ok partition($st), "$name: third process sees sizes and num_sets agreeing with the links" or diag $st;
}

done_testing;
