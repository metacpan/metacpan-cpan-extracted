use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# clear rethreads every bucket and timer in one pass under the write lock; a
# writer killed part-way used to leave active timers on the free list.  The
# header's op word marks a clear in progress, and the process that recovers the
# dead writer's lock re-runs it.  Stop a clear at a store boundary with gdb,
# kill it, and check the next process sees an empty, fully usable wheel.  The
# last case also kills the recovering process mid-rerun.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'timingwheel.h' && -f 'Makefile.PL';

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
    open my $fh, '<', 'timingwheel.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my $CAP = 32;
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'VEOF';
use strict; use warnings; use Data::TimingWheel::Shared;
my ($path, $op) = @ARGV;
my $tw = Data::TimingWheel::Shared->new($path, 16, 32);
if ($op eq 'recover') { $tw->stats; exit 0 }
$tw->add($_, 100 + $_) for 1 .. 20;
$tw->advance(3);
$tw->clear;
VEOF
close $v;

sub run_gdb {
    my ($path, $op, $line, $ignore) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak timingwheel.h:$line\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\nkill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/;
}

# every counted timer must fire, and the whole capacity must be allocatable again
sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::TimingWheel::Shared -e '
        my \$tw = Data::TimingWheel::Shared->new(q{$path}, 16, $CAP);
        \$tw->stats;
        my \$n = \$tw->count;
        my \$fired = () = \$tw->advance(64);
        my \$after = \$tw->count;
        my \$added = 0;
        \$added++ while \$added <= $CAP && defined eval { \$tw->add(1 + \$added % 5, \$added) };
        my \$fired2 = () = \$tw->advance(64);
        print "count=\$n fired=\$fired after=\$after added=\$added fired2=\$fired2\n";
    ' 2>&1`;
    chomp $out;
    return $out;
}

sub consistent {
    my ($st) = @_;
    my ($n, $f, $a, $ad, $f2) = $st =~ /count=(\d+) fired=(\d+) after=(\d+) added=(\d+) fired2=(\d+)/ or return 0;
    return $n == 0 && $f == 0 && $a == 0 && $ad == $CAP && $f2 == $CAP;
}

my @cases = (
    [ 'clear: buckets emptied, timers not', 'tm->next  = (i + 1 < cap)', 0 ],
    [ 'clear: mid timer rethread',          'tm->next  = (i + 1 < cap)', 10 ],
    [ 'clear: header counters not reset',   'h->hdr->now = 0;',          0 ],
);
my $k = 0;
for my $case (@cases) {
    my ($name, $pat, $ignore) = @$case;
    my $line = line_in('tw_clear_locked', $pat);
    ok $line, "$name: anchored at timingwheel.h:" . ($line // '?') or next;
    my $path = "$dir/w" . $k++ . '.tw';
    ok run_gdb($path, 'clear', $line, $ignore), "$name: writer stopped there and killed";
    my $st = check($path);
    ok consistent($st), "$name: next process sees an empty, usable wheel" or diag $st;
}

{
    my $name = 'recovery killed mid-rerun';
    my $path = "$dir/w" . $k++ . '.tw';
    my $line = line_in('tw_clear_locked', 'tm->next  = (i + 1 < cap)');
    ok run_gdb($path, 'clear', $line, 10), "$name: writer killed mid-clear";
    ok run_gdb($path, 'recover', $line, 5), "$name: recovering process killed mid-rerun";
    my $st = check($path);
    ok consistent($st), "$name: third process sees an empty, usable wheel" or diag $st;
}

done_testing;
