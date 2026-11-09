# ABSTRACT: The broker's refusals of what is no broker, no host and no implementation
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use Scalar::Util ();
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Util ();
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::HostBound;

# OFFLINE (karr k270). Small refusals around the AccessBroker that no test
# executed -- each a line that throws, or a predicate, read but never run:
#
#   1. a broker class that implements neither connect_info_for nor
#      connect_info_for_storage: the base class throws, naming the class and
#      the method -- asked directly, through every way the storage asks, and
#      through a HostBound view;
#   2. set_access_broker refuses what is no object and what is no
#      DBIO::AccessBroker, and leaves the storage as it was -- on the sync
#      storage and on an async backend;
#   3. HostBound refuses to be built without a broker, over something that is
#      no broker, and without a host -- directly and through for_host;
#   4. DBIO::Util::is_access_broker answers 1 for a broker, a subclass and a
#      view, and 0 for everything else -- a class name and a look-alike with
#      the broker's methods among it;
#   5. a broker unsafe for transactions for a reason of its own, without
#      rotating credentials: the SYNC storage's txn_begin and txn_do name
#      "broker-specific transaction safety constraints", refused or let
#      through with the override (the async twin is 22-async-txn-unsafe-broker.t;
#      the rotating case on the sync storage is 02-vault.t);
#   6. the plain hash connect form without a broker, on a storage registered
#      for a driver: what the hash holds beside the connection parameters
#      stays what it is -- a DBI attribute, a storage option -- and a dbname
#      that is a whole DSN is taken as the DSN. (The DSN built from dbname,
#      host and port is 19-connect-params-without-dbname.t.)
#
# THE SUBSTITUTIONS: DBIO::Test::Storage and a fake driver storage registered
# for the DBD name 'K270Fake'; DBI->connect records its arguments.

delete @ENV{qw( DBI_DSN DBI_DRIVER DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS )};

{
  package T::BareBroker;          # implements nothing
  use base 'DBIO::AccessBroker';
}

{
  package T::HashBroker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for { +{ dbname => 'app', user => 'u', password => 'p' } }
}

{
  package T::UnsafeBroker;        # no rotation, unsafe for a reason of its own
  use base 'DBIO::AccessBroker';
  sub connect_info_for    { [ 'dbi:K270Fake:dbname=app', 'u', 'p', {} ] }
  sub is_transaction_safe { 0 }
}

{
  package T::LookAlike;           # every method of a broker, and no broker
  sub new                     { bless {}, shift }
  sub connect_info_for        { [ 'dbi:K270Fake:dbname=app', 'u', 'p', {} ] }
  sub connect_info_for_storage { $_[0]->connect_info_for }
  sub current_connect_info_for_storage { $_[0]->connect_info_for }
  sub set_storage             { $_[0]{storage} = $_[1] }
  sub needs_refresh           { 0 }
  sub is_transaction_safe     { 1 }
}

{
  package T::AsyncBackend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
}

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(K270Fake => __PACKAGE__);
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

# ---------------------------------------------------------------------------
# 1. A broker class that implements nothing.
# ---------------------------------------------------------------------------
{
  my $unimplemented = qr/T::BareBroker must implement connect_info_for\(\)/;
  my $broker  = T::BareBroker->new;
  my $storage = DBIO::Storage::DBI->new(undef);

  throws_ok { $broker->connect_info_for } $unimplemented,
    'connect_info_for on a broker that implements none: throws, naming the class and the method';
  throws_ok { $broker->connect_info_for_storage($storage) } $unimplemented,
    '... and so does connect_info_for_storage, which hands on to it';
  throws_ok { $broker->current_connect_info_for } $unimplemented,
    '... and current_connect_info_for';
  throws_ok { $broker->current_connect_info_for_storage($storage) } $unimplemented,
    '... and current_connect_info_for_storage';

  throws_ok { $broker->for_host('replica.example')->connect_info_for } $unimplemented,
    'a HostBound view over it throws the same, naming the broker below the view';
  throws_ok { $broker->for_host('replica.example')->connect_info_for_storage($storage) }
    $unimplemented, '... also when asked for a storage';

  throws_ok { $storage->connect_info([ T::BareBroker->new ]) } $unimplemented,
    'a sync storage connected with it throws the same at connect_info';

  my $backend = T::AsyncBackend->new(undef);
  throws_ok { $backend->connect_info([ T::BareBroker->new ]) } $unimplemented,
    '... and so does an async backend';
}

# ---------------------------------------------------------------------------
# 2. set_access_broker takes a DBIO::AccessBroker object and nothing else.
# ---------------------------------------------------------------------------
my $NO_OBJECT = qr/set_access_broker\(\) requires a broker object/;
my $NO_BROKER = qr/set_access_broker\(\) requires a DBIO::AccessBroker instance/;

for my $kind (
  [ 'a sync storage'   => sub { DBIO::Storage::DBI->new(undef) } ],
  [ 'an async backend' => sub { T::AsyncBackend->new(undef) } ],
) {
  my ($name, $new) = @$kind;
  my $look_alike = T::LookAlike->new;

  for my $case (
    [ 'undef'                   => undef,                         $NO_OBJECT ],
    [ 'a class name'            => 'DBIO::AccessBroker::Static',  $NO_OBJECT ],
    [ 'a hash of parameters'    => { dbname => 'app' },           $NO_OBJECT ],
    [ 'a code reference'        => sub { 1 },                     $NO_OBJECT ],
    [ 'an object of another class' => T::Handle->new,             $NO_BROKER ],
    [ 'a look-alike with a broker\'s methods' => $look_alike,    $NO_BROKER ],
  ) {
    my ($what, $value, $refusal) = @$case;
    my $t = "$name, set_access_broker with $what";

    # on a storage with no broker
    {
      my $storage = $new->();
      throws_ok { $storage->set_access_broker($value) } $refusal, "$t: refused";
      is $storage->access_broker, undef, "$t: nothing is attached";
      is $storage->access_broker_mode, undef, "$t: and no mode is set";
    }

    # on a storage that has one
    {
      my $storage = $new->();
      my $broker  = T::HashBroker->new;
      $storage->set_access_broker($broker, 'read');
      throws_ok { $storage->set_access_broker($value) } $refusal,
        "$t, over an attached broker: refused";
      is $storage->access_broker, $broker, "$t: the attached broker stays";
      is $storage->access_broker_mode, 'read', "$t: and so does its mode";
    }
  }
  is $look_alike->{storage}, undef, "$name: the refused look-alike was never told of a storage";

  # What it does take.
  {
    my $storage = $new->();
    my $broker  = T::HashBroker->new;
    is $storage->set_access_broker($broker), $storage, "$name: set_access_broker returns the storage";
    is $storage->access_broker, $broker, "$name: the broker is attached";
    is $storage->access_broker_mode, 'write', "$name: in write mode when none is given";
    is_deeply [ map { Scalar::Util::refaddr($_) } $broker->_attached_storages ], [ Scalar::Util::refaddr($storage) ],
      "$name: and knows its storage";

    my $view = $broker->for_host('replica.example');
    $storage->set_access_broker($view, 'read');
    is $storage->access_broker, $view, "$name: a HostBound view is a broker and is attached";
    is $storage->access_broker_mode, 'read', "$name: in the mode given";
  }
}

# ---------------------------------------------------------------------------
# 3. HostBound: a broker, and a host.
# ---------------------------------------------------------------------------
{
  my $broker = T::HashBroker->new;

  throws_ok { DBIO::AccessBroker::HostBound->new(host => 'db.example') }
    qr/HostBound requires 'broker'/, 'HostBound without a broker: refused';
  throws_ok { DBIO::AccessBroker::HostBound->new(broker => undef, host => 'db.example') }
    qr/HostBound requires 'broker'/, '... and with an undefined one';

  for my $case (
    [ 'a class name'           => 'DBIO::AccessBroker::Static' ],
    [ 'a hash of parameters'   => { dbname => 'app' } ],
    [ 'an object of another class' => T::Handle->new ],
    [ 'a look-alike with a broker\'s methods' => T::LookAlike->new ],
  ) {
    my ($what, $value) = @$case;
    throws_ok { DBIO::AccessBroker::HostBound->new(broker => $value, host => 'db.example') }
      qr/HostBound 'broker' must be a DBIO::AccessBroker instance/,
      "HostBound over $what: refused";
  }

  throws_ok { DBIO::AccessBroker::HostBound->new(broker => $broker) }
    qr/HostBound requires 'host'/, 'HostBound without a host: refused';
  throws_ok { DBIO::AccessBroker::HostBound->new(broker => $broker, port => 5433) }
    qr/HostBound requires 'host'/, '... a port alone is no host';

  throws_ok { $broker->for_host } qr/HostBound requires 'host'/,
    'for_host without a host: refused';
  throws_ok { $broker->for_host(undef) } qr/HostBound requires 'host'/,
    '... with an undefined host';
  throws_ok { $broker->for_host({ port => 5433 }) } qr/HostBound requires 'host'/,
    '... with a hash that has a port and no host';
  throws_ok { $broker->for_host(port => 5433) } qr/HostBound requires 'host'/,
    '... with a list that has a port and no host';

  # What it does take: all three forms of for_host, and a view over a view.
  for my $case (
    [ 'a host string'         => [ 'db.example' ],                          'db.example', undef ],
    [ 'a hash'                => [ { host => 'db.example', port => 5433 } ], 'db.example', 5433 ],
    [ 'a list'                => [ host => 'db.example', port => 5433 ],     'db.example', 5433 ],
  ) {
    my ($what, $args, $host, $port) = @$case;
    my $view = $broker->for_host(@$args);
    isa_ok $view, 'DBIO::AccessBroker::HostBound', "for_host with $what";
    is $view->host, $host, "for_host with $what: the host";
    is $view->port, $port, "for_host with $what: the port";
    is $view->underlying_broker, $broker, "for_host with $what: over the broker";
  }

  my $outer = $broker->for_host('inner.example')->for_host('outer.example');
  is_deeply $outer->connect_info_for,
    { dbname => 'app', user => 'u', password => 'p', host => 'outer.example' },
    'a view over a view is a view: the outer host is the one bound in';
}

# ---------------------------------------------------------------------------
# 4. DBIO::Util::is_access_broker.
# ---------------------------------------------------------------------------
{
  my $static = DBIO::AccessBroker::Static->new(dbname => 'app');

  for my $case (
    [ 'a DBIO::AccessBroker'      => DBIO::AccessBroker->new ],
    [ 'a Static broker'           => $static ],
    [ 'a broker subclass'         => T::HashBroker->new ],
    [ 'a HostBound view'          => $static->for_host('db.example') ],
  ) {
    my ($what, $value) = @$case;
    is DBIO::Util::is_access_broker($value), 1, "is_access_broker: $what is one";
  }

  for my $case (
    [ 'undef'                      => undef ],
    [ 'an empty string'            => '' ],
    [ 'the class name'             => 'DBIO::AccessBroker' ],
    [ 'a subclass name'            => 'DBIO::AccessBroker::Static' ],
    [ 'a DSN'                      => 'dbi:K270Fake:dbname=app' ],
    [ 'a hash of parameters'       => { dbname => 'app' } ],
    [ 'an array'                   => [ $static ] ],
    [ 'a code reference'           => sub { $static } ],
    [ 'an object of another class' => T::Handle->new ],
    [ 'a look-alike with a broker\'s methods' => T::LookAlike->new ],
  ) {
    my ($what, $value) = @$case;
    is DBIO::Util::is_access_broker($value), 0, "is_access_broker: $what is none";
  }
}

# ---------------------------------------------------------------------------
# 5. Unsafe for a reason of its own, on the sync storage.
# ---------------------------------------------------------------------------
my $OWN = 'broker-specific transaction safety constraints';

for my $case (
  [ 'a broker unsafe for a reason of its own'
      => sub { T::UnsafeBroker->new }, 'T::UnsafeBroker' ],
  [ 'a HostBound view over it'
      => sub { T::UnsafeBroker->new->for_host('replica.example') }, 'DBIO::AccessBroker::HostBound' ],
) {
  my ($name, $new_broker, $class) = @$case;
  my $refusal = qr/Refusing to start a transaction with unsafe AccessBroker \Q$class\E: \Q$OWN\E can break transactional consistency/;

  ok !$new_broker->()->has_rotating_credentials, "$name: it does not rotate credentials";
  ok !$new_broker->()->is_transaction_safe, "$name: and is not transaction-safe";

  for my $entry (qw(txn_begin txn_do)) {
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };

    my $schema = DBIO::Test->init_schema(no_deploy => 1);
    my $storage = $schema->storage;
    $storage->set_access_broker($new_broker->());

    my $ran = 0;
    throws_ok {
      $entry eq 'txn_begin' ? $storage->txn_begin : $storage->txn_do(sub { $ran++ });
    } $refusal, "$name, $entry: refused, naming the broker and its own reason";
    isa_ok $@, 'DBIO::Exception', "$name, $entry: the refusal";
    unlike "$@", qr/credential rotation/, "$name, $entry: which does not blame a rotation";
    is $ran, 0, "$name, $entry: the coderef does not run" if $entry eq 'txn_do';
    is $storage->transaction_depth, 0, "$name, $entry: no transaction is open";
    is_deeply \@warned, [], "$name, $entry: nothing is warned";
  }

  for my $entry (qw(txn_begin txn_do)) {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };

    my $schema = DBIO::Test->init_schema(no_deploy => 1);
    my $storage = $schema->storage;
    $storage->set_access_broker($new_broker->());

    my $ran = 0;
    lives_ok {
      if ($entry eq 'txn_begin') { $storage->txn_begin; $ran = $storage->transaction_depth; $storage->txn_rollback }
      else                       { $storage->txn_do(sub { $ran++ }) }
    } "$name, $entry with the override: the transaction runs";
    is $ran, 1, "$name, $entry with the override: (it did)";
    is scalar @warned, 1, "$name, $entry with the override: one warning";
    like $warned[0] // '',
      qr/Starting a transaction with unsafe AccessBroker \Q$class\E via override: \Q$OWN\E/,
      "$name, $entry with the override: naming the broker and its own reason";
  }
}

# Control: a broker that is safe starts a transaction, and nobody says a word.
{
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->storage->set_access_broker(T::HashBroker->new);

  my $ran = 0;
  lives_ok { $schema->storage->txn_do(sub { $ran++ }) }
    'a transaction-safe broker: txn_do runs';
  is $ran, 1, '... its coderef';
  is_deeply \@warned, [], '... without a warning';
}

# ---------------------------------------------------------------------------
# 6. The plain hash connect form, without a broker.
# ---------------------------------------------------------------------------
my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,
);

sub hash_connected {
  my (%hash) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => '+T::FakeDriver::Storage',
  );
  return $schema->connection({ %hash })->storage;
}

{
  my $storage = hash_connected(
    dbname        => 'appdb',
    host          => 'db.example',
    port          => 5433,
    user          => 'app',
    password      => 's3cret',
    LongReadLen   => 4096,
    on_connect_do => [ 'SET search_path TO app' ],
  );

  is_deeply $storage->_dbi_connect_info, [
    'dbi:K270Fake:dbname=appdb;host=db.example;port=5433',
    'app',
    's3cret',
    { %DEFAULT_ATTRS, LongReadLen => 4096 },
  ], 'a plain hash of connection parameters: the DSN of the storage\'s driver, and beside it '
   . 'only what is a DBI attribute';
  is_deeply $storage->on_connect_do, [ 'SET search_path TO app' ],
    '... a storage option in the hash goes to the storage';
  is $storage->access_broker, undef, '... and no broker is attached';

  my @connects;
  {
    no warnings qw(redefine once);
    local *DBI::connect = sub { shift; push @connects, [@_]; T::Handle->new };
    $storage->_connect;
  }
  is_deeply $connects[0], [
    'dbi:K270Fake:dbname=appdb;host=db.example;port=5433',
    'app',
    's3cret',
    { %DEFAULT_ATTRS, LongReadLen => 4096 },
  ], '... and DBI->connect gets exactly that';
}

{
  my $storage = hash_connected(
    dbname => 'dbi:K270Fake:database=whole;server=elsewhere', user => 'app', password => 's3cret',
  );
  is_deeply [ @{ $storage->_dbi_connect_info }[0 .. 2] ],
    [ 'dbi:K270Fake:database=whole;server=elsewhere', 'app', 's3cret' ],
    'a plain hash whose dbname is a whole DSN: taken as the DSN, as it is';

  throws_ok {
    hash_connected(dbname => 'dbi:K270Fake:database=whole', host => 'db.example', user => 'app');
  } qr/Connection parameter\(s\) 'host' given beside a dbname that is a whole DSN/,
    '... and a host beside it is refused, it cannot be put into that DSN';
}

done_testing;
