use strict;
use warnings;
use Test::More;
use File::Temp ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k254, found in a dbio-postgresql run (k90). A process that exits while
# an acquire is still pending -- queued for a busy pool, or waiting for a new
# connection to become ready -- warned on the way out:
#
#   (in cleanup) Can't call method "is_ready" on an undefined value at
#   .../DBIO/Storage/PoolBase.pm line ... during global destruction.
#
# In global destruction Perl frees objects in no particular order. The pool's
# DESTROY runs shutdown, which settled every Future still waiting: a queued
# waiter freed before the pool was called a method on; one still there was
# failed although the Future its caller held had been freed -- Future.pm then
# carps "lost a sequence Future", DBIO::Test::Future calls a method on the
# freed one. No event loop runs in global destruction, so nobody is left to be
# told. The claims:
#
#   * shutdown called by the program still fails a queued acquire and one
#     waiting for readiness, with "Connection pool has been shut down" -- the
#     contract the global-destruction case must not cost (control);
#   * a process that exits with acquires pending exits cleanly: status 0 and
#     nothing about a cleanup, global destruction or a lost Future -- with
#     DBIO::Test::Future and with Future.pm (when installed), for a queued
#     acquire and for one waiting for readiness, on twenty pools each. Before
#     the fix every one of them warned, every time, on this perl.

{
  package K254::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K254::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K254::Conn->new(++$_[0]{n}) }
  sub _shutdown_connection { return }
}

{
  package K254::ColdPool;
  use base 'K254::Pool';
  sub _create_connection {
    my $self = shift;
    my $conn = $self->SUPER::_create_connection(@_);
    $self->_register_connection_ready($conn, $self->future_class->new);
    return $conn;
  }
}

# ---------------------------------------------------------------------------
# Control: an explicit shutdown fails what waits.
# ---------------------------------------------------------------------------
{
  my $pool = K254::Pool->new(conninfo => 'x', size => 1, future_class => 'DBIO::Test::Future');
  my $held   = $pool->acquire;
  my $queued = $pool->acquire;
  ok $held->is_ready && !$queued->is_ready, 'control: one acquire holds the pool, one is queued';
  $pool->shutdown;
  ok $queued->is_failed, 'control: shutdown fails the queued acquire';
  like scalar(eval { $queued->get } // $@), qr/Connection pool has been shut down/,
    '... with the shutdown message';
}

{
  my $pool = K254::ColdPool->new(conninfo => 'x', size => 1, future_class => 'DBIO::Test::Future');
  my $cold = $pool->acquire;
  ok !$cold->is_ready, 'control: an acquire waits for its new connection to become ready';
  $pool->shutdown;
  ok $cold->is_failed, 'control: shutdown fails it';
  like scalar(eval { $cold->get } // $@), qr/Connection pool has been shut down/,
    '... with the shutdown message';
}

# ---------------------------------------------------------------------------
# A process that exits with acquires pending.
# ---------------------------------------------------------------------------
my @future_classes = ('DBIO::Test::Future');
push @future_classes, 'Future' if eval { require Future; 1 };
note 'Future.pm not installed: checked with DBIO::Test::Future only'
  if @future_classes == 1;

my %shapes = (
  'a queued acquire'                 => [ 'K254::Pool',     2 ],
  'an acquire waiting for readiness' => [ 'K254::ColdPool', 1 ],
);

my @inc = map { "-I$_" } grep { !ref } @INC;
for my $fc (@future_classes) {
  for my $shape (sort keys %shapes) {
    my ($class, $acquires) = @{ $shapes{$shape} };

    my $script = File::Temp->new(SUFFIX => '.pl');
    print {$script} <<"PERL";
use strict;
use warnings;
open STDERR, '>&', \\*STDOUT or die "dup STDERR: \$!";
\$| = 1;
use $fc ();
use DBIO::Storage::PoolBase;
{
  package K254::Conn;
  sub new { bless { id => \$_[1] }, \$_[0] }
}
{
  package K254::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K254::Conn->new(++\$_[0]{n}) }
  sub _shutdown_connection { return }
}
{
  package K254::ColdPool;
  use base 'K254::Pool';
  sub _create_connection {
    my \$self = shift;
    my \$conn = \$self->SUPER::_create_connection(\@_);
    \$self->_register_connection_ready(\$conn, \$self->future_class->new);
    return \$conn;
  }
}
our \@K;
for (1 .. 20) {
  my \$pool = $class->new(conninfo => 'x', size => 1, future_class => '$fc');
  push \@K, \$pool, map { \$pool->acquire } 1 .. $acquires;
}
print((grep { !\$_->isa('DBIO::Storage::PoolBase') && !\$_->is_ready } \@K)
  ? "pending\\n" : "settled\\n");
PERL
    close $script;

    open my $child, '-|', $^X, @inc, $script->filename
      or die "cannot run $^X: $!";
    my $output = do { local $/; <$child> } // '';
    close $child;
    my $status = $? >> 8;

    like $output, qr/^pending$/m, "$fc, $shape: the acquire is pending when the process exits";
    is $status, 0, "$fc, $shape: the process exits with status 0";
    unlike $output, qr/\(in cleanup\)|during global destruction|lost a sequence Future/,
      "$fc, $shape: it says nothing about a cleanup or a lost Future on the way out"
      or diag $output;
  }
}

done_testing;
