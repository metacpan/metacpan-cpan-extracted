use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

# OFFLINE test: the connect options beside an AccessBroker in the forked mode
# (karr k12; core k243, ADR 0030 addendum II).
#
# WHY: core takes connect options beside a broker --
# MyApp::Schema->connect($broker, { async => 'forked', AutoCommit => 1, ... }).
# What only the owning sync storage applies (the mode, storage and SQL maker
# options) never needed anything from a backend. What a backend applies itself
# -- the DBD attributes and pool_size -- core hands on as [ $broker, \%options ],
# but only to a transport that declares 'broker_connect_options'; any other is
# refused at first async use, because the sync connection would run with
# settings none of the backend's own connections has. This backend did not
# declare it, so a broker-backed connection could not carry a single DBD
# attribute in the forked mode -- although Model A is the one transport where
# the refusal has nothing to protect: the forked child opens no connection of
# its own making, it runs the OWNER storage, which reconnects through the
# broker and applies the options itself (ADR 0002).
#
# The declaration is a promise, so this file claims the behaviour behind it:
#   1. the backend declares exactly broker_connect_options -- the one
#      capability core itself reads -- and still nothing an async layer could
#      require (no on_connect_replay, listen, notify, copy, pipeline) and no
#      _query_async seam for a layer to wrap;
#   2. control: a broker with nothing but the mode beside it resolves the
#      backend (it did before, too) and the child's connection is the owner's;
#   3. connect($broker, { async => 'forked', pool_size => 2, AutoCommit => 1 })
#      -- the card's own example -- is not refused at first async use, and the
#      backend is handed the connect info as given;
#   4. THE CHILD SEES THE ATTRIBUTES: the connection the owner storage opens in
#      the forked child gets the DBD attributes given beside the broker, and
#      not pool_size (nor the mode) -- the very arguments the parent's own
#      connection got;
#   5. pool_size has nothing to size: Model A has no pool, with a broker as
#      with a DSN;
#   6. the child asks the broker again, and the options join THAT answer: a
#      broker answering the DBI form with attributes of its own and a fresh
#      user per answer.
#
# WHAT RUNS FOR REAL: fork + pipe + Storable, DBIO::Forked::Storage and its
# Future, core's DBIO::Schema, core's DBIO::Storage::DBI as the owner (its
# connect_info, broker attach, option split, _async_storage gate, _verify_pid,
# _connect, txn_do), DBIO::AccessBroker::Static.
# THE SUBSTITUTIONS: no DBD. DBI->connect records its arguments (and the pid
# that called it) and returns a fake handle that answers what the owner's
# connect and transaction path ask of one. So this file shows what the owner
# hands to DBI->connect in the child -- not what a DBD then does with it.

use DBI ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::Forked;

plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243)'
  unless DBIO::Storage::Async->can('_takes_broker_connect_options');

alarm 60;

my $FORKED = 'DBIO::Forked::Storage';

# --- the owner: core's sync storage, registered for a DBD name of its own so a
# --- broker answering connection parameters gets its DSN built.
{
  package T::Probe::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ForkedProbe => __PACKAGE__);

  package T::Probe::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::Probe::Storage');
}

# --- the handle DBI->connect returns.
{
  package T::Probe::DBH;
  sub new {
    bless {
      Active     => 1,
      AutoCommit => 1,
      RaiseError => 1,
      Driver     => { Name => 'ForkedProbe' },
    }, shift;
  }
  sub FETCH      { $_[0]{ $_[1] } }
  sub ping       { 1 }
  sub begin_work { $_[0]{AutoCommit} = 0; 1 }
  sub commit     { $_[0]{AutoCommit} = 1; 1 }
  sub rollback   { $_[0]{AutoCommit} = 1; 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
}

# Every DBI->connect, in whichever process: who called, and with what. Set for
# the whole file (not local) -- the forked child inherits it and records its
# own connect into its own copy of @CONNECTS.
our @CONNECTS;
{
  no warnings qw(redefine once);
  *DBI::connect = sub {
    shift;
    push @CONNECTS, { pid => $$, args => [ @_ ] };
    return T::Probe::DBH->new;
  };
}

# A broker answering the DBI form, with attributes of its own; each answer
# names a fresh user, as a rotating broker's would.
{
  package T::DBIFormBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $attrs) = @_; bless { attrs => $attrs, calls => 0 }, $class }
  sub is_transaction_safe { 1 }
  sub connect_info_for {
    my $self = shift;
    my $n = ++$self->{calls};
    return [ 'dbi:ForkedProbe:dbname=app', "user_$n", 'p', { %{ $self->{attrs} } } ];
  }
}

my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,   # core forces it off on every handle (no statement text in errors)
);

my @STATIC = ('dbi:ForkedProbe:dbname=appdb;host=db.example', 'app', 's3cret');

sub static_broker {
  return DBIO::AccessBroker::Static->new(
    host => 'db.example', dbname => 'appdb', username => 'app', password => 's3cret',
  );
}

# Connect the parent, then run a transaction in a forked child and bring back
# every DBI->connect the CHILD made. The parent connects first on purpose: the
# child then inherits a live handle and has to drop it and reconnect on its own
# (_verify_pid), which is the path ADR 0002 rests on.
sub connects_in_child {
  my ($schema) = @_;

  $schema->storage->ensure_connected;
  my @parent = grep { $_->{pid} == $$ } @CONNECTS;

  my $seen = $schema->storage->txn_do_async(sub {
    return { pid => $$, connects => [ grep { $_->{pid} == $$ } @CONNECTS ] };
  })->get;

  return ($seen, @parent);
}

# ---------------------------------------------------------------------------
# 1. The declaration -- and what stays undeclared.
# ---------------------------------------------------------------------------
{
  is_deeply [ $FORKED->transport_capabilities ], [ 'broker_connect_options' ],
    'transport_capabilities: exactly broker_connect_options';
  ok $FORKED->_takes_broker_connect_options,
    'core reads it: _takes_broker_connect_options is true';

  my %have = map { $_ => 1 } $FORKED->transport_capabilities;
  ok !$have{$_}, "no '$_' -- nothing an async layer could require"
    for qw( on_connect_replay listen notify copy pipeline );

  is $FORKED->can('_query_async'), DBIO::Storage::Async->can('_query_async'),
    'still no _query_async seam: the abstract stub is inherited, not overridden';
}

# ---------------------------------------------------------------------------
# 2. Control: the broker with nothing but the mode beside it.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker = static_broker();
  my $schema = T::Probe::Schema->connect($broker, { async => 'forked' });

  my $async = eval { $schema->storage->async };
  is $@, '', 'broker + mode alone: the backend resolves';
  isa_ok $async, $FORKED, 'the embedded backend';
  is_deeply $async->connect_info, { broker => 1, elements => 1 },
    '... handed the broker alone (the backend keeps the form)';

  my ($seen, @parent) = connects_in_child($schema);
  isnt $seen->{pid}, $$, 'the transaction ran in a forked child';
  is_deeply [ map { $_->{args} } @{ $seen->{connects} } ],
    [ [ @STATIC, { %DEFAULT_ATTRS } ] ],
    'the child connected once, on its own, with the owner storage\'s arguments';
}

# ---------------------------------------------------------------------------
# 3. + 4. + 5. DBD attributes and pool_size beside the broker.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my %options = (
    async       => 'forked',
    pool_size   => 2,
    AutoCommit  => 1,       # the card's example; also the storage's default
    LongReadLen => 4096,    # NOT a default: only the options can put it there
  );
  my $broker = static_broker();
  my $schema = T::Probe::Schema->connect($broker, { %options });

  # 3. not refused at first async use
  my $async = eval { $schema->storage->async };
  is $@, '', 'DBD attributes and pool_size beside the broker: the backend is not refused';
  isa_ok $async, $FORKED, 'the embedded backend';

  SKIP: {
    skip 'no backend to look at', 8 unless $async;

    is_deeply $async->connect_info, { broker => 1, elements => 2 },
      'the backend is handed the broker and the options beside it (it keeps the form)';

    # 5. nothing to size
    ok !eval { $async->pool; 1 }, 'pool_size sizes nothing: there is no pool';
    like $@, qr/no connection pool/, '... and the backend says so';

    # 4. the child sees the attributes
    my ($seen, @parent) = connects_in_child($schema);
    isnt $seen->{pid}, $$, 'the transaction ran in a forked child';
    is scalar @{ $seen->{connects} }, 1, 'the child connected once, on its own';

    my $child = $seen->{connects}[0]{args};
    is_deeply $child, [ @STATIC, { %DEFAULT_ATTRS, LongReadLen => 4096 } ],
      'the child\'s DBI->connect: the broker\'s connection, the attributes beside it';
    ok !exists $child->[3]{pool_size} && !exists $child->[3]{async},
      '... and neither pool_size nor the mode among the DBD attributes';
    is_deeply $child, $parent[-1]{args},
      '... the very arguments of the parent\'s own connect';
  }
}

# ---------------------------------------------------------------------------
# 6. The child asks the broker again; the options join that answer.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker = T::DBIFormBroker->new({ PrintWarn => 0 });
  my $schema = T::Probe::Schema->connect(
    $broker, { async => 'forked', LongReadLen => 4096 },
  );

  my ($seen, @parent) = eval { connects_in_child($schema) };
  is $@, '', 'a DBI-form broker with DBD attributes beside it: not refused';

  SKIP: {
    skip 'no child to look at', 3 unless $seen;

    my $child = $seen->{connects}[0]{args};
    my ($parent_n) = $parent[-1]{args}[1] =~ /^user_(\d+)$/;
    my ($child_n)  = ($child->[1] // '')  =~ /^user_(\d+)$/;

    ok $parent_n && $child_n && $child_n > $parent_n,
      'the child asked the broker again (a later answer than the parent\'s)';
    is $child->[0], 'dbi:ForkedProbe:dbname=app', '... for the same database';
    is_deeply $child->[3], { %DEFAULT_ATTRS, PrintWarn => 0, LongReadLen => 4096 },
      'that answer\'s attributes with the ones beside the broker joined in';
  }
}

# ---------------------------------------------------------------------------
# No zombies left behind.
# ---------------------------------------------------------------------------
{
  my $reaped = waitpid(-1, WNOHANG);
  ok($reaped == -1 || $reaped == 0, "no unreaped child processes left (got $reaped)");
}

done_testing;
