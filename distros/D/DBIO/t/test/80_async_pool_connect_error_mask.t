use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;

# karr k400 (1) and (2).
#
# (1) The pool's future class is loaded as a class name is loaded: a name that
#     is no class name throws before anything is loaded or run.
# (2) A connection error that comes up asynchronously -- through the
#     transport's on_error, which settles the readiness Future and is reported
#     to the pool's on_error -- is masked like the error of a failed spawn: the
#     password of the connect info never reaches the warning nor the reason the
#     connection is retired for.

unless (eval { require Future; 1 }) {
  plan skip_all => 'Future not installed';
}

# --- (1) future_class ---------------------------------------------------------
{
  our $RAN = 0;
  my $name = 'Future; $main::RAN = 1';
  my $pool = eval {
    DBIO::Storage::PoolBase->new(conninfo => 'x', future_class => $name);
  };
  like $@, qr/is not a class name/, 'future_class: a name that is no class name throws';
  is $RAN, 0, 'future_class: and nothing of it ran';

  eval { DBIO::Storage::PoolBase->new(conninfo => 'x', future_class => 'No::Such::Future::K400') };
  ok $@, 'future_class: a class that is not installed throws';
  unlike $@, qr/No::Such::Future::K400.*password/, 'future_class: and says nothing else';

  my $ok = DBIO::Storage::PoolBase->new(conninfo => 'x', future_class => 'Future');
  is $ok->future_class, 'Future', 'future_class: an installed class is taken';
}

# --- (2) asynchronous connect errors -----------------------------------------
{
  package K400::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _transform_conninfo  { $_[1] }
  sub _create_connection   { my ($self, $info) = @_; $self->_create_ready_connection(conninfo => $info) }
  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = bless { %args }, 'K400::Conn';
    push @{ $self->{made} }, $conn;
    return $conn;
  }
  sub _shutdown_connection { }
  package K400::Conn;
}

my $SECRET = 's3cretpw';

for my $case (
  [ 'string conninfo', "host=db1 user=app password=$SECRET dbname=x" ],
  [ 'hash conninfo',   { host => 'db1', user => 'app', password => $SECRET } ],
) {
  my ($label, $conninfo) = @$case;

  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  my $pool = K400::Pool->new(conninfo => $conninfo, size => 1, future_class => 'Future');

  my $acquired = $pool->acquire;
  my $conn = $pool->{made}[0];
  $conn->{on_error}->("connection to server failed: FATAL password authentication failed (password=$SECRET)");

  ok $acquired->is_failed, "$label: the acquire fails with the connect error";
  my $reason = $acquired->failure;
  unlike $reason, qr/\Q$SECRET\E/, "$label: the reason the connection is retired for carries no password";
  like $reason, qr/authentication failed/, "$label: but still says what failed";

  my $all = join '', @warned;
  unlike $all, qr/\Q$SECRET\E/, "$label: the pool's on_error warning carries no password";
  like $all, qr/authentication failed/, "$label: but still says what failed";
}

# a seam that dies while the readiness of a connection is asked: the reason of
# the retirement is masked as well
{
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  my $pool = K400::Pool->new(
    conninfo => "host=db1 password=$SECRET", size => 1, future_class => 'Future',
  );
  no warnings 'redefine';
  local *K400::Pool::_connection_ready_future = sub { die "ready check failed for host=db1 password=$SECRET\n" };
  my $f = $pool->acquire;
  ok $f->is_failed, 'ready seam dies: the acquire fails';
  unlike $f->failure, qr/\Q$SECRET\E/, 'ready seam dies: the reason carries no password';
}

done_testing;
