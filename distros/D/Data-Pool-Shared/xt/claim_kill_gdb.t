use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# SIGKILL an allocator / freer (under gdb, at an instruction boundary) at every
# instruction of the claim or release, then check that recover_stale gives back
# the dead process's slot: the whole pool must be allocatable again.  (The used
# count can stay one high when the kill lands between a bit and its count update;
# that drift is older than this protocol and not checked here.)

my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root with a built blib'
    unless -f 'pool.h' && -d 'blib/arch';

my $dir = tempdir(CLEANUP => 1);
$ENV{PERL_HASH_SEED} = 0;
$ENV{PERL_PERTURB_KEYS} = 0;
my @gdb_pre = ('set pagination off', 'set confirm off', 'set breakpoint pending on',
               'set debuginfod enabled off');
{
    my $probe = `$gdb -batch -ex run --args $^X -e 1 2>&1`;
    plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;
}

my $CAP = 4;
my $lib = "$dir/pool_kill.pl";
{
    open my $f, '>', $lib or die $!;
    print $f <<'EOF';
use strict; use warnings;
use Data::Pool::Shared;
my ($mode, $path, $cap, $op, $gdbvars) = @ARGV;
my $p = Data::Pool::Shared::I64->new($path, $cap);
if ($mode eq 'victim') {
    my $s = $p->alloc;
    open my $m, '<', '/proc/self/maps' or die $!;
    my ($base) = map { /^([0-9a-f]+)-/ ? $1 : () } grep { m{ \Q$path\E$} } <$m>;
    open my $g, '>', $gdbvars or die $!;
    print $g "set \$used = (unsigned int *) (0x$base + 64)\n";
    close $g;
    $op eq 'alloc' ? $p->try_alloc : $p->free($s);
    exit 0;
}
my $rec = $p->recover_stale;
my $n = 0;
$n++ while defined $p->try_alloc;
printf "RESULT allocatable=%d used=%d\n", $n, $p->used;
EOF
}

sub gdb_run {
    my ($xs, $op, @cmds) = @_;
    unlink "$dir/p.pool";
    my $cf = "$dir/gdb.cmds";
    open my $c, '>', $cf or die $!;
    print $c join("\n", @gdb_pre, "break XS_Data__Pool__Shared_$xs", 'run', @cmds, 'kill', 'quit'), "\n";
    close $c;
    return scalar `$gdb -batch -x $cf --args $^X -Iblib/lib -Iblib/arch $lib victim $dir/p.pool $CAP $op $dir/vars.gdb 2>&1`;
}

for my $op (qw(alloc free)) {
    my $xs = $op eq 'alloc' ? 'try_alloc' : 'free';
    my $log = gdb_run($xs, $op, "source $dir/vars.gdb", 'set $u0 = *$used', 'set $n = 0',
        'while *$used == $u0', 'stepi', 'set $n = $n + 1', 'end',
        'printf "WINDOW %d\n", $n');
    my ($end) = $log =~ /WINDOW (\d+)/;
    ok($end, "$op: gdb stepped to the used-count update") or do { diag $log; next };

    my @bad;
    my $from = $end > 150 ? $end - 150 : 0;
    for my $n ($from .. $end) {
        my $k = gdb_run($xs, $op, "stepi $n");
        my $r = `$^X -Iblib/lib -Iblib/arch $lib check $dir/p.pool $CAP $op 2>&1`;
        my ($res) = $r =~ /RESULT (.*)/;
        $res //= "no result: $r";
        push @bad, "stepi $n: $res"
            unless $k =~ /Breakpoint 1[,.]/ && $res =~ /^allocatable=$CAP /;
    }
    ok(!@bad, sprintf "%s: every kill in the last %d instructions was recovered", $op, $end - $from + 1)
        or diag join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)];
}

done_testing;
