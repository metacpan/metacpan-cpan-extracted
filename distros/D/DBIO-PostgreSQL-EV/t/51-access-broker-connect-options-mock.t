use strict;
use warnings;
use Test::More;

# OFFLINE test: the connect options beside an AccessBroker on the ev transport
# (karr k60; core k240 / k243 / k245).
#
# WHY: core takes connect options beside a broker --
# MyApp::Schema->connect($broker, { async => 'ev', pool_size => 3, ... }). What
# the owning sync storage applies itself (the mode, storage and SQL maker
# options) stays with it. What a backend applies -- pool_size and the DBD
# attributes -- core hands on as [ $broker, \%options ], but only to a transport
# that declares 'broker_connect_options'; for any other it refuses the
# connection at first async use, because the sync side would otherwise run with
# settings none of the pooled connections has. This transport did not declare
# it, so a pool could not be sized beside a broker at all. And its connect_info
# override never took the two-element form: handed one, it read the BROKER
# OBJECT as the conninfo, detached the broker and kept the default pool size.
#
# The declaration is a promise, so this file claims the behaviour behind it:
#   1. the schema path: connect($broker, { async => 'ev', pool_size => 3 }) is
#      not refused, the pool has three connections, and libpq gets exactly the
#      broker's parameters -- no pool_size, no DBIO option, no DBD attribute;
#   2. the pool is sized from wherever the size is given -- the broker's hash
#      answer, slot [3] or slot [4] of a DBI-form answer (a later slot winning,
#      as the sync storage merges them), or beside the broker. Given both in
#      the answer and beside the broker, the two must agree: the same value is
#      fine, different values throw naming pool_size, rather than one of them
#      winning silently;
#   3. DBD attributes beside the broker are treated as this transport treats
#      the same keys in DBI-form connect info: they never reach libpq, which
#      refuses a parameter it does not know, and they do not fail the connect;
#   4. the broker stays attached in the two-element form: it is asked again for
#      every connection, so rotated credentials reach the next one;
#   5. the declaration and the behaviour are one thing: the transport declares
#      broker_connect_options, and the same connect_info on a transport that
#      does not declare it is refused through core's gate, with nothing
#      configured -- the override takes the form only as a declared promise;
#   6. DBI-form connect info: pool_size in the fifth element (\%extra_attributes)
#      sizes the pool, and wins over the fourth -- before, only slot [3] was
#      read, so connect($dsn, $user, $pass, \%attrs, { pool_size => N }) left
#      the pool at its default.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach, option split
# and pool-size rule, core's sync storage and its _async_storage gate, this
# dist's Storage, ConnectInfo and Pool.
# THE SUBSTITUTIONS: EV::Pg records what it is constructed with (the test plays
# the server's connect); the Vault client is a stub.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @NEW;   # every EV::Pg->new: [ conninfo, the handle (weak) ]

  sub new {
    my ($class, %args) = @_;
    my $self = bless { args => { %args }, connected => 0 }, $class;
    # connect_timeout=10 is the transport's own default (karr k101, t/111): not part of what these tests compare
    push @NEW, [ $args{conninfo} =~ s/\s*connect_timeout=10\z//r, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{args}{$h} = $_[0] if @_; $s->{args}{$h} };
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }
  sub finish       { $_[0]{connected} = 0; return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{args}{on_connect}->() if $s->{args}{on_connect};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo 'dbi_to_conninfo';

plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243 / k245)'
  unless DBIO::Storage::Async->can('_access_broker_pool_size');

alarm 60;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

# A libpq conninfo string back into its parameters: key=value or
# key='quoted value' with \' and \\ escaped -- the syntax libpq reads. Dies on
# anything else.
sub parse_conninfo {
  my ($str) = @_;
  die "no conninfo string\n" unless defined $str && !ref $str;
  my %h;
  pos($str) = 0;
  while ($str =~ /\G\s*([A-Za-z_]+)=(?:'((?:[^'\\]|\\.)*)'|([^\s']*))/gc) {
    my ($key, $quoted, $bare) = ($1, $2, $3);
    die "conninfo names '$key' twice\n" if exists $h{$key};
    $h{$key} = defined $quoted ? $quoted =~ s/\\(.)/$1/gr : $bare;
  }
  die "not a libpq conninfo string\n" unless $str =~ /\G\s*\z/gc;
  return \%h;
}

{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' } }, shift }
  sub read_secret { return { %{ $_[0]{secret} } } }
}

# A broker answering whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 5433,
    dbname   => 'appdb',
    username => 'app',
    password => 's3cret',
  );
}

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example;port=5433',
    cred_path => 'database/creds/app',
    dbi_attrs => { async => 'ev' },
    %args,
  );
}

my %STATIC = (dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => 's3cret');
my %VAULT  = (dbname => 'appdb', host => 'db.example', port => 5433,
              user => 'vault-user-1', password => 'vault-pw-1');
my %ANSWER = (dbname => 'appdb', user => 'app', password => 'pw');

# One new pool connection: what EV::Pg was constructed with. The connection is
# acquired and kept, so the next spawn is a new one.
sub spawn_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one spawn\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $pg;
  return $conninfo;
}

# One open of the listen connection: what EV::Pg was constructed with.
sub listen_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->_listen_open;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one listen open\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  $s->_listen_close($f->get);
  return $conninfo;
}

# The transport, given connect info directly.
sub transport {
  my ($info, $class) = @_;
  my $s = ($class || $EV)->new(undef);
  $s->connect_info($info);
  return $s;
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# ---------------------------------------------------------------------------
# 1. The schema path.
# ---------------------------------------------------------------------------

{
  my $schema = BrokerSchema->connect(static(), { async => 'ev', pool_size => 3 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($broker, { async => ev, pool_size => 3 }): the transport'
    or diag $@;

  SKIP: {
    skip 'the connection was refused', 3 unless $async;
    is scalar eval { $async->pool->max_size }, 3, '... has a pool of three connections' or diag $@;
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%STATIC,
      '... a pool connection is opened with the broker\'s parameters and nothing else'
      or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, \%STATIC,
      '... and so is the listen connection'
      or diag $@;
  }
}

{
  # Everything the hash beside a broker may carry at once: the mode and a SQL
  # maker option (the owner's), pool_size and DBD attributes (the backend's).
  my $schema = BrokerSchema->connect(vault(), {
    async          => 'ev',
    quote_names    => 1,
    pool_size      => 2,
    pg_enable_utf8 => 1,
    RaiseError     => 1,
  });
  my $async = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($vault, { async, quote_names, pool_size, DBD attributes }): the transport'
    or diag $@;

  SKIP: {
    skip 'the connection was refused', 2 unless $async;
    is scalar eval { $async->pool->max_size }, 2, '... has a pool of two connections' or diag $@;
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%VAULT,
      '... and libpq gets the DSN parts, user and password -- no option, no DBD attribute'
      or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 2. Where the pool size comes from, and what happens when two places differ.
# ---------------------------------------------------------------------------

my @dbi = ('dbi:Pg:dbname=appdb', 'app', 'pw');

for my $case (
  [ 'nowhere',                           { %ANSWER },                                      undef,              5 ],
  [ 'the hash answer',                   { %ANSWER, pool_size => 3 },                      undef,              3 ],
  [ 'slot [3] of a DBI-form answer',     [ @dbi, { pool_size => 3 } ],                     undef,              3 ],
  [ 'slot [4] of a DBI-form answer',     [ @dbi, {}, { pool_size => 3 } ],                 undef,              3 ],
  [ 'slots [3] and [4]: [4] wins',       [ @dbi, { pool_size => 2 }, { pool_size => 3 } ], undef,              3 ],
  [ 'beside the broker',                 { %ANSWER },                                      { pool_size => 3 }, 3 ],
  [ 'beside the broker (DBI-form)',      [ @dbi, {} ],                                     { pool_size => 3 }, 3 ],
  [ 'the hash answer and beside, alike', { %ANSWER, pool_size => 3 },                      { pool_size => 3 }, 3 ],
  [ 'slot [3] and beside, alike',        [ @dbi, { pool_size => 3 } ],                     { pool_size => 3 }, 3 ],
  [ 'slot [4] and beside, alike',        [ @dbi, { pool_size => 2 }, { pool_size => 3 } ], { pool_size => 3 }, 3 ],
) {
  my ($label, $answer, $beside, $want) = @$case;
  my $broker = AnswerBroker->new($answer);
  my $s = eval { transport($beside ? [ $broker, $beside ] : [ $broker ]) };
  ok $s, "pool_size from $label: the connect info is taken" or diag $@;
  is scalar eval { $s->pool->max_size }, $want, "... and the pool has $want connections" or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%ANSWER,
    '... while pool_size never reaches libpq'
    or diag $@;
}

for my $case (
  [ 'the hash answer',               { %ANSWER, pool_size => 3 } ],
  [ 'slot [3] of a DBI-form answer', [ @dbi, { pool_size => 3 } ] ],
  [ 'slot [4] of a DBI-form answer', [ @dbi, { pool_size => 4 }, { pool_size => 3 } ] ],
) {
  my ($label, $answer) = @$case;
  @EV::Pg::NEW = ();
  my $s   = $EV->new(undef);
  my $ok  = eval { $s->connect_info([ AnswerBroker->new($answer), { pool_size => 4 } ]); 1 };
  my $err = $@;
  ok !$ok, "pool_size 3 in $label, 4 beside the broker: the connect info is refused";
  like $err, qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer, with different values/,
    '... naming pool_size, so neither size wins silently';
  is scalar(@EV::Pg::NEW), 0, '... and nothing was handed to EV::Pg';
}

# ---------------------------------------------------------------------------
# 3. DBD attributes beside the broker: dropped, as in DBI-form connect info.
# ---------------------------------------------------------------------------

{
  my %dbd = (pg_enable_utf8 => 1, pg_server_prepare => 0, AutoCommit => 1, RaiseError => 1);

  # The reference: what this transport makes of the same keys in DBI-form
  # connect info. libpq knows none of them; one of them in the conninfo string
  # makes it refuse the connection ("invalid connection option").
  my $by_dsn = transport([ 'dbi:Pg:dbname=appdb;host=db.example;port=5433', 'app', 's3cret', { %dbd } ]);
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($by_dsn)) }, \%STATIC,
    'DBI-form connect info with DBD attributes: none of them reaches libpq'
    or diag $@;

  my $s = eval { transport([ static(), { %dbd } ]) };
  ok $s, 'the same DBD attributes beside a broker: the connect info is taken' or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%STATIC,
    '... and none of them reaches libpq on a pool connection'
    or diag $@;
  is_deeply scalar eval { parse_conninfo(listen_conninfo($s)) }, \%STATIC,
    '... nor on the listen connection'
    or diag $@;
  is_deeply scalar eval { parse_conninfo($s->_conninfo_string) }, \%STATIC,
    '... nor in _conninfo_string'
    or diag $@;
  is scalar eval { $s->pool->max_size }, 5, '... and the pool keeps its default size' or diag $@;

  # They are kept apart, where core's accessor answers for them, and gone with
  # the next connect info.
  is_deeply scalar eval { $s->_access_broker_call_attributes }, \%dbd,
    'the DBD attributes beside the broker are what _access_broker_call_attributes answers';
  $s->connect_info([ static() ]);
  is_deeply $s->_access_broker_call_attributes, {},
    '... and a later connect info without them leaves none behind';
}

# ---------------------------------------------------------------------------
# 4. The broker stays attached in the two-element form.
# ---------------------------------------------------------------------------

{
  my $broker = AnswerBroker->new({ %ANSWER });
  my $s = eval { transport([ $broker, { pool_size => 2 } ]) };
  ok $s, '[ $broker, { pool_size => 2 } ]: the connect info is taken' or diag $@;

  SKIP: {
    skip 'the connect info was refused', 3 unless $s;
    is $s->access_broker, $broker, '... and the broker is attached';
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%ANSWER,
      '... the first pool connection uses its answer'
      or diag $@;

    $broker->{answer} = { %ANSWER, user => 'app-2', password => 'pw-2' };
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) },
      { %ANSWER, user => 'app-2', password => 'pw-2' },
      '... and the second one the ROTATED answer: the broker is asked per connection'
      or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 5. The declaration, bound to the behaviour.
# ---------------------------------------------------------------------------

ok scalar(grep { $_ eq 'broker_connect_options' } $EV->transport_capabilities),
  "the transport declares 'broker_connect_options'";
ok $EV->_takes_broker_connect_options,
  '... which is what core asks before handing it [ $broker, \%options ]';

{
  # The same transport without the declaration. Its connect_info must refuse
  # the settings through core's gate: the override takes them because the
  # transport promised to apply them, not because the form happens to parse.
  package UndeclaredTransport;
  use base 'DBIO::PostgreSQL::EV::Storage';
  sub transport_capabilities {
    return grep { $_ ne 'broker_connect_options' } shift->next::method;
  }
}

for my $case (
  [ 'pool_size',       { pool_size => 3 },      qr/: pool_size\b/ ],
  [ 'a DBD attribute', { pg_enable_utf8 => 1 }, qr/: pg_enable_utf8\b/ ],
) {
  my ($label, $beside, $names_re) = @$case;
  @EV::Pg::NEW = ();
  my $s   = UndeclaredTransport->new(undef);
  my $ok  = eval { $s->connect_info([ static(), $beside ]); 1 };
  my $err = $@;
  ok !$ok, "without the declaration, $label beside a broker is refused";
  like $err, qr/does not take connection settings beside an AccessBroker \(it does not declare 'broker_connect_options'/,
    '... by core\'s gate, saying what is missing';
  like $err, $names_re, '... and naming the setting';
  ok !$s->access_broker, '... no broker is attached';
  is scalar(@EV::Pg::NEW), 0, '... and nothing was handed to EV::Pg';
}

{
  # Only the owner's own options beside the broker: nothing for a backend to
  # apply, so nothing to refuse -- it is the bare broker form.
  my $broker = static();
  my $s = eval { transport([ $broker, { async => 'ev', quote_names => 1 } ], 'UndeclaredTransport') };
  ok $s, 'without the declaration, a hash holding only the owner\'s options is taken' or diag $@;
  is scalar eval { $s->access_broker }, $broker, '... as the broker form';
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%STATIC,
    '... and none of those options reaches libpq'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 6. DBI-form connect info: the fifth element.
# ---------------------------------------------------------------------------

{
  my $dsn = 'dbi:Pg:dbname=appdb;host=db.example;port=5433';

  for my $case (
    [ 'slot [3] alone',                 [ { pool_size => 3 } ],                               3 ],
    [ 'slot [4] alone',                 [ {}, { pool_size => 3 } ],                           3 ],
    [ 'slot [4] with no slot [3]',      [ undef, { pool_size => 3 } ],                        3 ],
    [ 'both slots: [4] wins',           [ { pool_size => 2 }, { pool_size => 3 } ],           3 ],
    [ 'slot [3], [4] without a size',   [ { pool_size => 3 }, { pg_enable_utf8 => 1 } ],      3 ],
    [ 'no size in either slot',         [ { pg_enable_utf8 => 1 }, { RaiseError => 1 } ],     undef ],
  ) {
    my ($label, $attr_slots, $want) = @$case;
    my $info = dbi_to_conninfo([ $dsn, 'app', 's3cret', @$attr_slots ]);
    is $info->[0]{pool_size}, $want,
      "dbi_to_conninfo, $label: pool_size is " . ($want // 'not set');
    my %libpq = %{ $info->[0] };
    delete $libpq{pool_size};
    is_deeply \%libpq, \%STATIC, '... and the libpq parameters are the DSN parts, user and password only';
  }

  # Through the owning sync storage, the way a user gives the fifth element.
  my $schema = BrokerSchema->connect($dsn, 'app', 's3cret', { async => 'ev' }, { pool_size => 3 });
  my $async  = eval { $schema->storage->async };
  isa_ok $async, $EV, 'connect($dsn, $user, $pass, { async => ev }, { pool_size => 3 }): the transport'
    or diag $@;
  is scalar eval { $async->pool->max_size }, 3,
    '... has a pool of three connections: the fifth element reaches the pool'
    or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%STATIC,
    '... and pool_size does not reach libpq'
    or diag $@;
}

done_testing;
