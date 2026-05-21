use Test2::V0;
use Atomic::Pipe;
use POSIX qw/mkfifo/;
use File::Temp qw/tempdir/;
use Fcntl ();
use Errno qw/EPERM ENOMEM EBUSY EINVAL/;

skip_all("F_SETPIPE_SZ not available") unless defined &Fcntl::F_SETPIPE_SZ;

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/fifo";
mkfifo($f, 0700) or die "mkfifo: $!";

my $p = Atomic::Pipe->read_fifo($f);

my $before = $p->size;
my $max    = $p->max_size;

skip_all("kernel cap matches default; resize is a no-op")
    if $before >= $max;

my $ret = $p->resize_or_max($max);

# Per-user pipe page budget (fs.pipe-user-pages-soft) can deny F_SETPIPE_SZ
# with EPERM/ENOMEM when the user already has many large pipes open. That's
# environmental, not a bug in resize_or_max, so skip rather than fail.
if (!defined $ret && ($! == EPERM || $! == ENOMEM)) {
    skip_all("kernel pipe-user-pages budget exhausted ($!); cannot grow pipe");
}

ok(defined $ret, "resize_or_max returned a defined value");
is($ret, $max,   "resize_or_max returned the requested size");

my $after = $p->size;
is($after, $max, "FIFO buffer is grown to max ($max)");

ok($after > $before, "size strictly increased ($before -> $after)");

# max_size return shape -- regression sentinel for the
# "string vs integer" bug. fcntl(F_SETPIPE_SZ, $string) returns EINVAL
# silently; we want to be sure max_size returns something that, when
# fed back to fcntl, succeeds.
my $ms = Atomic::Pipe->max_size;
ok(defined $ms,    "max_size is defined");
ok($ms =~ /^\d+\z/, "max_size has only digits (no trailing newline)");

# Fresh fifo so we observe the raw fcntl path independently. Free the
# first pipe first so its pages are returned to the per-user pipe-pages
# budget; otherwise the raw fcntl below can fail with EPERM/ENOMEM on
# constrained smokers even though the value itself is well-formed.
undef $p;
unlink $f;
mkfifo($f, 0700) or die "mkfifo: $!";
my $p2 = Atomic::Pipe->read_fifo($f);
my $rh = $p2->rh;
my $r2  = fcntl($rh, &Fcntl::F_SETPIPE_SZ, $ms);
my $err = $!;
SKIP: {
    # EINVAL is the chomp-string regression we actually want to catch
    # (fcntl reads $ms as a buffer pointer and rejects). Anything else is
    # environmental: pipe-user-pages budget (EPERM/ENOMEM), pipe-has-data
    # (EBUSY), or smoker-specific quirks. Skip those rather than fail.
    if (!defined $r2 && 0+$err != EINVAL) {
        skip "raw fcntl failed environmentally ($err)", 1;
    }
    ok(defined $r2, "raw fcntl(F_SETPIPE_SZ, max_size()) does not return undef")
        or diag("errno: $err (", 0+$err, ")");
}

done_testing;
