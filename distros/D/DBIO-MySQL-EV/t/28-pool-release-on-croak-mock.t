use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k50: a pooled query that dies before it has a
# Future still gives its connection back to the pool.
#
# WHY: _query_async and insert_async acquire a pooled connection and register
# its release on the query Future (on_ready). That Future only exists once the
# dispatch has returned -- and EV::MariaDB croaks synchronously from prepare
# and query ("another operation is in progress", "cannot queue query:
# exclusive operation in progress", "not connected", "connection not valid
# after fork", ...), and insert_async's SQL generation throws before anything
# reaches the wire (a conflict target MySQL cannot honour, say). In every one
# of those cases the release was never registered: the call failed, and its
# connection stayed checked out for good. With a pool of N, N such failures
# and every later query waits forever for a connection.
#
# What this file claims, for each way to die -- a croaking prepare (a query
# with bind values), a croaking query (one without), a croaking prepare under
# insert_async, and insert_async's SQL generation throwing:
#   a. the call fails with that error, unchanged -- releasing does not swallow
#      or replace it;
#   b. the connection is back in the pool at once, and only once: a pool of
#      one has exactly one idle connection (a double release would list the
#      one handle twice and hand it to two callers);
#   c. the next call on that pool of one gets the connection and completes.
#
# Without the fix b and c fail: nothing is idle, and the next call waits for a
# connection nobody returns. That wait is bounded -- DBIO::MySQL::EV::Future
# dies when nothing left in the loop could settle it (karr k48), and a
# keepalive(0) watchdog fails it should something keep the loop alive -- so
# the regression shows as a failure, not a hang.
#
# CroakMDB stands in for EV::MariaDB (the t/26 fake): every operation
# completes on an EV timer, and prepare / query croak once when armed, the way
# the XS does -- before taking the callback. Its session is there throughout
# (a live socket with nothing to read), whatever the armed message says, so
# the connection goes back on the idle list; a croak on a handle that is gone
# retires the connection instead, which is t/32's claim (karr k55).

use EV;
use DBIO::Test;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

{
  package CroakMDB;
  use Carp ();
  use Socket ();

  # op => message: the next call of that op croaks with it, once.
  our %CROAK;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0, stmts => {}, next => 0 }, $class;
    # A live session: a real socket with nothing to read, which is what the
    # transport asks a handle about after a failed statement (karr k55).
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    _later(sub { $self->{connected} = 1; $self->{on_connect}->() });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub _answer {
    my ($sql) = @_;
    return ([ [ 7 ] ])        if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ]) if $sql =~ /^SELECT/;
    return (1)                if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub is_connected { $_[0]{connected} }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async  { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
  sub finish       { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }
  sub socket       { fileno $_[0]{sock}[0] }
  sub pending_count { 0 }

  sub query {
    my ($self, $sql, $cb) = @_;
    if (defined(my $msg = delete $CROAK{query})) { Carp::croak($msg) }
    _later(sub { $cb->(_answer($sql)) });
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    if (defined(my $msg = delete $CROAK{prepare})) { Carp::croak($msg) }
    my $id = ++$self->{next};
    $self->{stmts}{$id} = $sql;
    _later(sub { $cb->($id) });
    return;
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    _later(sub { $cb->(_answer($sql)) });
    return;
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    delete $self->{stmts}{$id};
    _later(sub { $cb->(1) });
    return;
  }

  # The reset the pool sends at the end of every borrow (karr k100, core k398).
  sub reset_connection {
    my ($self, $cb) = @_;
    _later(sub { $cb->(1, undef) });
    return;
  }
}

# The real pool builds its handles through this seam (t/08, t/26).
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; CroakMDB->new(@_) };
}

# A real storage, pool and executor over CroakMDB, with a pool of one.
sub pool_of_one {
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# The three claims, for one way to die. $fails and $next are coderefs that
# start the dying call and the next call on $storage.
sub released_after_croak {
  my ($label, $storage, $fails, $error, $next, $expect) = @_;

  my ($ok, @r) = wait_for($fails->());
  ok !$ok, "$label: the call fails";
  like $r[0], $error, "$label: with the error it died with";

  # The connection is back once the reset of its session has answered.
  my $dog = EV::timer(2, 0, sub {});
  EV::run(EV::RUN_ONCE()) until $storage->pool->available == 1 || !$dog->is_active;

  is $storage->pool->available, 1, "$label: its connection is back in the pool, once";

  ($ok, @r) = wait_for($next->());
  ok $ok, "$label: the next call on the pool of one gets the connection"
    or diag "it failed: $r[0]";
  is_deeply \@r, $expect, "$label: and completes";
  is $storage->pool->size, 1, "$label: on the one connection the pool has";
}

# --- a query with bind values: prepare croaks ------------------------------------

{
  my $storage = pool_of_one();
  released_after_croak(
    'prepare croaks',
    $storage,
    sub {
      $CroakMDB::CROAK{prepare} = 'another operation is in progress';
      $storage->update_async('artist', { name => 'x' }, { id => 1 });
    },
    qr/^another operation is in progress at /,
    sub { $storage->update_async('artist', { name => 'y' }, { id => 1 }) },
    [ 1 ],
  );
}

# --- a query without bind values: query croaks -----------------------------------

{
  my $storage = pool_of_one();
  released_after_croak(
    'query croaks',
    $storage,
    sub {
      $CroakMDB::CROAK{query} = 'cannot queue query: exclusive operation in progress';
      $storage->select_async('artist', [qw( id name )]);
    },
    qr/^cannot queue query: exclusive operation in progress at /,
    sub { $storage->select_async('artist', [qw( id name )]) },
    [ [ 1, 'one' ] ],
  );
}

# --- insert_async: the INSERT's prepare croaks -----------------------------------

{
  my $storage = pool_of_one();
  released_after_croak(
    'insert_async, prepare croaks',
    $storage,
    sub {
      $CroakMDB::CROAK{prepare} = 'not connected';
      $storage->insert_async('artist', { name => 'x' });
    },
    qr/^not connected at /,
    sub { $storage->insert_async('artist', { name => 'y' }) },
    [ { name => 'y' } ],
  );
}

# --- insert_async: SQL generation throws before anything reaches the wire --------
#
# An upsert demanding a conflict target MySQL cannot honour: Artist has further
# unique keys besides artistid, and ON DUPLICATE KEY UPDATE would fire on those
# too. The plan (DBIO::MySQL::Storage::_mysql_upsert_plan, on the owning sync
# storage) throws inside insert_async's acquire -- a caller's mistake that cost
# a pool slot for good.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $owner  = $schema->storage;
  my $source = $schema->source('Artist');

  my $storage = pool_of_one();
  $storage->_owner_storage($owner);   # held by $schema; the setter weakens

  released_after_croak(
    'insert_async, SQL generation throws',
    $storage,
    sub {
      $storage->insert_async($source, { name => 'x' }, {
        on_conflict => {
          target => [ 'artistid' ],
          action => 'update',
          set    => { name => { -attempted => 'name' } },
        },
      });
    },
    qr/MySQL cannot honour the requested conflict target \(artistid\)/,
    sub { $storage->insert_async($source, { name => 'y' }) },
    [ { name => 'y', artistid => 7 } ],
  );
}

done_testing;
