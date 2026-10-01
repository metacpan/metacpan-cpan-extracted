use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# SIGKILL a writer (under gdb, at an instruction boundary) at points spread over
# a container rewrite, and check that the next process sees the bitmap exactly
# as it was before the call or after it, with its cardinality right and no
# container slot lost.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root with a built blib'
    unless -f 'roaring.h' && -d 'blib/arch';

my $dir = tempdir(CLEANUP => 1);
# Same instruction stream in every run, so a step count lands at the same place.
$ENV{PERL_HASH_SEED} = 0;
$ENV{PERL_PERTURB_KEYS} = 0;
my @gdb_pre = ('set pagination off', 'set confirm off', 'set breakpoint pending on',
               'set debuginfod enabled off');
{
    my $probe = `$gdb -batch -ex run --args $^X -e 1 2>&1`;
    plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;
}

my $CAP = 8;
my @evens = map { 2 * $_ } 0 .. 3999;
my %op = (
    insert  => { xs => 'add',       a => \@evens,       b => [],
                 call => '$a->add(1)',        post => [sort { $a <=> $b } @evens, 1] },
    promote => { xs => 'add',       a => [0 .. 4095],   b => [],
                 call => '$a->add(5000)',     post => [0 .. 4095, 5000] },
    remove  => { xs => 'remove',    a => \@evens,       b => [],
                 call => '$a->remove(0)',     post => [@evens[1 .. $#evens]] },
);

my $lib = "$dir/rb_kill.pl";
{
    open my $f, '>', $lib or die $!;
    print $f <<'EOF';
use strict; use warnings;
use Data::RoaringBitmap::Shared;
my ($mode, $dir, $cap, $call, $gdbvars) = @ARGV;
my $spec = do "$dir/spec.pl" or die "spec: $@ $!";
my @pre = @{ $spec->{a} };
if ($mode eq 'victim') {
    my $a = Data::RoaringBitmap::Shared->new("$dir/a.rb", $cap);
    my $b = Data::RoaringBitmap::Shared->new("$dir/b.rb", $cap);
    $a->add_many(\@pre);
    $b->add_many($spec->{b}) if @{ $spec->{b} };
    open my $m, '<', '/proc/self/maps' or die $!;
    my ($base) = map { /^([0-9a-f]+)-/ ? $1 : () } grep { m{ \Q$dir\E/a\.rb$} } <$m>;
    open my $g, '>', $gdbvars or die $!;
    print $g "set \$wl = (unsigned int *) (0x$base + 72)\n";
    close $g;
    eval $call; die $@ if $@;
    exit 0;
}
open my $raw, '<:raw', "$dir/a.rb" or die $!;
sysseek $raw, 72, 0; sysread $raw, my $w, 4; close $raw;
my $held = unpack('V', $w) ? 1 : 0;
my $a = Data::RoaringBitmap::Shared->new("$dir/a.rb", $cap);
my $got = join ',', @{ $a->to_array };
my $which = $got eq join(',', @pre) ? 'pre' : $got eq join(',', @{ $spec->{post} }) ? 'post' : 'torn';
my $card_ok = $a->cardinality == scalar(@{ $a->to_array }) ? 1 : 0;
my $want = $cap - 1 - $a->stats->{buckets_used};
my $free = 0;
for my $hi (1000 .. 1000 + $cap) { last unless eval { $a->add($hi << 16); 1 }; $free++ }
print "RESULT held=$held $which card_ok=$card_ok free=$free want=$want\n";
EOF
}

sub gdb_run {
    my ($xs, $tag, @cmds) = @_;
    my $cf = "$dir/gdb.cmds";
    open my $c, '>', $cf or die $!;
    print $c join("\n", @gdb_pre, "break XS_Data__RoaringBitmap__Shared_$xs", 'run', @cmds, 'kill', 'quit'), "\n";
    close $c;
    return scalar `$gdb -batch -x $cf --args $^X -Iblib/lib -Iblib/arch $lib victim $dir $CAP '$tag' $dir/vars.gdb 2>&1`;
}

sub fresh {
    my ($o) = @_;
    unlink "$dir/a.rb", "$dir/b.rb";
    require Data::Dumper;
    open my $s, '>', "$dir/spec.pl" or die $!;
    print $s Data::Dumper->new([{ a => $o->{a}, b => $o->{b}, post => $o->{post} }])->Terse(1)->Indent(0)->Dump;
    close $s;
}

for my $name (sort keys %op) {
    my $o = $op{$name};
    fresh($o);
    my $log = gdb_run($o->{xs}, $o->{call}, "source $dir/vars.gdb", 'set $n = 0',
        'while *$wl == 0', 'stepi', 'set $n = $n + 1', 'end', 'set $lk = $n',
        'while *$wl != 0', 'stepi', 'set $n = $n + 1', 'end',
        'printf "WINDOW %d %d\n", $lk, $n');
    my ($lo, $hi) = $log =~ /WINDOW (\d+) (\d+)/;
    ok($lo && $hi > $lo, "$name: gdb found the write-locked window")
        or do { diag $log; next };

    my %n;
    $n{ $lo + int($_ * ($hi - $lo) / 8) } = 1 for 0 .. 7;
    $n{$_} = 1 for grep { $_ >= $lo } $hi - 10 .. $hi - 1;
    my (@bad, %seen);
    for my $n (sort { $a <=> $b } keys %n) {
        fresh($o);
        my $k = gdb_run($o->{xs}, $o->{call}, "stepi $n");
        my $r = `$^X -Iblib/lib -Iblib/arch $lib check $dir $CAP '$o->{call}' 2>&1`;
        my ($res) = $r =~ /RESULT (.*)/;
        $res //= "no result: $r";
        $seen{$1}++ if $res =~ /\b(pre|post|torn)\b/;
        push @bad, "stepi $n: $res" unless $k =~ /Breakpoint 1[,.]/
            && $res =~ /^held=1 (?:pre|post) card_ok=1 free=(\d+) want=\1$/;
    }
    ok(!@bad, sprintf "%s: %d kills inside the rewrite left it whole (pre %d, post %d)",
        $name, scalar keys %n, $seen{pre} // 0, $seen{post} // 0)
        or diag join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)];
}

done_testing;
