use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Basename qw(dirname);

# clear() empties the table under a record in the header.  Kill the clearing
# writer with gdb before the record, inside the pass that empties the states
# and at each store after it -- and kill the process finishing it too -- then
# check that the next process sees the map whole or empty, never in between,
# and can use it.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'MANIFEST';
my $probe = `$gdb -batch -ex run --args /bin/true 2>&1`;
plan skip_all => 'gdb cannot run a process here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my $src = do { open my $f, '<', 'shm_generic.h' or die $!; [<$f>] };
sub anchor {                      # line of the first $re after the line matching $fn
    my ($fn, $re) = @_;
    my $in = 0;
    for my $i (0 .. $#$src) {
        $in ||= $src->[$i] =~ $fn;
        return $i + 1 if $in && $src->[$i] =~ $re;
    }
    return;
}

my $CLEAR = qr/^static void SHM_FN\(clear\)/;
my $RUN   = qr/^static void shm_clear_run\(ShmHandle \*h\) \{/;
# [label, line, what the next process must find, % of the table for the watched state]
my @anchors = map { [ $_->[0], scalar anchor(@$_[1, 2]), @$_[3, 4] ] } (
    [ 'record',       $CLEAR, qr/rz_phase, SHM_RZ_CLEAR,/,                        'whole' ],
    [ 'states pass',  $RUN,   qr/ShmHeader \*hdr = h->hdr;/,                      'empty', [10, 50, 90] ],
    [ 'states empty', $RUN,   qr/hdr->size = 0;/,                                 'empty' ],
    [ 'arena',        $RUN,   qr/shm_arena_reset\(hdr\);/,                        'empty' ],
    [ 'generation',   $RUN,   qr/hdr->table_gen\+\+;/,                            'empty' ],
    [ 'record clear', $RUN,   qr/rz_phase, SHM_RZ_NONE,/,                         'empty' ],
);
my @lost = map { $_->[0] } grep { !defined $_->[1] } @anchors;
ok !@lost, 'located every clear breakpoint: ' . join ', ', map { "$_->[0]=" . ($_->[1] // '?') } @anchors
    or BAIL_OUT("no line in shm_generic.h for: @lost");

# A debug build in a scratch copy, so blib is left alone.
my $dir = tempdir(CLEANUP => 1);
my $bld = "$dir/build";
{
    open my $m, '<', 'MANIFEST' or die $!;
    while (<$m>) {
        my ($f) = split ' ';
        next unless defined $f && -f $f && $f !~ m{^(t|xt|eg|bench)/};
        make_path(dirname("$bld/$f"));
        copy($f, "$bld/$f") or die "copy $f: $!";
    }
}
my $out = `cd $bld && $^X Makefile.PL 2>&1 && make OPTIMIZE='-O2 -g' 2>&1`;
is $?, 0, '-O2 -g build' or BAIL_OUT("build failed:\n$out");
my @inc = ("-I$bld/blib/lib", "-I$bld/blib/arch");

my $common = <<'EOF';
use strict; use warnings;
my ($path, $cls, $manifest, $recover) = @ARGV;
eval "require Data::HashMap::Shared::$cls; 1" or die $@;
my $m = "Data::HashMap::Shared::$cls"->new($path, 8000, $cls eq 'SS' ? 8000 : 0, 3600);
my $key = $cls eq 'SS' ? sub { "key$_[0]" . ('k' x ($_[0] % 9)) } : sub { $_[0] * 7919 };
my $val = $cls eq 'SS' ? sub { "val$_[0]" . ('v' x ($_[0] % 23)) } : sub { $_[0] * 31 - 5 };
EOF

my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v $common, <<'EOF';
$m->put($key->($_), $val->($_)) or die "put $_" for 0 .. 999;
open my $f, '>', $manifest or die $!;
print $f $key->($_), "\t", $val->($_), "\n" for 0 .. 999;
close $f;
my $ppid = getppid();                   # gdb arms the breakpoint here
$m->clear;
EOF
close $v;

my $check = "$dir/check.pl";
open my $c, '>', $check or die $!;
print $c $common, <<'EOF';
if ($recover) { my $ppid = getppid(); my @k = $m->keys; exit 0 }
my %want;
open my $f, '<', $manifest or die $!;
while (<$f>) { chomp; my ($k, $v) = split /\t/; $want{$k} = $v }
my @keys = $m->keys;
my $present = grep { ($m->get($_) // "\0") eq $want{$_} } keys %want;
my $extra = grep { !exists $want{$_} } @keys;
my $size = $m->size;
my @new = map { $key->($_) } 5000 .. 5049;
my $stored = grep { $m->put($new[$_], $val->($_)) } 0 .. $#new;
my $back = grep { ($m->get($new[$_]) // "\0") eq $val->($_) } 0 .. $#new;
my $listed = () = $m->keys;
my $usable = $stored == 50 && $back == 50 && $m->size == $size + 50 && $listed == $size + 50;
printf "n=%d listed=%d present=%d extra=%d size=%d usable=%s\n",
    scalar(keys %want), scalar(@keys), $present, $extra, $size, $usable ? 'ok' : 'no';
EOF
close $c;

# Run a script under gdb and kill it at a line or, inside the states pass, once
# that pass rewrites the first live state at p% of the table.
sub gdb_run {
    my ($tag, $a, $p, @args) = @_;
    my (undef, $line, undef, $watch) = @$a;
    my $cmds = "$dir/$tag.gdb";
    open my $g, '>', $cmds or die $!;
    print $g "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "catch syscall getppid\nrun\ndelete 1\nbreak shm_generic.h:$line\ncontinue\n";
    print $g "delete 2\nset \$st = (unsigned char *) h->states\nset \$n = h->hdr->table_cap\n",
             "set \$k = \$n * $p / 100\nwhile \$k < \$n && \$st[\$k] < 2\nset \$k = \$k + 1\nend\n",
             "if \$k < \$n\nwatch -l \$st[\$k]\ncontinue\nend\n" if $watch;
    print $g "kill\nquit\n";
    close $g;
    my $log = `ulimit -v 1500000; $gdb -batch -x $cmds --args $^X @inc @args 2>&1`;
    return $log =~ ($watch ? qr/New value/ : qr/Breakpoint 2[,.]/) ? 1 : 0;
}

sub state_of {
    my ($map, $cls, $man) = @_;
    my $s = `$^X @inc $check $map $cls $man 2>&1`;
    chomp $s;
    return $s;
}

my %shape = (
    whole => qr/^n=1000 listed=1000 present=1000 extra=0 size=1000 usable=ok$/,
    empty => qr/^n=1000 listed=0 present=0 extra=0 size=0 usable=ok$/,
);

my ($runs, %reached) = (0);
for my $a (@anchors) {
    for my $cls (qw(II SS)) {
        next if $cls eq 'II' && $a->[0] eq 'arena';
        for my $p (@{ $a->[3] // [0] }) {
            my $tag = "c$runs"; $runs++;
            my ($map, $man) = ("$dir/$tag.shm", "$dir/$tag.man");
            my $hit = gdb_run($tag, $a, $p, $victim, $map, $cls, $man);
            $reached{$a->[0]} ||= $hit;
            like state_of($map, $cls, $man), $shape{ $hit ? $a->[2] : 'empty' },
                "$cls, killed at $a->[0]" . ($a->[3] ? " at $p%" : '') . ($hit ? '' : ', not reached')
                . ': the map is ' . ($hit ? $a->[2] : 'empty');
        }
    }
}
ok $reached{$_->[0]}, "$_->[0] is reached" for @anchors;

# The process finishing a dead writer's clear dies inside it too.
my ($pass) = grep { $_->[0] eq 'states pass' } @anchors;
for my $cls (qw(II SS)) {
    my $tag = "cc$runs"; $runs++;
    my ($map, $man) = ("$dir/$tag.shm", "$dir/$tag.man");
    my $h1 = gdb_run("$tag.a", $pass, 50, $victim, $map, $cls, $man);
    my $h2 = gdb_run("$tag.b", $pass, 75, $check, $map, $cls, $man, 1);
    ok $h1 && $h2, "$cls: the writer and then its recoverer are killed inside the states pass";
    like state_of($map, $cls, $man), $shape{empty}, '  ... and the next process finds the map empty';
}
done_testing;
