use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);

# A writer killed between two stores of one mutation leaves the chains, free
# list or count torn.  Stop it at exactly such a boundary with gdb, kill it, and
# check that the next process -- whose lock call recovers the dead writer's
# lock -- sees a consistent map: every live entry reachable, count right, free
# list complete.  The last case also kills the recovering process mid-rebuild.

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
chomp(my $gdb = `command -v gdb 2>/dev/null`);
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'sphash.h' && -f 'Makefile.PL';

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
    open my $fh, '<', 'sphash.h' or die $!;
    my $in = 0;
    while (<$fh>) {
        $in = 1 if /^static\b.*\b\Q$fn\E\(/;
        return $. if $in && /\Q$pat\E/;
    }
    return;
}

my ($MAX, $LIVE) = (64, 40);
my $victim = "$dir/victim.pl";
open my $v, '>', $victim or die $!;
print $v <<'EOF';
use strict; use warnings; use Data::SpatialHash::Shared;
my ($path, $op) = @ARGV;
my $s = Data::SpatialHash::Shared->new($path, 64, 0, 1.0);
if ($op eq 'recover') { my @r = $s->query_aabb(-1, -1, 301, 101); exit 0 }
my @h = map { $s->insert($_ + 0.5, 0.5, $_) } 0 .. 39;
if    ($op eq 'move')   { $s->move($h[$_], 100.5 + $_, 50.5) for 0 .. 9 }
elsif ($op eq 'remove') { $s->remove($h[$_]) for 0 .. 9 }
elsif ($op eq 'insert') { $s->insert(200.5 + $_, 0.5, 1000 + $_) for 0 .. 9 }
elsif ($op eq 'clear')  { $s->clear }
EOF
close $v;

sub run_gdb {
    my ($path, $op, $line, $ignore) = @_;
    my $cmds = "$dir/cmds";
    open my $c, '>', $cmds or die $!;
    print $c "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "set debuginfod enabled off\nbreak sphash.h:$line\n",
             ($ignore ? "ignore 1 $ignore\n" : ''), "run\nkill\nquit\n";
    close $c;
    my $log = `ulimit -v 1500000; timeout 300 $gdb -nx -batch -x $cmds --args $^X @inc $victim $path $op 2>&1`;
    return $log =~ /Breakpoint 1[,.]/;
}

sub check {
    my ($path) = @_;
    my $out = `timeout 120 $^X @inc -MData::SpatialHash::Shared -e '
        my \$s = Data::SpatialHash::Shared->new(q{$path}, $MAX, 0, 1.0);
        my \@all = \$s->query_aabb(-1, -1, 301, 101);
        my \$n = \$s->count;
        my \%seen; my \$dup = grep { \$seen{\$_}++ } \@all;
        my \$free = 0;
        \$free++ while \$free <= $MAX && defined \$s->insert(0.5, 0.5, -1);
        print "count=\$n reach=", scalar(\@all), " dup=\$dup free=\$free\n";
    ' 2>&1`;
    chomp $out;
    return $out;
}

sub consistent {
    my ($st) = @_;
    my ($n, $r, $d, $f) = $st =~ /count=(\d+) reach=(\d+) dup=(\d+) free=(\d+)/ or return 0;
    return $n == $r && $d == 0 && $n + $f == $MAX;
}

my @cases = (
    [ 'move: unlinked, not relinked',     'move',   'sph_move_locked',   'sph_bucket_link(h, idx);', 0 ],
    [ 'move: 5th move, same point',       'move',   'sph_move_locked',   'sph_bucket_link(h, idx);', 4 ],
    [ 'remove: freed, head not updated',  'remove', 'sph_free_slot',     'h->hdr->free_head = idx;', 0 ],
    [ 'insert: linked, not yet live',     'insert', 'sph_insert_locked', 'h->bitmap[idx / 64] |=',   $LIVE ],
    [ 'clear: buckets emptied only',      'clear',  'sph_clear_locked',  'memset(h->bitmap',         0 ],
    [ 'clear: bitmap zeroed, stale head', 'clear',  'sph_clear_locked',  'h->hdr->free_head = 0;',   0 ],
);

my $k = 0;
for my $case (@cases) {
    my ($name, $op, $fn, $pat, $ignore) = @$case;
    my $line = line_in($fn, $pat);
    ok $line, "$name: anchored at sphash.h:" . ($line // '?') or next;
    my $path = "$dir/m" . $k++ . '.sph';
    ok run_gdb($path, $op, $line, $ignore), "$name: writer stopped there and killed";
    my $st = check($path);
    ok consistent($st), "$name: next process sees a consistent map" or diag $st;
}

{
    my $name = 'recovery killed mid-rebuild';
    my $path = "$dir/m" . $k++ . '.sph';
    my $l1 = line_in('sph_move_locked', 'sph_bucket_link(h, idx);');
    my $l2 = line_in('sph_rebuild_locked', 'h->hdr->free_head = head;');
    ok $l1 && $l2, "$name: anchored" or diag 'no sph_rebuild_locked';
    ok run_gdb($path, 'move', $l1, 0), "$name: writer killed mid-move";
    ok $l2 && run_gdb($path, 'recover', $l2, 0), "$name: recovering process killed mid-rebuild";
    my $st = check($path);
    ok consistent($st), "$name: third process sees a consistent map" or diag $st;
}

done_testing;
