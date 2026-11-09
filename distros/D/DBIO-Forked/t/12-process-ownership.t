use strict;
use warnings;
use Test::More;
use POSIX ();

use DBIO::Forked::Storage;

# OFFLINE test: a Future belongs to the process that created it (karr k26).
#
# WHY: a Future is a pipe read end plus a child pid. An application that forks
# (prefork server, worker spawn) copies the object, and the copy shares the
# pipe. If the copy read or reaped, it would consume the bytes the owner is
# waiting for: the owner would then see an empty or torn result. So in any
# process other than the creating one, get/is_ready fail with a message naming
# the owner, and DESTROY closes nothing and reaps nothing. A derived
# (then/catch) future follows its source.
#
# WHAT RUNS FOR REAL: DBIO::Forked::Storage::_run_forked (fork + pipe +
# Storable) and DBIO::Forked::Future. THE SUBSTITUTION: the sync storage is a
# mock; no DBI, no database.

alarm 60;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ], [ 2, 'Bob' ]) }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
my $storage = DBIO::Forked::Storage->new($schema);

# Run $code in a child of this test; it returns a hash that is sent back
# through a pipe as "key=value" lines. The child leaves with POSIX::_exit so
# it neither flushes Test::More's output nor runs END blocks.
sub in_child {
  my ($code) = @_;
  pipe(my $r, my $w) or die "pipe: $!";
  my $pid = fork // die "fork: $!";
  if (!$pid) {
    close $r;
    my %out = eval { $code->() };
    %out = (died => "$@") if $@;
    print {$w} map { "$_=" . ($out{$_} // '') . "\n" } sort keys %out;
    close $w;
    POSIX::_exit(0);
  }
  close $w;
  my %got = map { chomp; split /=/, $_, 2 } <$r>;
  close $r;
  waitpid($pid, 0);
  return %got;
}

# ---------------------------------------------------------------------------
# 1. get / is_ready / is_failed in a copy fail naming the owner; the owner
#    still gets the result.
# ---------------------------------------------------------------------------
{
  my $f = $storage->select_async('t', [qw(id name)], {}, {});
  my %c = in_child(sub {
    my %o;
    eval { $f->get };            $o{get}      = $@;
    eval { $f->is_ready };       $o{is_ready} = $@;
    eval { $f->is_failed };      $o{is_failed} = $@;
    my $d = $f->then(sub { 1 });
    eval { $d->get };            $o{derived}  = $@;
    return %o;
  });
  for my $m (qw(get is_ready is_failed derived)) {
    like $c{$m}, qr/belongs to process $$\b/, "$m in a copy names the owner pid";
  }
  my @rows = $f->get;
  is scalar(@rows), 2, 'the owner still gets every row after the copy tried';
  is_deeply $rows[0], [ 1, 'Alice' ], 'and the rows are intact';
}

# ---------------------------------------------------------------------------
# 2. DESTROY in a copy closes nothing and reaps nothing: the read end stays
#    open there, and the owner reaps its own child with a real exit status
#    (a copy that had reaped it would leave the owner with ECHILD).
# ---------------------------------------------------------------------------
{
  my $f = $storage->select_async('t', [qw(id name)], {}, {});
  my %c = in_child(sub {
    my $fh = $f->{read_fh};
    undef $f;                       # the last reference in this process
    return (fd_open => (defined fileno($fh) ? 1 : 0));
  });
  is $c{fd_open}, 1, 'DESTROY in a copy leaves the read end open';
}
{
  my $f = $storage->select_async('t', [qw(id name)], {}, {});
  in_child(sub { undef $f; return () });
  my @rows = $f->get;
  is scalar(@rows), 2, 'the owner reads the full result after a copy was destroyed';
  is $f->{status}, 0, 'and reaped its child itself, with the child\'s real status';
}

done_testing;
