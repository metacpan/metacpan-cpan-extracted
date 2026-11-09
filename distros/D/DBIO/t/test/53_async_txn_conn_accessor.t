use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# A backend names the pinned connection of its transaction context itself
# (karr k284).
#
# _txn_conn_accessor is a seam: the name a backend's transaction context knows
# its pinned connection by. txn_do_async honoured it -- it builds the context
# with the connection under that key -- but deploy_async did not: its
# transactional run read the connection back as $ctx->txn_conn, the default
# name, whatever the seam answered. A backend that used the seam got a deploy
# that died on its own context, or -- where that context had a txn_conn of
# another meaning -- sent its DDL to whatever that was.
#
# The claim: wherever core needs the pinned connection from a transaction
# context, it asks the context under the name _txn_conn_accessor answers --
# the same name it built the context with, and no other. So a backend that
# answers another name, with a context class that goes by it, runs
# txn_do_async and a transactional deploy_async like one that keeps the
# default: the same statements, on the pinned connection, handed back once.
#
# The fixture: a real DBIO::Storage::PoolBase of size 1 logging every release;
# a fake wire recording each statement with the connection it was sent on.
# Against DBIO::Test::Future and, where installed, Future.pm.

{
  package K284::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K284::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K284::Conn->new('the pinned connection') }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# A context class of the backend's own, as the seam asks for: it takes the
# connection under txn_handle and answers it under txn_handle. It is not the
# generic context and has no txn_conn.
{
  package K284::Context;
  sub new {
    my ($class, %args) = @_;
    die "txn_handle required\n" unless $args{txn_handle};
    return bless { %args }, $class;
  }
  sub txn_handle { $_[0]->{txn_handle} }
}

# The same, where txn_conn is a name of the backend's own for something else.
{
  package K284::Context::OtherTxnConn;
  our @ISA = ('K284::Context');
  sub txn_conn { 'not the pinned connection' }
}

# ALTER stands for the statement that cannot run in a transaction.
{
  package K284::Owner;
  sub new { bless {}, $_[0] }
  sub _use_transactional_ddl { 1 }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package K284::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { $_[0]->{fc} }
  sub _install_ddl { $_[0]->{ddl} }

  sub _txn_conn_accessor {
    my ($self) = @_;
    return $self->{accessor} || $self->SUPER::_txn_conn_accessor;
  }
  sub _txn_context_class {
    my ($self) = @_;
    return $self->{context_class} || $self->SUPER::_txn_context_class;
  }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K284::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{sent} }, [ $sql, (ref $conn ? $conn->{id} : $conn) ];
    return $self->future_class->fail("refused: $sql\n")
      if $self->{fail_on} && $sql =~ $self->{fail_on};
    return $self->future_class->done;
  }
}

my @warnings;
local $SIG{__WARN__} = sub {
  # deploy_async's own one-shot notice.
  return if $_[0] =~ /^split DDL batch on K284::Backend /;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, %set) = @_;
  my $backend = K284::Backend->new(undef);
  $backend->{fc}     = $fc;
  $backend->{_owner} = K284::Owner->new;   # held weakly by the backend
  $backend->_owner_storage($backend->{_owner});
  $backend->{sent} = [];
  $backend->{$_} = $set{$_} for keys %set;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  return 'pending' unless $f->is_ready;
  return "failed: $@" unless eval { $f->get; 1 };
  return 'done';
}

sub on_pinned { [ map { [ $_, 'the pinned connection' ] } @_ ] }

my ($A, $B) = map { "CREATE TABLE $_ (id int)" } qw( a b );
my $X       = "ALTER TYPE mood ADD VALUE 'x'";

# [ label, what the backend answers for the two seams, the name its context
#   answers the connection under ]
my @BACKENDS = (
  [ 'the default name, the generic context', {}, 'txn_conn' ],
  [ 'a name of its own, a context of its own',
    { accessor => 'txn_handle', context_class => 'K284::Context' }, 'txn_handle' ],
  [ 'a name of its own, a context whose txn_conn is something else',
    { accessor => 'txn_handle', context_class => 'K284::Context::OtherTxnConn' }, 'txn_handle' ],
);

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { note 'Future.pm not installed: run against DBIO::Test::Future only' }

for my $fc (@future_classes) {
  for my $spec (@BACKENDS) {
    my ($which, $seams, $name) = @$spec;
    my $l = "$fc, $which";

    # --- txn_do_async: the context is built with the connection under the name
    {
      my $backend = new_backend($fc, %$seams);
      my $pool    = $backend->pool;
      my $seen;
      my $f = $backend->txn_do_async(sub {
        my ($ctx) = @_;
        $seen = $ctx->$name;
        return $backend->_query_async_pinned($seen, 'INSERT INTO a VALUES (1)', []);
      });
      is outcome($f), 'done', "$l: txn_do_async resolves";
      is_deeply $backend->{sent}, on_pinned('BEGIN', 'INSERT INTO a VALUES (1)', 'COMMIT'),
        "$l: ... its context answers under $name the connection BEGIN and COMMIT ran on";
      is_deeply $pool->{release_log}, ['the pinned connection'],
        "$l: ... handed back once";
    }

    # --- deploy_async, one transactional run: the DDL goes out on the
    #     connection BEGIN ran on, read from the context under the same name
    {
      my $backend = new_backend($fc, %$seams, ddl => "$A;\n$B;");
      my $pool    = $backend->pool;
      is outcome($backend->deploy_async('schema')), 'done',
        "$l: a transactional deploy_async resolves";
      is_deeply $backend->{sent}, on_pinned('BEGIN', $A, $B, 'COMMIT'),
        "$l: ... every statement on the pinned connection, inside BEGIN/COMMIT";
      is_deeply $pool->{release_log}, ['the pinned connection'],
        "$l: ... handed back once";
    }

    # --- ... a statement of it fails: that error, and a ROLLBACK
    {
      my $backend = new_backend($fc, %$seams, ddl => "$A;\n$B;", fail_on => qr/^\Q$B\E$/);
      my $pool    = $backend->pool;
      like outcome($backend->deploy_async('schema')), qr/^failed: .*refused: \Q$B\E/s,
        "$l: a transactional deploy_async fails with its statement's error";
      is_deeply $backend->{sent}, on_pinned('BEGIN', $A, $B, 'ROLLBACK'),
        "$l: ... the statements up to it went out, then ROLLBACK";
      is_deeply $pool->{release_log}, ['the pinned connection'],
        "$l: ... handed back once";
    }

    # --- ... a batch of three runs: each transactional run asks its own context
    {
      my $backend = new_backend($fc, %$seams, ddl => "$A;\n$X;\n$B;");
      my $pool    = $backend->pool;
      is outcome($backend->deploy_async('schema')), 'done',
        "$l: a deploy_async of three runs resolves";
      is_deeply $backend->{sent},
        on_pinned('BEGIN', $A, 'COMMIT', $X, 'BEGIN', $B, 'COMMIT'),
        "$l: ... both transactional runs on the pinned connection";
      is_deeply $pool->{release_log}, [ ('the pinned connection') x 3 ],
        "$l: ... each run handed it back once";
    }
  }

  # The generic context takes the connection under txn_conn only: a backend
  # that answers another name and keeps the generic context is told so, as the
  # failure of the transaction -- and the connection still goes back.
  {
    my $l = "$fc, a name of its own but the generic context";
    my $backend = new_backend($fc, accessor => 'txn_handle');
    my $pool    = $backend->pool;
    my $ran     = 0;
    like outcome($backend->txn_do_async(sub { $ran++; 1 })), qr/^failed: .*txn_conn required/s,
      "$l: txn_do_async fails with 'txn_conn required'";
    is $ran, 0, "$l: ... the coderef never ran";
    is_deeply $pool->{release_log}, ['the pinned connection'], "$l: ... the connection handed back once";
  }
}

is_deeply \@warnings, [], 'nothing warned';

done_testing;
