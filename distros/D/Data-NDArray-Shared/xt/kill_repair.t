use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep);

# A reshape killed between its header stores leaves ndim/shape/strides mixed.
# Stop it right after one of those stores with a gdb watchpoint, kill it, and
# check that a process attached before the kill (its lock call recovers the
# dead writer) and a process attaching afterwards both see a consistent shape
# over the untouched data.  The last case also kills the recovering process.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'ndarray.h' && -f 'Makefile.PL';

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

sub line_of {
    my ($file, $fn, $pat) = @_;
    open my $fh, '<', $file or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /$fn/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'EOF';
use strict; use warnings; use Time::HiRes qw(sleep); use Data::NDArray::Shared;
my ($path, $case) = @ARGV;
my $nochild = $case =~ s/!$//;
if ($case eq 'recover') { my @s = Data::NDArray::Shared->new($path, 'i64', 24)->shape; exit 0 }
my %from = (a => [6, 4], b => [2, 3, 4], c => [24]);
my %to   = (a => [4, 6], b => [24],      c => [2, 3, 4]);
my $a = Data::NDArray::Shared->new($path, 'i64', @{ $from{$case} });
$a->set_flat($_, $_) for 0 .. 23;
my $pid = $nochild ? 1 : fork // die "fork: $!";
if (!$pid) {
    my $pp = getppid;
    sleep 0.02 while kill 0, $pp;
    my @s = $a->shape; my @st = $a->strides; my $l = $a->to_list;
    open my $o, '>', "$path.tmp" or die $!;
    print $o "shape=@s strides=@st data=@$l\n";
    close $o; rename "$path.tmp", "$path.out";
    exit 0;
}
$a->reshape(@{ $to{$case} });
EOF
close $v;

sub run_gdb {
    my ($path, $case, $break, $watch) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak $break\nrun\n",
             ($watch ? "watch -l h->hdr->$watch\ncontinue\n" : ''), "kill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $case 2>&1`;
    return $log =~ /Breakpoint 1[,.]/ && (!$watch || $log =~ /watchpoint 2: /i);
}

sub fresh_view {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::NDArray::Shared -e '
        my \$a = Data::NDArray::Shared->new(q{$path}, "i64", 24);
        my \@s = \$a->shape; my \@st = \$a->strides; my \$l = \$a->to_list;
        print "shape=\@s strides=\@st data=\@\$l\n";
    ' 2>&1`;
    chomp $out;
    return $out;
}

sub attached_view {
    my ($path) = @_;
    for (1 .. 600) { last if -e "$path.out"; sleep 0.05 }
    open my $fh, '<', "$path.out" or return 'attached process wrote nothing';
    chomp(my $l = <$fh>);
    return $l;
}

sub consistent {
    my ($st) = @_;
    my ($s, $t, $d) = $st =~ /^shape=([\d ]+) strides=([\d ]+) data=([\d ]+)$/ or return 0;
    my @s = split ' ', $s;
    my @t = split ' ', $t;
    return 0 unless @s == @t && $d eq join ' ', 0 .. 23;
    my ($n, $want) = (1, 1);
    $n *= $_ for @s;
    for my $i (reverse 0 .. $#s) { return 0 if $t[$i] != $want; $want *= $s[$i] }
    return $n == 24;
}

my $line = line_of('Shared.xs', qr/^reshape\(/, 'h->hdr->ndim = (uint32_t)nd;');
ok $line, "anchored in reshape at Shared.xs:" . ($line // '?') or BAIL_OUT('no anchor');

my @cases = (
    [ '(6,4) -> (4,6), killed after shape[0]',  'a', 'shape[0]' ],
    [ '(2,3,4) -> (24), killed after ndim',     'b', 'ndim' ],
    [ '(24) -> (2,3,4), killed after ndim',     'c', 'ndim' ],
);
my $k = 0;
for my $case (@cases) {
    my ($name, $c, $watch) = @$case;
    my $path = "$dir/a" . $k++ . '.nda';
    ok run_gdb($path, $c, "Shared.xs:$line", $watch), "$name: writer stopped mid-reshape and killed";
    my $att = attached_view($path);
    ok consistent($att), "$name: already-attached process sees a consistent shape" or diag $att;
    my $fr = fresh_view($path);
    ok consistent($fr), "$name: a new process attaches and sees a consistent shape" or diag $fr;
}

{
    my $name = 'recovery killed mid-repair';
    my $path = "$dir/a" . $k++ . '.nda';
    my $l2 = line_of('ndarray.h', qr/^static.*\bnda_repair_shape_locked\(/, 'h->hdr->shape[0] = h->size;');
    ok $l2, "$name: anchored" or diag 'no nda_repair_shape_locked';
    ok run_gdb($path, "a!", "Shared.xs:$line", "shape[0]"), "$name: writer killed mid-reshape";
    ok $l2 && run_gdb($path, 'recover', "ndarray.h:$l2"), "$name: recovering process killed mid-repair";
    my $fr = fresh_view($path);
    ok consistent($fr), "$name: third process sees a consistent shape" or diag $fr;
}

done_testing;
