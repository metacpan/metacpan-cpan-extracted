use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# A writer killed mid add or mid clear leaves total_count disagreeing with the
# buckets.  Stop it at exactly such a boundary with gdb, kill it, and check that
# the next process -- whose lock call recovers the dead writer's lock -- sees a
# sketch whose count, quantiles, min and max agree.  The last case also kills
# the recovering process mid-repair.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'ddsketch.h' && -f 'Makefile.PL';

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
    open my $fh, '<', 'ddsketch.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings; use Data::DDSketch::Shared;
my ($path, $op) = @ARGV;
my $d = Data::DDSketch::Shared->new($path, 0.01, 2048);
if ($op eq 'recover') { $d->quantile(0.5); exit 0 }
$d->add($_) for -50 .. 50;
if    ($op eq 'add')   { $d->add(-1e6) }
elsif ($op eq 'clear') { $d->clear }
VEOF
close $v;

sub run_gdb {
    my ($path, $op, $line, $ignore) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak ddsketch.h:$line\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\nkill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/;
}

sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::DDSketch::Shared -e '
        my \$d = Data::DDSketch::Shared->new(q{$path}, 0.01, 2048);
        my \@q = map { \$d->quantile(\$_) } 0, 1;
        my \@v = (\$d->min, \$d->max, \$d->mean);
        print join(" ", "n=" . \$d->count, "z=" . \$d->zero_count,
                   map { defined ? sprintf("%.6g", \$_) : "undef" } \@q, \@v), "\n";
    ' 2>&1`;
    chomp $out;
    return $out;
}

sub near { my ($a, $b) = @_; abs($a - $b) <= 0.021 * abs($b) + 1e-9 }

sub consistent {
    my ($st) = @_;
    my ($n, $z, @f) = $st =~ /^n=(\d+) z=(\d+) (\S+) (\S+) (\S+) (\S+) (\S+)$/ or return 0;
    return $z == 0 && !grep { $_ ne 'undef' } @f if $n == 0;
    return 0 if $z > $n || grep { $_ eq 'undef' } @f;
    my ($q0, $q1, $mn, $mx, $mean) = @f;
    return near($q0, $mn) && near($q1, $mx) && $mn <= $mean && $mean <= $mx;
}

my @cases = (
    [ 'add: bucket counted, total not',     'add',   'dd_insert_locked', 'hdr->total_count += count;', 101 ],
    [ 'clear: negatives zeroed only',       'clear', 'dd_clear_locked',  'memset(dd_pos(h), 0,',       0 ],
    [ 'clear: all but zero_count cleared',  'clear', 'dd_clear_locked',  'hdr->zero_count  = 0;',      0 ],
);
my $k = 0;
for my $case (@cases) {
    my ($name, $op, $fn, $pat, $ignore) = @$case;
    my $line = line_in($fn, $pat);
    ok $line, "$name: anchored at ddsketch.h:" . ($line // '?') or next;
    my $path = "$dir/d" . $k++ . '.dd';
    ok run_gdb($path, $op, $line, $ignore), "$name: writer stopped there and killed";
    my $st = check($path);
    ok consistent($st), "$name: next process sees a consistent sketch" or diag $st;
}

{
    my $name = 'recovery killed mid-repair';
    my $path = "$dir/d" . $k++ . '.dd';
    my $l1 = line_in('dd_clear_locked', 'memset(dd_pos(h), 0,');
    my $l2 = line_in('dd_repair_locked', 'hdr->total_count = n;');
    ok $l1 && $l2, "$name: anchored" or diag 'no dd_repair_locked';
    ok run_gdb($path, 'clear', $l1, 0), "$name: writer killed mid-clear";
    ok $l2 && run_gdb($path, 'recover', $l2, 0), "$name: recovering process killed mid-repair";
    my $st = check($path);
    ok consistent($st), "$name: third process sees a consistent sketch" or diag $st;
}

done_testing;
