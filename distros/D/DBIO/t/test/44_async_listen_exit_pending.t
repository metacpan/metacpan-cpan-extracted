use strict;
use warnings;
use Test::More;
use File::Temp ();
use Scalar::Util ();

use DBIO::Test::Future ();
use DBIO::Storage::Async;

# karr k237, found in a dbio-postgresql-ev run. A process that exits while a
# listen() is still pending -- its listen connection not yet open, say --
# warned on the way out:
#
#   (in cleanup) Can't call method "is_ready" on an undefined value at
#   .../DBIO/Storage/Async.pm line ... during global destruction.
#
# In global destruction Perl frees objects in no particular order. The Future
# listen() handed out, still waiting in the listen state, can be freed before
# the storage; the storage's DESTROY then disconnects, ends listening, and
# settles every Future still waiting -- and _listen_resolve called a method on
# the one that was already gone. The claims:
#
#   * disconnect -- which DESTROY runs -- ends listening although a Future
#     waiting in it has been freed: there is nothing to settle there. Pinned
#     in-process, with the Future freed on purpose, as global destruction frees
#     it: that does not depend on the order Perl picks;
#   * a process that exits with listens pending exits cleanly: status 0 and no
#     "(in cleanup)" / "during global destruction" diagnostic. Checked in a
#     child process, in two shapes of twenty storages each; before the fix
#     both warned, every time, on this perl.

{
  package K237::Listen;
  use base 'DBIO::Storage::Async';

  sub future_class           { 'DBIO::Test::Future' }
  sub transport_capabilities { qw(listen notify) }
  sub _listen_open           { DBIO::Test::Future->new }
  sub _listen_close          { return }
}

# ---------------------------------------------------------------------------
# disconnect with a waiting Future already freed. Asserts: the listen is
# pending; once the Future waiting for it is gone, disconnect lives and
# reports nothing. Before the fix disconnect died calling is_ready on it.
# ---------------------------------------------------------------------------
{
  my $storage = K237::Listen->new(undef);
  my @reported;
  $storage->on_listen_error(sub { push @reported, $_[1] });
  my $listening = $storage->listen('chan', sub {});
  ok !$listening->is_ready, 'freed Future: the listen is pending';

  # What global destruction does before the storage's DESTROY runs: free the
  # Future still waiting in the listen state -- the state's hold on it made
  # weak, the caller's dropped.
  my $waiting = $storage->{_listen}{waiting}{chan};
  Scalar::Util::weaken($_) for @$waiting;
  undef $listening;
  ok !grep({ defined } @$waiting), 'freed Future: (it is gone)';

  my $ok = eval { $storage->disconnect; 1 };
  ok $ok, 'freed Future: disconnect ends listening all the same' or diag $@;
  is_deeply \@reported, [], 'freed Future: and reports nothing about it';
}

# ---------------------------------------------------------------------------
# A process that exits with listens pending, on twenty storages. Asserts, per
# shape: none of the listens had settled when the child exited; it exits with
# status 0; it says nothing about a cleanup or global destruction. Before the
# fix both shapes warned.
# ---------------------------------------------------------------------------
my $preamble = <<'PERL';
use strict;
use warnings;
open STDERR, '>&', \*STDOUT or die "dup STDERR: $!";
$| = 1;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
{
  package K237::Child;
  use base 'DBIO::Storage::Async';
  sub future_class           { 'DBIO::Test::Future' }
  sub transport_capabilities { qw(listen notify) }
  sub _listen_open           { my $f = DBIO::Test::Future->new; push @{ $_[0]{opens} }, $f; $f }
  sub _listen_close          { return }
  sub _listen_subscribe      { DBIO::Test::Future->done }
  sub _listen_unsubscribe    { DBIO::Test::Future->done }
  sub _listen_watch          { return }
  sub _listen_unwatch        { return }
  sub _listen_probe          { 1 }
  sub _listen_delay          { DBIO::Test::Future->new }
  sub _notify_send           { DBIO::Test::Future->done }
}
PERL

my %shapes = (
  'one channel each' => <<'PERL',
our @K;
for (1 .. 20) {
  my $storage = K237::Child->new(undef);
  push @K, $storage, $storage->listen('chan', sub {});
}
print((grep { $_->can('is_ready') && $_->is_ready } grep { !$_->isa('K237::Child') } @K)
  ? "settled\n" : "pending\n");
PERL
  'several channels and a listen_reconnect each' => <<'PERL',
our @K;
for (1 .. 20) {
  my $storage = K237::Child->new(undef);
  push @K, $storage;
  push @K, $storage->listen("chan$_", sub {}) for 1 .. 5;
  push @K, $storage->listen_reconnect;
}
print((grep { $_->can('is_ready') && $_->is_ready } grep { !$_->isa('K237::Child') } @K)
  ? "settled\n" : "pending\n");
PERL
);

my @inc = map { "-I$_" } grep { !ref } @INC;
for my $shape (sort keys %shapes) {
  my $script = File::Temp->new(SUFFIX => '.pl');
  print {$script} $preamble, $shapes{$shape};
  close $script;

  open my $child, '-|', $^X, @inc, $script->filename
    or die "cannot run $^X: $!";
  my $output = do { local $/; <$child> } // '';
  close $child;
  my $status = $? >> 8;

  like $output, qr/^pending$/m, "$shape: the listens are pending when the process exits";
  is $status, 0, "$shape: the process exits with status 0";
  unlike $output, qr/\(in cleanup\)|during global destruction/,
    "$shape: it says nothing about a cleanup on the way out"
    or diag $output;
}

done_testing;
