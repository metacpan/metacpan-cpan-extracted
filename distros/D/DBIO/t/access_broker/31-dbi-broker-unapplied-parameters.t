# ABSTRACT: A sync storage does not connect with a broker's hash answer carrying a parameter it would not apply
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::Test::Future ();

# OFFLINE (karr k298; maintainer's decisions of 2026-10-06). Seen live on
# PostgreSQL with ssl off: a broker answering a hash with sslmode => 'require'.
# The ev pool refused the server ("server does not support SSL, but SSL was
# required"); the sync dbh of the same schema connected without SSL and said
# nothing.
#
# WHY: of a hash a DBI storage builds dbname, host and port into the DSN, and
# nothing else. Every other key it does not consume itself goes to
# DBI->connect as an attribute -- and a DBD keeps a lowercase attribute it does
# not know without a word. A parameter of the database client (sslmode,
# connect_timeout, sslrootcert, ...) is therefore lost exactly where it
# matters: the connection is opened, without it. An async transport hands the
# same key to its client, so the two connections of one schema differ in what
# the broker asked for.
#
# WHEN: the storage refuses where it would open that connection, and nowhere
# before. The first form of k298 refused in connect_info already. That broke
# the answer an async transport documents for its client's parameters -- one
# hash for every storage -- at Schema->connect, also for a caller who only
# ever uses the pool (found in dbio-postgresql-ev). The answer is the
# transport's to use; the sync storage has to answer for its own connection
# only.
#
# What this file claims:
#   1. A hash answer with a key that is neither consumed by the storage nor
#      the name of a DBI attribute configures the storage -- connect_info
#      lives and keeps the DSN the answer names -- and stops the storage's own
#      connection: the first one and every later one, attached directly or
#      through a HostBound view, by the generic and by a driver storage, with
#      a dsn key and with a dbname. The error names the broker class and the
#      KEYS, all of them, never a value, and DBI->connect is not called.
#      (Until the second decision of 2026-10-06 this claim was "refused at
#      connect_info and at every later connection". What is kept: never a
#      connection without the parameter. What is replaced: the moment.)
#   2. The name of a DBI attribute is: one starting with an uppercase letter
#      (DBI's own), one starting with private_, dbi_ or dbd_, and one starting
#      with the prefix of the DBD the DSN names. Another DBD's prefix is not
#      one, and neither is a lowercase name on a DBD whose prefix nobody
#      declared -- refused, since it cannot be told from a client parameter.
#   3. What a hash answer may carry still connects, and still reaches
#      DBI->connect as before: DBI attributes, the storage's and the SQL
#      maker's options, async, pool_size, ignore_version; a key set to undef
#      or to the empty string, which names no parameter.
#   4. The ways out the error names connect: the DBI form with the parameter
#      inside its DSN -- whose attribute hash is DBI's by its place, not
#      looked into, so a DBD attribute the storage cannot recognise goes
#      there -- and a broker answering by the storage that asks. The error
#      does not name a dsn key in the hash: this storage takes one, as before,
#      but an ev transport does not read it (dbio-postgresql-ev k79).
#   5. A driver storage declares the prefix of a DBD that DBI's registry does
#      not know (_dbd_attribute_prefixes).
#   6. With an async mode, the answer is the transport's to use: the owning
#      storage is configured, its backend is built, asks the broker itself and
#      opens a pooled connection with the whole answer, the parameter
#      included, and DBI->connect is not called. The owner's own dbh -- its
#      first access -- throws. (Until the second decision of 2026-10-06 this
#      claim was "an async mode does not defer the refusal: connect_info
#      throws all the same".)
#
# The same for a parameter given BESIDE the broker (karr k307):
# t/access_broker/32-dbi-broker-unapplied-options-beside.t.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; fake driver storages registered for the DBD name 'ExampleP' (in
# DBI's prefix registry as examplep_, and no DBIO driver's) and for
# 'K298Fake' (in nobody's); an async mode whose transport runs core's own
# connect_info and records every pooled connection it would build; no DBD is
# loaded and no database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

# A broker answering each storage in its own shape.
{
  package T::TwoShapeBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %arg) = @_; bless { %arg }, $class }
  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    return $storage->isa('DBIO::Storage::DBI') ? $self->{dbi} : $self->{native};
  }
}

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ExampleP => __PACKAGE__);
}

# A DBD DBI's prefix registry does not know ...
{
  package T::Unknown::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(K298Fake => __PACKAGE__);
}

# ... and a driver storage that declares its prefix.
{
  package T::Declaring::Storage;
  use base 'DBIO::Storage::DBI';
  sub _dbd_attribute_prefixes { 'k298fake_' }
}

# An async transport: core's own connect_info, and a pool that records the
# conninfo of every connection instead of opening it.
{
  package T::RecordingPool;
  use base 'DBIO::Storage::PoolBase';
  our @BUILT;
  sub _create_connection { my ($self, $conninfo) = @_; push @BUILT, $conninfo; bless {}, 'T::Conn' }
  sub _transform_conninfo { $_[1] }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub disconnect   { delete $_[0]{pool}; 1 }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::RecordingPool->new(
      size              => 5,
      future_class      => $self->future_class,
      conninfo_provider => $self->_conninfo_provider,
    );
  }
}

T::Driver::Storage->register_async_mode(k298loop => 'T::Backend');

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

is scalar('DBI'->driver_prefix('DBD::ExampleP')), 'examplep_',
  'premise: DBI knows the prefix of DBD::ExampleP without loading it';
ok !$INC{'DBD/ExampleP.pm'}, '... the DBD is not loaded';
is scalar('DBI'->driver_prefix('DBD::K298Fake')), undef,
  'premise: and none for DBD::K298Fake';

my ($USER, $PASSWORD) = ('k298-user', 'k298-secret');
# every value of an answer in this file
my $VALUE = qr/k298-(?:user|secret|db|host|value)|dbi:ExampleP|dbi:K298Fake/;

my $DSN = 'dbi:ExampleP:dbname=k298-db;host=k298-host';
my %LOGIN = (user => $USER, password => $PASSWORD);

sub good_answer { [ $DSN, $USER, $PASSWORD, {} ] }

sub refused {
  my ($broker_class, @keys) = @_;
  my $keys = join ', ', @keys;
  return qr/AccessBroker \Q$broker_class\E answered connect info with parameter\(s\) a DBI storage does not apply \(\Q$keys\E\)/;
}

# The attribute hash DBI->connect was handed last, without the storage's own
# defaults.
sub connect_attrs {
  my %attrs = %{ $CONNECTS[-1][3] || {} };
  delete @attrs{qw( AutoCommit PrintError RaiseError ShowErrorStatement )};
  return \%attrs;
}

# ---------------------------------------------------------------------------
# 1. Configured, and no connection of the storage's own.
# ---------------------------------------------------------------------------
# label => [ storage classes, answer, the keys the error names ]
my @BOTH   = ('DBIO::Storage::DBI', 'T::Driver::Storage');
my @DRIVER = ('T::Driver::Storage');   # a dbname needs the storage of a driver

my %REFUSED = (
  'sslmode beside a dsn' => [ \@BOTH,
    sub { { dsn => $DSN, %LOGIN, sslmode => 'k298-value' } },
    [ 'sslmode' ] ],
  'sslmode beside dbname and host' => [ \@DRIVER,
    sub { { dbname => 'k298-db', host => 'k298-host', %LOGIN, sslmode => 'k298-value' } },
    [ 'sslmode' ] ],
  'several client parameters, among what a hash may carry' => [ \@BOTH,
    sub { {
      dsn => $DSN, %LOGIN,
      sslmode => 'k298-value', connect_timeout => 'k298-value',
      application_name => 'k298-value', sslrootcert => 'k298-value', charset => 'k298-value',
      RaiseError => 1, examplep_trace => 1, quote_names => 1, on_connect_do => [ 'SELECT 1' ],
    } },
    [ qw( application_name charset connect_timeout sslmode sslrootcert ) ] ],
  "an async transport's attrs key" => [ \@BOTH,
    sub { { dsn => $DSN, %LOGIN, attrs => { examplep_trace => 'k298-value' } } },
    [ 'attrs' ] ],
  'the prefix of another DBD' => [ \@BOTH,
    sub { { dsn => $DSN, %LOGIN, pg_enable_utf8 => 'k298-value' } },
    [ 'pg_enable_utf8' ] ],
  'a lowercase key on a DBD whose prefix nobody declared' => [ [ 'DBIO::Storage::DBI', 'T::Unknown::Storage' ],
    sub { { dsn => 'dbi:K298Fake:dbname=k298-db', %LOGIN, k298fake_trace => 'k298-value' } },
    [ 'k298fake_trace' ] ],
);

for my $label (sort keys %REFUSED) {
  my ($classes, $answer, $keys) = @{ $REFUSED{$label} };

  for my $class (@$classes) {
    my $t = "$class, $label";

    {
      my $storage = $class->new(undef);
      local @CONNECTS;
      lives_ok { $storage->connect_info([ T::ScriptBroker->new($answer) ]) }
        "$t: connect_info configures the storage";
      like $storage->_dbi_connect_info->[0], qr/^dbi:(?:ExampleP|K298Fake):dbname=k298-db/,
        "$t: ... which keeps the DSN the answer names";
      throws_ok { $storage->_connect } refused('T::ScriptBroker', @$keys),
        "$t: its own connection throws, naming the broker class and the keys";
      unlike "$@", $VALUE, "$t: naming no value of the answer";
      throws_ok { $storage->_connect } refused('T::ScriptBroker', @$keys),
        "$t: every connection after it throws the same";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }

    {
      my $storage = $class->new(undef);
      $storage->connect_info([ T::ScriptBroker->new(\&good_answer, \&good_answer, $answer) ]);
      local @CONNECTS;
      lives_ok { $storage->_connect } "$t as a later answer: a connection before it is opened";
      throws_ok { $storage->_connect } refused('T::ScriptBroker', @$keys),
        "$t as a later answer: the next connection throws";
      unlike "$@", $VALUE, "$t as a later answer: naming no value, of this answer or an earlier one";
      is scalar @CONNECTS, 1, "$t as a later answer: DBI->connect is not called again";
    }

    {
      my $storage = $class->new(undef);
      my $view = T::ScriptBroker->new($answer)->for_host('k298-host-replica');
      local @CONNECTS;
      lives_ok { $storage->connect_info([ $view ]) }
        "$t through a HostBound view: connect_info configures the storage";
      throws_ok { $storage->_connect } refused('DBIO::AccessBroker::HostBound', @$keys),
        "$t through a HostBound view: its own connection throws, naming the view and the same keys";
      unlike "$@", $VALUE, "$t through a HostBound view: naming no value of the answer";
      throws_ok { $storage->_connect } refused('DBIO::AccessBroker::HostBound', @$keys),
        "$t through a HostBound view: every connection after it throws the same";
      is scalar @CONNECTS, 0, "$t through a HostBound view: DBI->connect is not called";
    }
  }
}

# The way a caller meets it: the first access to the dbh. And the error says
# what to do.
{
  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(sub { { dsn => $DSN, %LOGIN, sslmode => 'k298-value' } }) ]);
  local @CONNECTS;
  throws_ok { $storage->dbh } refused('T::ScriptBroker', 'sslmode'),
    'the first access to the dbh throws';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called';
  like "$@", qr/Answer the DBI form .* inside the DSN .* or answer by the storage that asks \(connect_info_for_storage\)/s,
    'the error names the two ways out: the DBI form with the parameter inside the DSN, an answer by the storage that asks';
  unlike "$@", qr/dsn\s*=>/,
    '... and no dsn key in the hash, which an ev transport does not read';
}

# ---------------------------------------------------------------------------
# 2./3. What a hash answer may carry (control).
# ---------------------------------------------------------------------------
# label => [ what the answer carries beside dsn and login, what of it
# DBI->connect gets as attributes ]
my %CARRIED = (
  'nothing' => [ {}, {} ],
  "DBI's own attributes" => [
    { LongReadLen => 4096, FetchHashKeyName => 'NAME_lc', Callbacks => {} },
    { LongReadLen => 4096, FetchHashKeyName => 'NAME_lc', Callbacks => {} } ],
  "an attribute with the DBD's prefix" => [
    { examplep_trace => 1 }, { examplep_trace => 1 } ],
  'private_, dbi_ and dbd_ attributes' => [
    { private_app_tag => 'x', dbi_connect_method => 'connect', dbd_verbose => 2 },
    { private_app_tag => 'x', dbi_connect_method => 'connect', dbd_verbose => 2 } ],
  "the storage's options" => [
    { on_connect_do => [ 'SELECT 1' ], auto_savepoint => 1, unsafe => 1, cursor_class => 'DBIO::Storage::DBI::Cursor' }, {} ],
  "the SQL maker's options" => [
    { quote_names => 1, name_sep => '.' }, {} ],
  'an async mode and pool_size' => [
    { async => 'immediate', pool_size => 3 }, {} ],
  'pool_size without a mode' => [
    { pool_size => 3 }, { pool_size => 3 } ],
  'ignore_version' => [
    { ignore_version => 1 }, {} ],
  'a client parameter set to undef or to the empty string' => [
    { sslmode => undef, connect_timeout => '' }, { sslmode => undef, connect_timeout => '' } ],
);

for my $class (@BOTH) {
  for my $label (sort keys %CARRIED) {
    my ($carried, $attrs) = @{ $CARRIED{$label} };
    my $t = "$class, a hash answer carrying $label";

    my $storage = $class->new(undef);
    local @CONNECTS;
    lives_ok {
      $storage->connect_info([ T::ScriptBroker->new(sub { { dsn => $DSN, %LOGIN, %$carried } }) ]);
      $storage->_connect;
    } "$t: connects";
    is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ $DSN, $USER, $PASSWORD ],
      "$t: ... to the DSN the broker answered, with its credentials";
    is_deeply connect_attrs(), $attrs, "$t: ... and DBI->connect gets what it got before";
  }
}

# The built-in broker of connection parameters, directly and through a view.
for my $case (
  [ 'Static', sub { $_[0] }, 'dbi:ExampleP:dbname=k298-db;host=k298-host;port=5433' ],
  [ 'Static through a HostBound view', sub { $_[0]->for_host('k298-host-replica') },
    'dbi:ExampleP:dbname=k298-db;host=k298-host-replica;port=5433' ],
) {
  my ($label, $attach, $dsn) = @$case;
  my $storage = T::Driver::Storage->new(undef);
  local @CONNECTS;
  lives_ok {
    $storage->connect_info([ $attach->(DBIO::AccessBroker::Static->new(
      dbname => 'k298-db', host => 'k298-host', port => 5433, username => $USER, password => $PASSWORD,
    )) ]);
    $storage->_connect;
  } "$label: connects";
  is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ $dsn, $USER, $PASSWORD ],
    "$label: ... with the DSN built for the driver";
}

# ---------------------------------------------------------------------------
# 4. The ways out, and the dsn key of a hash this storage still takes.
# ---------------------------------------------------------------------------
my $DSN_SSL = "$DSN;sslmode=require";

for my $class (@BOTH) {
  for my $case (
    [ 'the parameter inside the DSN of the DBI form',
      sub { [ $DSN_SSL, $USER, $PASSWORD, {} ] }, {} ],
    [ "a lowercase attribute in the DBI form's attribute hash",
      sub { [ $DSN_SSL, $USER, $PASSWORD, { k298fake_trace => 1 } ] }, { k298fake_trace => 1 } ],
    [ 'the parameter inside the dsn key of a hash (taken as before; no way out the error names)',
      sub { { dsn => $DSN_SSL, %LOGIN } }, {} ],
  ) {
    my ($label, $answer, $attrs) = @$case;
    my $t = "$class, $label";

    my $storage = $class->new(undef);
    local @CONNECTS;
    lives_ok {
      $storage->connect_info([ T::ScriptBroker->new($answer) ]);
      $storage->_connect;
    } "$t: connects";
    is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ $DSN_SSL, $USER, $PASSWORD ],
      "$t: ... with the DSN as the broker answered it";
    is_deeply connect_attrs(), $attrs, "$t: ... and the attributes of the answer";
  }
}

# ---------------------------------------------------------------------------
# 5. A driver storage declares the prefix of its DBD.
# ---------------------------------------------------------------------------
{
  my $answer = sub { { dsn => 'dbi:K298Fake:dbname=k298-db', %LOGIN, k298fake_trace => 1, @_ } };

  my $storage = T::Declaring::Storage->new(undef);
  local @CONNECTS;
  lives_ok {
    $storage->connect_info([ T::ScriptBroker->new($answer) ]);
    $storage->_connect;
  } 'a storage declaring the prefix of its DBD: an attribute with it connects';
  is_deeply connect_attrs(), { k298fake_trace => 1 }, '... and reaches DBI->connect';

  $storage = T::Declaring::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(sub { $answer->(sslmode => 'k298-value') }) ]);
  throws_ok { $storage->_connect } refused('T::ScriptBroker', 'sslmode'),
    '... and a client parameter beside it is refused all the same, alone';
}

# ---------------------------------------------------------------------------
# 6. With an async mode the answer is the transport's to use.
# ---------------------------------------------------------------------------
{
  my %native = (dbname => 'k298-db', host => 'k298-host', %LOGIN, sslmode => 'k298-value');

  # one answer for every storage that asks
  my $broker  = T::ScriptBroker->new(sub { +{ %native } });
  my $storage = T::Driver::Storage->new(undef);
  local @CONNECTS;
  local @T::RecordingPool::BUILT;

  lives_ok { $storage->connect_info([ $broker, { async => 'k298loop' } ]) }
    'one hash with a client parameter for every storage, an async mode beside the broker: connect_info configures the owner';
  is $storage->_async_mode, 'k298loop', '... with the mode';
  is $storage->_dbi_connect_info->[0], 'dbi:ExampleP:dbname=k298-db;host=k298-host',
    '... and the DSN built from the answer, which driver detection reads';

  my $backend = eval { $storage->async };
  isa_ok $backend, 'T::Backend', '... ->async: the transport' or diag $@;

  SKIP: {
    skip 'the transport was not built', 4 unless $backend;
    is_deeply $backend->connect_info, [ $broker ], '... handed the broker, to ask it itself';

    my $f = $backend->pool->acquire;
    ok !$f->is_failed, '... a pooled connection is opened';
    is_deeply \@T::RecordingPool::BUILT, [ { %native } ],
      '... with the whole answer, the parameter included';
    is scalar @CONNECTS, 0, '... and none of this called DBI->connect';
  }

  throws_ok { $storage->dbh } refused('T::ScriptBroker', 'sslmode'),
    "the owner's own dbh, at its first access, throws";
  unlike "$@", $VALUE, '... naming no value of the answer';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called';

  # each storage its own shape: the DBI storage the parameter inside a DSN
  $storage = T::Driver::Storage->new(undef);
  lives_ok {
    $storage->connect_info([
      T::TwoShapeBroker->new(native => { %native }, dbi => [ $DSN_SSL, $USER, $PASSWORD, {} ]),
      { async => 'k298loop' },
    ]);
    $storage->_connect;
  } 'a broker answering the DBI storage the parameter inside a DSN: configured and connected';
  is $CONNECTS[0][0], $DSN_SSL, '... to the DSN carrying the parameter';

  @T::RecordingPool::BUILT = ();
  ok !$storage->async->pool->acquire->is_failed, '... while the transport is answered the hash';
  is_deeply \@T::RecordingPool::BUILT, [ { %native } ], '... and opens its connection with the parameter';
}

done_testing;
