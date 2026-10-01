use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use Data::TopK::Shared;

# A writer killed between claiming or rewriting a counter and indexing it, or
# mid clear, must not leave a counter no key reaches.  gdb single-steps one add
# (an eviction, or a warm-up insert) or clear through this module's code,
# copying the backing file at every state change; each copy is then opened
# (which recovers the dead writer's lock), keys are added again, and top() must
# list each key once.

my $gdb = `command -v gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'topk.h' && -d 'blib';
my $probe = `$gdb -batch -ex 'python print(6*7)' -ex run --args $^X -e 1 2>&1`;
plan skip_all => 'gdb without python' unless $probe =~ /^42$/m;
plan skip_all => 'ptrace unavailable' unless $probe =~ /exited normally/;

my $dir = tempdir(CLEANUP => 1);
my ($CAP, $KS) = (15, 8);

open my $v, '>', "$dir/victim.pl" or die $!;
print $v <<'EOF';
use strict; use warnings;
use Data::TopK::Shared;
my ($path, $cap, $ks, $key, $hl, $ts) = @ARGV;
my $tk = $hl ? Data::TopK::Shared->new_decayed($path, $cap, $ks, $hl)
             : Data::TopK::Shared->new($path, $cap, $ks);
$key eq 'CLEAR' ? $tk->clear : $tk->add($key, defined $ts ? $ts : ());
EOF
close $v;

# Steps into calls that stay inside the XS module and over everything else.
open my $py, '>', "$dir/step.py" or die $!;
print $py <<'EOF';
import gdb, os, re
xs, file, snaps = os.environ['SK_XS'], os.environ['SK_FILE'], os.environ['SK_SNAPS']
gdb.execute('set pagination off')
gdb.execute('set confirm off')
gdb.execute('set breakpoint pending on')
gdb.execute('break ' + xs)
gdb.execute('run')
pc = lambda: int(gdb.parse_and_eval('$pc'))
so = gdb.solib_name(pc())
last = open(file, 'rb').read()
n = 0
while n < 50000 and gdb.solib_name(pc()) == so:
    asm = gdb.selected_frame().architecture().disassemble(pc())[0]['asm']
    m = re.match(r'call\w*\s+(0x[0-9a-f]+)', asm)
    into = m and '@plt' not in asm and gdb.solib_name(int(m.group(1), 16)) == so
    gdb.execute('stepi' if into else 'nexti', to_string=True)
    cur = open(file, 'rb').read()
    if cur != last:
        open('%s/s.%05d' % (snaps, n), 'wb').write(cur)
        last = cur
    n += 1
print('stepped %d' % n)
gdb.execute('kill')
EOF
close $py;

sub snapshots {
    my ($name, $key, $sym, @decay) = @_;
    my $file = "$dir/$name.tk";
    my $snaps = "$dir/$name.snap";
    mkdir $snaps or die $!;
    local @ENV{qw(SK_XS SK_FILE SK_SNAPS)} = ($sym, $file, $snaps);
    my $log = `ulimit -v 1500000; timeout 600 $gdb -batch -x $dir/step.py --args $^X -Iblib/lib -Iblib/arch $dir/victim.pl $file $CAP $KS $key @decay 2>&1`;
    like $log, qr/Breakpoint 1, .*\n(?s:.*)stepped \d+/, "$name: gdb stepped $sym" or diag $log;
    opendir my $d, $snaps or die $!;
    return map { "$snaps/$_" } sort grep { /^s\./ } readdir $d;
}

sub seed {
    my ($name, $n, $times) = @_;
    my $tk = Data::TopK::Shared->new("$dir/$name.tk", $CAP, $KS);
    for my $r (1 .. $times) { $tk->add("k$_") for 1 .. $n }
}

# recover a copy of the snapshot, add @keys, and report any key top() lists
# twice or whose count - error claims more sightings than it can have had
sub dups {
    my ($snap, @keys) = @_;
    copy($snap, "$snap.d") or die $!;
    my $tk = Data::TopK::Shared->new("$snap.d", $CAP, $KS);
    $tk->add($_) for @keys;
    my %n; $n{$_->{key}}++ for $tk->top;
    my @d = grep { $n{$_} > 1 } sort keys %n;
    return "duplicate keys in top(): @d" if @d;
    for my $k (@keys) {
        my $most = 3 * ($k =~ /^k\d+$/) + (grep { $_ eq $k } @keys) + 1;   # seeded, re-added, the victim's
        my $low = $tk->estimate($k) - $tk->error($k);
        return "$k: count - error = $low > $most" if $low > $most;
    }
    return 'ok';
}

# [name, keys seeded, what the victim does, its XS entry, keys added after recovery]
for my $case (['evict',   $CAP,     'fresh', 'add',   'fresh', 'fresh'],
              ['insert',  $CAP - 1, 'fresh', 'add',   'fresh', 'fresh'],
              ['insert5', $CAP - 5, 'fresh', 'add',   'fresh', 'fresh'],
              ['clear',   $CAP,     'CLEAR', 'clear', 'k1', 'k2', 'k3']) {
    my ($name, $n, $key, $xs, @readd) = @$case;
    seed($name, $n, 3);
    my @s = snapshots($name, $key, "XS_Data__TopK__Shared_$xs");
    my @bad = grep { $_->[1] ne 'ok' } map { [$_, dups($_, @readd)] } @s;
    ok !@bad, "$name: no killed state yields a duplicate key or an overclaimed count (" . @s . ' states)'
        or diag join "\n", map { "$_->[0]: $_->[1]" } @bad[0 .. ($#bad < 4 ? $#bad : 4)];
}

# An evicted counter torn mid-copy into "ab" must not take over the real "ab"'s count.
{
    my $tk = Data::TopK::Shared->new("$dir/prefix.tk", $CAP, $KS);
    for my $k ('ab', map { "p$_" } 1 .. $CAP - 2) { $tk->add($k) for 1 .. 5 }
    $tk->add('xy') for 1 .. 3;
}
my @s = snapshots('prefix', 'abc', 'XS_Data__TopK__Shared_add');
my @bad;
for my $s (@s) {
    copy($s, "$s.d") or die $!;
    my $est = Data::TopK::Shared->new("$s.d", $CAP, $KS)->estimate('ab');
    push @bad, "$s: estimate(ab) = $est, below its 5 sightings" if $est < 5;
}
ok !@bad, 'prefix: a torn key spelling a monitored key does not understate it (' . @s . ' states)'
    or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];

# The same with equal counts and the torn counter in the lower slot: the real "ab" keeps the index.
{
    my $tk = Data::TopK::Shared->new("$dir/tie.tk", $CAP, $KS);
    $tk->add($_) for 'xy', 'ab';
    for my $k (map { "p$_" } 1 .. $CAP - 2) { $tk->add($k) for 1 .. 5 }
}
@s = snapshots('tie', 'abc', 'XS_Data__TopK__Shared_add');
@bad = ();
for my $s (@s) {
    copy($s, "$s.d") or die $!;
    my $tk = Data::TopK::Shared->new("$s.d", $CAP, $KS);
    $tk->add('ab');
    my ($est, $err) = ($tk->estimate('ab'), $tk->error('ab'));
    push @bad, "$s: ab count $est error $err, want 2 and 0" unless $est == 2 && $err == 0;
}
ok !@bad, 'tie: the real counter, not the torn one, keeps the key (' . @s . ' states)'
    or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];

# Decayed weights all 0 after a long gap: the torn "ab" at the root ties the real one,
# which must keep the key once the next eviction removes the torn counter.
{
    my $tk = Data::TopK::Shared->new_decayed("$dir/zero.tk", $CAP, $KS, 1);
    $tk->add('xy', 1);
    for my $k ('p1', 'p2', 'ab', map { "p$_" } 3 .. $CAP - 2) { $tk->add($k, 1) for 1 .. 5 }
}
@s = snapshots('zero', 'abc', 'XS_Data__TopK__Shared_add', 1, 1e6);
@bad = ();
for my $s (@s) {
    copy($s, "$s.d") or die $!;
    my $tk = Data::TopK::Shared->new_decayed("$s.d", $CAP, $KS, 1);
    $tk->add($_, 1e6) for 'abd', 'ab';
    my $n = grep { $_->{key} eq 'ab' } $tk->top;
    push @bad, "$s: top() lists ab $n times" unless $n == 1;
}
ok !@bad, 'zero: the real counter keeps the key in a tie of fully decayed weights (' . @s . ' states)'
    or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];
done_testing;
