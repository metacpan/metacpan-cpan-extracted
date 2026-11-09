use strict;
use warnings;
use Test::More;
use File::Temp ();

use DBIO::Test::Future ();

# karr k257, found by the k254 worker. DBIO::Test::Future holds a derived
# Future -- the one ->then, ->catch and needs_all return -- strongly, in its
# precedent's callback list or in a closure, and settled it without checking
# it still existed. Held strongly, it can be gone only in global destruction,
# where Perl clears references to objects in no particular order: a Future
# settled there -- by a DESTROY, as a pool's shutdown settled its waiters
# before k254 -- warned
#
#   (in cleanup) Can't call method "fail" on an undefined value at
#   .../DBIO/Test/Future.pm line ... during global destruction.
#
# The claims:
#
#   * a chain is held from its head: a ->then result nobody holds still runs
#     its callback and settles, and so does a chain whose middle nobody holds
#     -- the reason the fix is an existence check, not weak references, which
#     would free both (control);
#   * a process that exits with DBIO::Test::Future chains pending, settled in
#     global destruction, exits cleanly: status 0 and nothing about a cleanup
#     or global destruction -- for a plain ->then, a ->then whose callback
#     returned a pending Future, and needs_all. Before the fix every shape
#     warned, on this perl.

# ---------------------------------------------------------------------------
# Control: the chain is held from its head.
# ---------------------------------------------------------------------------
{
  my $head = DBIO::Test::Future->new;
  my $ran;
  $head->then(sub { $ran = 'dropped'; return });
  my $tail = $head->then(sub { 'a' })->then(sub { "$_[0]b" });
  $head->done;
  is $ran, 'dropped', 'control: a ->then result nobody holds still runs its callback';
  ok $tail->is_ready, 'control: a chain whose middle nobody holds settles';
  is scalar $tail->get, 'ab', 'control: through every link';
}

# ---------------------------------------------------------------------------
# A process that exits with chains pending, settled in global destruction.
# ---------------------------------------------------------------------------
my %shapes = (
  'a plain ->then' => <<'PERL',
    push @d, map {
      my $f = $h->future;
      $f->then(sub { my $x = $h; DBIO::Test::Future->done });
    } 1 .. 2;
PERL
  'a ->then whose callback returned a pending Future' => <<'PERL',
    my $outer = DBIO::Test::Future->new;
    push @d, $outer->then(sub { my $x = $h; $h->future });
    $outer->done;
PERL
  'needs_all' => <<'PERL',
    push @d, DBIO::Test::Future->needs_all(map { $h->future } 1 .. 2);
    push @{ $h->{keep} }, sub { my $x = $h };
PERL
);

my @inc = map { "-I$_" } grep { !ref } @INC;
for my $shape (sort keys %shapes) {
  my $script = File::Temp->new(SUFFIX => '.pl');
  print {$script} <<"PERL";
use strict;
use warnings;
open STDERR, '>&', \\*STDOUT or die "dup STDERR: \$!";
\$| = 1;
use DBIO::Test::Future ();

# Settles the Futures it made when it is destroyed, as a pool's DESTROY ran
# shutdown before k254; callbacks capture it, as acquire's capture the pool.
{
  package K257::Holder;
  sub new    { bless { f => [] }, \$_[0] }
  sub future {
    my \$self = shift;
    my \$f = DBIO::Test::Future->new;
    push \@{ \$self->{f} }, \$f;
    return \$f;
  }
  sub DESTROY {
    for my \$f (\@{ \$_[0]{f} }) {
      next unless defined \$f;
      \$f->fail("gone\\n") unless \$f->is_ready;
    }
  }
}

our \@K;
for (1 .. 20) {
  my \$h = K257::Holder->new;
  my \@d;
$shapes{$shape}
  push \@K, \$h, \@d;
}
print((grep { !\$_->isa('K257::Holder') && !\$_->is_ready } \@K)
  ? "pending\\n" : "settled\\n");
PERL
  close $script;

  open my $child, '-|', $^X, @inc, $script->filename
    or die "cannot run $^X: $!";
  my $output = do { local $/; <$child> } // '';
  close $child;
  my $status = $? >> 8;

  like $output, qr/^pending$/m, "$shape: the chain is pending when the process exits";
  is $status, 0, "$shape: the process exits with status 0";
  unlike $output, qr/\(in cleanup\)|during global destruction/,
    "$shape: it says nothing about a cleanup on the way out"
    or diag $output;
}

done_testing;
