use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Time::HiRes qw(time);

use Data::HashMap::Shared::SS;

# get() is lock-free and consistent only because of the seqlock: a writer flips
# hdr->seq odd before it touches an entry and even after, and a reader that saw
# the sequence move re-reads.  Without write_begin a section can hand a reader a
# record mid-rewrite, and an odd number of sections leaves the sequence odd for
# good, where read_begin spins forever -- nobody holds wlock, so stale-lock
# recovery never fires.  Two alarm-bounded detectors, so either outcome fails an
# assertion:
#  - the tear: readers hammer get() on a key a writer keeps rewriting.  Every
#    value names its key and its round and repeats a round-derived byte to the
#    end, so a recycled block's free-list link, the interim inline-empty state,
#    or a mix of two generations fails a field check;
#  - the spin: after the writer stops, a probe child does one get() under a
#    no-handler alarm, once before and once after a single put() flips the
#    parity.  A stuck-odd sequence kills exactly one probe with SIGALRM.
# A Perl-level $SIG{ALRM} cannot interrupt a get() that never returns to Perl,
# so every read that could spin runs in a child with the default disposition and
# the parent only judges exit statuses.

use constant {
    VLEN    => 256,       # > 7 bytes: an arena block
    HEAD    => 18,        # "KKKKKKKK|RRRRRRRR|"
    READERS => 3,
    READS   => 50_000,    # per reader
    # One key, so every read targets the entry being rewritten, and a TTL, so
    # the expiry check sits inside the reader's window: together they raise
    # the observed tear rate from a handful per run to hundreds.
    TTL     => 3600,
};

my $key  = 'k0000000';
my @FILL = map { chr(97 + $_) x (VLEN - HEAD) } 0 .. 25;

sub val_for { sprintf('%s|%08d|', $_[0], $_[1]) . $FILL[$_[1] % 26] }

# undef when $v is exactly some round's value for $k, else the field that broke
sub torn {
    my ($k, $v) = @_;
    return 'undef'                     unless defined $v;
    return 'length ' . length $v       unless length($v) == VLEN;
    return 'key'                       unless substr($v, 0, 8) eq $k;
    my $r = substr($v, 9, 8);
    return 'round'                     unless $r =~ /\A[0-9]{8}\z/;
    return 'fill'                      unless substr($v, HEAD) eq $FILL[$r % 26];
    return undef;
}

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/seqlock.shm";
my @args = ($path, 1024, 0, TTL);
my $map  = Data::HashMap::Shared::SS->new(@args);
$map->put($key, val_for($key, 0));

pipe(my $go_rd,   my $go_wr)   or die "pipe: $!";
pipe(my $stop_rd, my $stop_wr) or die "pipe: $!";
pipe(my $res_rd,  my $res_wr)  or die "pipe: $!";

my @pids;

my $writer = fork;
die "fork: $!" unless defined $writer;
if ($writer == 0) {
    close $_ for $go_wr, $stop_wr, $res_rd;
    alarm 30;                         # an orphaned writer ends itself
    my $m = Data::HashMap::Shared::SS->new(@args);
    my $go;
    sysread($go_rd, $go, 1);
    my $rin = '';
    vec($rin, fileno($stop_rd), 1) = 1;
    my $round = 1;
    until (select(my $rout = $rin, undef, undef, 0)) {
        $m->put($key, val_for($key, $round));
        $round++;
    }
    syswrite($res_wr, "writer rounds=$round\n");
    POSIX::_exit(0);
}
push @pids, $writer;

for my $r (0 .. READERS - 1) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $_ for $go_wr, $stop_rd, $stop_wr, $res_rd;
        alarm 30;                     # a wedged get() fails the test, never hangs it
        my $m = Data::HashMap::Shared::SS->new(@args);
        my $go;
        sysread($go_rd, $go, 1);
        my (%kind, $sample);
        my $t0 = time;
        for (1 .. READS) {
            my $v   = $m->get($key);
            my $why = torn($key, $v);
            next unless $why;
            $kind{$why}++;
            $sample //= sprintf '%s: %s', $why,
                join '', map { sprintf '%02x', ord } split //, substr($v // '', 0, 24);
        }
        my $secs  = time - $t0;
        my $tears = 0;
        $tears += $_ for values %kind;
        syswrite($res_wr, sprintf "reader %d reads=%d secs=%.2f tears=%d kinds=%s sample=%s\n",
            $r, READS, $secs, $tears,
            join(',', map { "$_:$kind{$_}" } sort keys %kind) || '-',
            $sample // '-');
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
close $_ for $go_rd, $stop_rd, $res_wr;

local $SIG{ALRM} = sub {
    kill 'KILL', @pids;
    die "seqlock probe exceeded its time budget\n";
};
# a writer that died early leaves nobody reading the stop pipe; its status is
# asserted below, so do not let SIGPIPE kill the report first
local $SIG{PIPE} = 'IGNORE';
alarm 60;

syswrite($go_wr, 'g' x @pids) == @pids or die "barrier release: $!";
close $go_wr;

my ($crashed, $failed) = (0, 0);
for my $pid (@pids[1 .. $#pids]) {
    waitpid($pid, 0);
    if    ($? & 127) { $crashed++ }
    elsif ($? >> 8)  { $failed++ }
}
syswrite($stop_wr, 's');
close $stop_wr;
waitpid($writer, 0);
my $writer_status = $?;
alarm 0;

my @report = <$res_rd>;
close $res_rd;
chomp @report;
diag $_ for @report;

is($crashed, 0, "no reader died on a signal");
is($failed,  0, "no reader exited with an error");
is($writer_status, 0, "the writer exited cleanly when told to stop");

my ($rounds) = map { /^writer rounds=(\d+)/ ? $1 : () } @report;
cmp_ok($rounds // 0, '>', 1, "the writer rewrote the key during the race");

my ($reads, $tears, %kinds) = (0, 0);
for (@report) {
    next unless /^reader \d+ reads=(\d+) .*?tears=(\d+) kinds=(\S+)/;
    $reads += $1;
    $tears += $2;
    $kinds{$_}++ for map { s/:\d+\z//r } grep { $_ ne '-' } split /,/, $3;
}
is($reads, READERS * READS, "every reader reported its full read count");
is($tears, 0, sprintf "every get() returned a record consistent with its key and round (%d reads, %d torn%s)",
    $reads, $tears, %kinds ? ': ' . join(', ', sort keys %kinds) : '');

# The spin.  One get() in a child under a no-handler alarm: a sequence left
# odd never returns and the child dies of SIGALRM, which is a status, not a
# stall.  The put() between the two probes flips the parity, so a no-op
# write_begin is caught whichever parity the race happened to end on.
sub probe_get {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    push @pids, $pid if $pid;       # the parent's alarm handler must reach a stuck probe too
    if ($pid == 0) {
        $SIG{ALRM} = 'DEFAULT';     # inherited Perl-level handler: XS would never return to run it
        alarm 3;
        my $v = $map->get($key);
        POSIX::_exit(torn($key, $v) ? 2 : 0);
    }
    waitpid($pid, 0);
    return $? & 127 ? "killed by signal " . ($? & 127) : $? >> 8 ? "torn (exit " . ($? >> 8) . ")" : 'ok';
}

alarm 30;
my $before = probe_get();
$map->put($key, val_for($key, 0));
my $after = probe_get();
alarm 0;

is($before, 'ok', "a lock-free get() after the writer stopped returned within its alarm");
is($after,  'ok', "a lock-free get() after one more write (parity flipped) returned within its alarm");

done_testing;
