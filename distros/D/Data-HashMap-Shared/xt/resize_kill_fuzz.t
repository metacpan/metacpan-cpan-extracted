use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use File::Temp qw(tempdir);
use File::Copy qw(copy);

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};

# xt/resize_crash_gdb.t kills a resizing writer at chosen lines.  This kills it
# with SIGKILL at a random moment of the resize instead, then kills up to two of
# the processes finishing that resize the same way, and checks the map the next
# process sees against what the writer was given: every entry, its value, its
# TTL and its LRU position, and a table with no record, no leftover mark and
# nothing above its capacity.

my $dir = tempdir(CLEANUP => 1);
my @inc = map { "-I$_" } @INC;

my $common = <<'EOF';
use strict; use warnings;
use Time::HiRes qw(time);
my ($file, $cls, $lru, $ttl, @rest) = @ARGV;
eval "require Data::HashMap::Shared::$cls; 1" or die $@;
# a table of at most 2**18 slots
my $m = "Data::HashMap::Shared::$cls"->new($file, 196_607, $lru ? 196_607 : 0, $ttl);
my $key = $cls =~ /^S/ ? sub { "key$_[0]" . ('k' x ($_[0] % 9)) } : sub { $_[0] * 7919 };
my $val = $cls =~ /S$/ ? sub { "val$_[0]" . ('v' x ($_[0] % 23)) } : sub { $_[0] * 31 - 5 };
my @sentinel = ($cls =~ /^S/ ? 'sentinel' : 4_000_000_001, $cls =~ /S$/ ? 'sv' : 77);
$| = 1;
EOF

# Builds the map a scenario starts from, the manifest of what it must still
# hold afterwards, and the argument of the operation that resizes it.
my $setup = "$dir/setup.pl";
write_script($setup, <<'EOF');
my ($scen, $n, $manifest) = @rest;
my $began = time;                           # no entry's TTL started before this
for (0 .. $n - 1) {
    ($ttl ? $m->put_ttl($key->($_), $val->($_), 1000 + $_ % 700) : $m->put($key->($_), $val->($_))) or die "put $_";
}
my $cap = $m->capacity;
my (%gone, $arg);
if ($scen eq 'grow') {                      # tombstones for the grow to clear
    for my $i (grep { $_ % 7 == 3 } 0 .. $n - 1) { $m->remove($key->($i)) or die; $gone{$i} = 1 }
    $arg = int($cap * 3 / 4) + 1;
} elsif ($scen eq 'shrink') {               # the next remove shrinks the table
    for my $i ((grep { $_ % 2 } 0 .. $n - 1), (grep { !($_ % 2) } 0 .. $n - 1)) {
        if ($m->size * 4 <= $cap) { $arg = $key->($i); $gone{$i} = 1; last }
        $m->remove($key->($i)) or die; $gone{$i} = 1;
    }
} else {                                    # at the maximum capacity: the next put compacts
    for my $i (grep { !($_ % 2) } 0 .. $n - 1) { $m->remove($key->($i)) or die; $gone{$i} = 1 }
    $arg = 'put';
}
open my $f, '>', $manifest or die $!;
printf $f "%s\t%s\t%d\t%d\n", $key->($_), $val->($_), 1000 + $_ % 700, $began for grep { !$gone{$_} } 0 .. $n - 1;
close $f;
print "$arg\n";
EOF

# Says "go", then resizes.
my $victim = "$dir/victim.pl";
write_script($victim, <<'EOF');
my ($scen, $arg) = @rest;
print "go\n";
my $t = time;
if    ($scen eq 'grow')   { $m->reserve($arg) or die 'reserve' }
elsif ($scen eq 'shrink') { $m->remove($arg) or die 'remove' }
else                      { $m->put(@sentinel) or die 'put' }
printf "done %.6f\n", time - $t;
EOF

# Says "go", then takes a lock, which finishes a dead writer's resize first.
my $recover = "$dir/recover.pl";
write_script($recover, <<'EOF');
my ($mode) = @rest;
print "go\n";
if ($mode eq 'keys') { my @k = $m->keys } else { $m->put(@sentinel) or die 'put' }
print "done\n";
EOF

my $check = "$dir/check.pl";
write_script($check, <<'EOF');
my ($manifest, $optional) = @rest;
my %have = map { $_ => 1 } $m->keys;
my (@want, %want);
open my $f, '<', $manifest or die $!;
while (<$f>) { chomp; my @r = split /\t/; push @want, $r[0]; $want{$r[0]} = \@r }
my %extra_ok = map { $_ => 1 } $sentinel[0], grep { length } $optional // '';
my ($missing, $badval, $badttl) = (0, 0, 0);
for my $k (@want) {
    my $v = $m->get($k);
    if (!defined $v || !$have{$k}) { $missing++; next }
    $badval++ if $v ne $want{$k}[1];
    next unless $ttl;
    my $r = $m->ttl_remaining($k);
    $badttl++ unless defined $r && $r <= $want{$k}[2] && $r >= $want{$k}[2] - (time - $want{$k}[3]) - 2;
}
my $extra = grep { !$want{$_} && !$extra_ok{$_} } keys %have;
my $listed = keys %have;
my $size = $m->size;

# the table itself, once that recovery has run: header offsets 16 max_table_cap,
# 20 table_cap, 48 states_off, 99 rz_phase, 140 tombstones
open my $fh, '<:raw', $file or die $!;
sysread($fh, my $hdr, 256) == 256 or die 'header';
my ($maxcap, $cap) = unpack 'x16 L L', $hdr;
sysseek $fh, unpack('x48 Q', $hdr), 0 or die $!;
sysread($fh, my $st, $maxcap) == $maxcap or die 'states';
my $marks = substr($st, 0, $cap) =~ tr/\x01//;
my $above = substr($st, $cap) =~ tr/\x00//c;

my $order = 'n/a';
if ($lru) {                                 # pop takes the LRU tail: insertion order
    my @popped;
    while (my ($k) = $m->pop) { push @popped, $k unless $extra_ok{$k} }
    $order = "@popped" eq "@want" ? 'ok' : 'bad';
}
printf "missing=%d badval=%d badttl=%d extra=%d size-listed=%d record=%d marks-tombstones=%d above=%d lru=%s\n",
    $missing, $badval, $badttl, $extra, $size - $listed, unpack('x99 C', $hdr),
    $marks - unpack('x140 L', $hdr), $above, $order;
EOF

sub write_script {
    my ($path, $body) = @_;
    open my $f, '>', $path or die "$path: $!";
    print $f $common, $body;
    close $f or die $!;
}

# Start a script, wait for its "go", and SIGKILL it $delay seconds later, or
# let it finish when $delay is undef.  Returns its output after the "go".
sub run_and_kill {
    my ($delay, @cmd) = @_;
    my $pid = open my $out, '-|', $^X, @inc, @cmd or die "fork: $!";
    my $go = <$out>;
    die "no go from @cmd: " . ($go // 'EOF') unless defined $go && $go eq "go\n";
    if (defined $delay) { sleep $delay if $delay > 0; kill KILL => $pid }
    my $rest = do { local $/; <$out> } // '';
    close $out;
    return $rest;
}

sub header { open my $f, '<:raw', $_[0] or die $!; sysread $f, my $h, 256; $h }

my $landed = 0;
for my $config ([ SS => 'grow', 1 ], [ SS => 'shrink', 1 ], [ SS => 'compact', 1 ],
                [ II => 'grow', 0 ], [ II => 'shrink', 0 ], [ II => 'compact', 0 ]) {
    my ($cls, $scen, $cache) = @$config;
    my @map = ($cls, $cache, $cache ? 3600 : 0);        # SS with LRU and TTL, II without
    my ($tmpl, $man, $trial) = map { "$dir/$cls-$scen.$_" } qw(tmpl man shm);
    my $n = $scen eq 'compact' ? 190_000 : 60_000;
    chomp(my $arg = `$^X @inc $setup $tmpl @map $scen $n $man`);
    is $?, 0, "$cls $scen: built the map" or next;
    my $optional = $scen eq 'shrink' ? $arg : '';       # the kill may come before its remove

    copy($tmpl, $trial) or die "copy: $!";
    my ($took) = run_and_kill(undef, $victim, $trial, @map, $scen, $arg) =~ /^done ([\d.]+)/m
        or die 'the victim did not finish';
    my (@bad, $in_resize);
    for my $t (1 .. 12) {
        copy($tmpl, $trial) or die "copy: $!";
        run_and_kill(rand($took * 1.15), $victim, $trial, @map, $scen, $arg);
        $in_resize++ if unpack 'x99 C', header($trial);
        for (1 .. int rand 3) {
            run_and_kill(rand($took * 1.15), $recover, $trial, @map, rand() < 0.5 ? 'keys' : 'put');
            $in_resize++ if unpack 'x99 C', header($trial);
        }
        chomp(my $state = `$^X @inc $check $trial @map $man '$optional' 2>&1`);
        push @bad, "trial $t: $state"
            unless $state =~ /^missing=0 badval=0 badttl=0 extra=0 size-listed=0 record=0 marks-tombstones=0 above=0 lru=(ok|n\/a)$/;
    }
    is scalar(@bad), 0, "$cls $scen: 12 random kills, each with up to two killed recoveries, leave the map whole"
        or diag join "\n", @bad;
    $landed += $in_resize // 0;
}
ok $landed, "$landed kills landed inside a resize"
    or diag 'no kill landed inside a resize: these trials proved nothing';
done_testing;
