use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBI;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k39, from core k298 / k307).
#
# WHY: a DBI storage does not open a connection with a parameter it was given
# through an AccessBroker and would not apply. A lowercase key in the broker's
# hash answer (k298), or beside the broker (k307), passes only when it starts
# with a prefix the storage vouches for as "an attribute of this DBD" --
# _dbd_attribute_prefixes. Core's default asks DBI's registry of driver
# prefixes, and that registry has no entry for DBD::Firebird. So ib_softcommit
# and ib_time_all -- the attributes this very driver writes onto the handle in
# its connect-calls -- were refused when a broker answered them, on every
# dbi:Firebird: connection.
#
# What this file claims:
#   1. Asked about the DBD 'Firebird', the two native storage classes answer
#      ib_. Every other DBD is DBI's to answer, as before.
#   2. With that, an ib_ attribute connects through a broker over
#      dbi:Firebird: -- in the hash answer and beside the broker -- and reaches
#      DBI->connect.
#   3. Nothing else got wider: a client parameter and another DBD's prefix are
#      refused as before, alone, with an ib_ attribute standing next to them.
#   4. The ODBC transport does not vouch for ib_: DBD::ODBC has none of that
#      API (ADR 0010), so ib_ over dbi:ODBC: is refused and odbc_ passes.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a
# stand-in handle; no DBD is asked to connect and no database is involved.
# _connect is driven directly, since it is where core refuses and it needs no
# driver determination -- the storage classes here are instantiated by name.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer}->() }
}

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

note 'DBI ' . DBI->VERSION . ' knows as the prefix of DBD::Firebird: '
  . ( DBI->driver_prefix('DBD::Firebird') // 'nothing' );

my ($USER, $PASSWORD) = ('k39-user', 'k39-secret');
my %LOGIN = (user => $USER, password => $PASSWORD);

my $FB_DSN   = 'dbi:Firebird:dbname=/k39/data/app.fdb;host=k39-host;port=3050';
my $IB_DSN   = 'dbi:InterBase:dbname=/k39/data/app.fdb;host=k39-host';
my $ODBC_DSN = 'dbi:ODBC:Driver=Firebird;Dbname=/k39/data/app.fdb';

sub refused_in_answer {
  my $keys = join ', ', @_;
  return qr/AccessBroker T::Broker answered connect info with parameter\(s\) a DBI storage does not apply \(\Q$keys\E\)/;
}

sub refused_beside {
  my ($broker_class, @keys) = @_;
  my $keys = join ', ', @keys;
  return qr/A DBI storage does not apply parameter\(s\) given beside AccessBroker \Q$broker_class\E \(\Q$keys\E\)/;
}

# The attribute hash DBI->connect was handed last, without the storage's own
# defaults.
sub connect_attrs {
  my %attrs = %{ @CONNECTS && $CONNECTS[-1][3] || {} };
  delete @attrs{qw( AutoCommit PrintError RaiseError ShowErrorStatement )};
  return \%attrs;
}

sub storage_with {
  my ($class, @connect_info) = @_;
  my $storage = $class->new(undef);
  $storage->connect_info([ @connect_info ]);
  return $storage;
}

# ---------------------------------------------------------------------------
# 1. The seam itself.
# ---------------------------------------------------------------------------
for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {
  is_deeply [ $class->new(undef)->_dbd_attribute_prefixes('Firebird') ], [ 'ib_' ],
    "$class: the attributes of DBD::Firebird start with ib_";
  is_deeply [ $class->new(undef)->_dbd_attribute_prefixes('InterBase') ], [ 'ib_' ],
    "$class: ... and those of DBD::InterBase too, which DBI knows itself";
  is_deeply [ $class->new(undef)->_dbd_attribute_prefixes('Pg') ], [ 'pg_' ],
    "$class: any other DBD is DBI's to answer";
  is_deeply [ grep { defined } $class->new(undef)->_dbd_attribute_prefixes(undef) ], [],
    "$class: a DSN naming no DBD has no prefix";
}

is_deeply [ grep { defined } DBIO::Firebird::Storage::ODBC->new(undef)->_dbd_attribute_prefixes('Firebird') ], [],
  'the ODBC storage does not vouch for ib_, even asked about DBD::Firebird: '
. 'the declaration lives with the ib_* API and that is not in its ancestry';
is_deeply [ DBIO::Firebird::Storage::ODBC->new(undef)->_dbd_attribute_prefixes('ODBC') ], [ 'odbc_' ],
  '... and answers odbc_ for its own DBD';

# ---------------------------------------------------------------------------
# 2. An ib_ attribute connects through a broker over dbi:Firebird:.
# ---------------------------------------------------------------------------
# ib_softcommit and ib_time_all are what this driver's own connect-calls set
# (connect_call_use_softcommit, connect_call_datetime_setup): DBD::Firebird
# takes both from the attribute hash.
my %IB = (ib_softcommit => 1, ib_time_all => 'ISO');
# every native connection also speaks UTF8 unless told otherwise (karr k60)
my %UTF8 = (ib_enable_utf8 => 1);

for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {
  {
    my $storage = storage_with($class, T::Broker->new(sub { { dsn => $FB_DSN, %LOGIN, %IB } }));
    local @CONNECTS;
    lives_ok { $storage->_connect }
      "$class, dbi:Firebird:, ib_ attributes in the hash answer: connects";
    is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ "$FB_DSN;ib_dialect=3;ib_charset=UTF8", $USER, $PASSWORD ],
      '... to the DSN the broker answered plus the SQL dialect (karr k43), with its credentials';
    is_deeply connect_attrs(), { %IB, %UTF8 }, '... and DBI->connect gets the attributes';
  }

  {
    my $storage = storage_with($class, T::Broker->new(sub { { dsn => $FB_DSN, %LOGIN } }), { %IB });
    local @CONNECTS;
    lives_ok { $storage->_connect }
      "$class, dbi:Firebird:, ib_ attributes beside the broker: connects";
    is_deeply connect_attrs(), { %IB, %UTF8 }, '... and DBI->connect gets the attributes';
  }
}

# The built-in broker of connection parameters: the DSN is built for the DBD
# the storage class is registered for, and the attribute stands beside it.
{
  my $storage = storage_with('DBIO::Firebird::Storage',
    DBIO::AccessBroker::Static->new(
      dbname => '/k39/data/app.fdb', host => 'k39-host', port => 3050,
      username => $USER, password => $PASSWORD,
    ),
    { ib_softcommit => 1 },
  );
  local @CONNECTS;
  lives_ok { $storage->_connect } 'Static with ib_softcommit beside it: connects';
  is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ "$FB_DSN;ib_dialect=3;ib_charset=UTF8", $USER, $PASSWORD ],
    '... to the DSN built from its parameters, plus the SQL dialect (karr k43)';
  is_deeply connect_attrs(), { ib_softcommit => 1, ib_enable_utf8 => 1 }, '... with the attribute';
}

# ---------------------------------------------------------------------------
# 3. Nothing else got wider.
# ---------------------------------------------------------------------------
for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {
  for my $case (
    [ 'a client parameter'       => { sslmode => 'k39-value' },                   [ 'sslmode' ] ],
    [ "DBD::Firebird's timeout"  => { timeout => 5 },                             [ 'timeout' ] ],
    [ 'the prefix of another DBD' => { pg_enable_utf8 => 1, odbc_cursortype => 2 }, [ qw( odbc_cursortype pg_enable_utf8 ) ] ],
  ) {
    my ($label, $foreign, $keys) = @$case;

    {
      my $storage = storage_with($class, T::Broker->new(sub { { dsn => $FB_DSN, %LOGIN, %IB, %$foreign } }));
      local @CONNECTS;
      throws_ok { $storage->_connect } refused_in_answer(@$keys),
        "$class, $label in the hash answer: refused, and named alone -- not the ib_ attributes beside it";
      unlike "$@", qr/k39-(?:user|secret|value|host)/, '... naming no value of the answer';
      is scalar @CONNECTS, 0, '... and DBI->connect is not called';
    }

    {
      my $storage = storage_with($class, T::Broker->new(sub { { dsn => $FB_DSN, %LOGIN } }), { %IB, %$foreign });
      local @CONNECTS;
      throws_ok { $storage->_connect } refused_beside('T::Broker', @$keys),
        "$class, $label beside the broker: refused, and named alone";
      is scalar @CONNECTS, 0, '... and DBI->connect is not called';
    }
  }
}

# ---------------------------------------------------------------------------
# 4. The ODBC transport.
# ---------------------------------------------------------------------------
{
  my $class = 'DBIO::Firebird::Storage::ODBC';

  {
    my $storage = storage_with($class, T::Broker->new(sub { { dsn => $ODBC_DSN, %LOGIN, ib_softcommit => 1 } }));
    local @CONNECTS;
    throws_ok { $storage->_connect } refused_in_answer('ib_softcommit'),
      'dbi:ODBC:, ib_softcommit in the hash answer: refused -- DBD::ODBC has no such attribute and would keep it without a word';
    is scalar @CONNECTS, 0, '... and DBI->connect is not called';
  }

  {
    my $storage = storage_with($class, T::Broker->new(sub { { dsn => $ODBC_DSN, %LOGIN } }), { ib_softcommit => 1 });
    local @CONNECTS;
    throws_ok { $storage->_connect } refused_beside('T::Broker', 'ib_softcommit'),
      'dbi:ODBC:, ib_softcommit beside the broker: refused';
    is scalar @CONNECTS, 0, '... and DBI->connect is not called';
  }

  {
    my $storage = storage_with($class, T::Broker->new(sub { { dsn => $ODBC_DSN, %LOGIN, odbc_cursortype => 2 } }));
    local @CONNECTS;
    lives_ok { $storage->_connect } 'dbi:ODBC:, an odbc_ attribute in the hash answer: connects';
    is_deeply connect_attrs(), { odbc_cursortype => 2 }, '... and DBI->connect gets it';
  }
}

# A native storage whose broker answers an ODBC DSN: the DSN names the DBD,
# and ib_ is not an attribute of that one.
{
  my $storage = storage_with('DBIO::Firebird::Storage',
    T::Broker->new(sub { { dsn => $ODBC_DSN, %LOGIN, ib_softcommit => 1 } }));
  local @CONNECTS;
  throws_ok { $storage->_connect } refused_in_answer('ib_softcommit'),
    'the native storage answered a dbi:ODBC: DSN: ib_softcommit is refused -- the prefix goes by the DBD of the DSN, not by the class';
}

# Control: dbi:InterBase: passed before this ticket, on DBI's registry alone.
{
  my $storage = storage_with('DBIO::Firebird::Storage::InterBase',
    T::Broker->new(sub { { dsn => $IB_DSN, %LOGIN, %IB } }));
  local @CONNECTS;
  lives_ok { $storage->_connect } 'dbi:InterBase:, ib_ attributes in the hash answer: connects, as before';
  is_deeply connect_attrs(), { %IB }, '... and DBI->connect gets the attributes';
}

done_testing;
