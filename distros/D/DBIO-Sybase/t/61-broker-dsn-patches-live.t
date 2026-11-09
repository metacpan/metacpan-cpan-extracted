use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::AccessBroker::Static;

# LIVE (karr k60). The counterpart of t/58-broker-dsn-patches.t, which shows
# offline, against a handle that only plays a server, that the two things this
# driver appends to the stored DSN after the connect info is set --
#
#   ;maxConnect=256  DBIO::Sybase::Storage::_set_max_connect, called from
#                    DBIO::Sybase::Storage::ASE::_init for the main storage
#                    and its writer storage (and its bulk storage);
#   ;bulkLogin=1     DBIO::Sybase::Storage::ASE::_init, for the bulk storage
#
# -- reach DBI->connect when the DSN was given as a string, and, since
# DBIO::Sybase::Storage::_finish_connect_dsn adds them (core's seam), when the
# connect info is a DBIO::AccessBroker too, whose answer core's _connect forms
# the DSN from anew for every connect. This file sees the same with real
# connections to a real ASE: DBI->connect is wrapped by a recorder that passes
# every call on, and every assertion on a DSN is about what arrived there.
#
#   A. The DSNs. Without a broker (the control) the connect _set_max_connect
#      leaves the storage on carries maxConnect=256, on the main and on the
#      writer storage, and still does after disconnect + ensure_connected:
#      hard tests. With a DBIO::AccessBroker::Static, in both shapes it has --
#      a dbname that is a whole DSN, and { dbname, host, port } built through
#      _connect_params_dsn -- the same is asserted (karr k60, fixed).
#   B. What the loss costs on a live connection. Measured, not argued -- and
#      with this client library the answer is: nothing that can be observed.
#
# Nothing of the driver is stubbed, as in t/58. Two schemas, for t/58's
# reason, and each declares the driver, as a schema has to (core ADR 0067,
# karr k90): T::K60::Component loads the Sybase component, and its storage
# becomes the ASE class at the first use without asking the server (karr
# k64); T::K60::ASE pins the ASE class.
#
# Measured 2026-10-05 against SAP ASE 16.0 SP02 PL02, with DBD::Sybase 1.27
# built against FreeTDS 1.3.17, TDS 5.0. What that client library leaves
# unmeasured, and this file therefore does NOT claim:
#
#   * anything about ;bulkLogin=1 on a live connection. Under FreeTDS there is
#     no bulk storage at all (ASE::_init makes none: FreeTDS cannot bulk-copy,
#     see t/22-ase-bulk-freetds.t), so no connection was made that should have
#     carried it. The assertions on it are here, taken from t/58, and skip;
#     with DBD::Sybase built against Open Client they would run -- and have
#     never been run against a server.
#   * that losing maxConnect is harmless with Open Client. There the client
#     library is documented to stop at 25 connections per process unless
#     maxConnect raises the limit (DBD::Sybase POD, "maxConnect"). FreeTDS
#     does not enforce a limit set this way (B), so nothing could be provoked
#     here; whether a broker user of Open Client hits the 25 was not measured.
#   * what the server makes of either part. Both are the client library's:
#     the server never sees them.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

# The broker's parameters come out of the DSN, so that every way here provably
# goes to the same place; only the form _connect_params_dsn builds will do.
my %dsn_part = $dsn =~ /\Adbi:Sybase:(.*)\z/s
  ? ( map { /\A([^=]+)=(.*)\z/s ? ($1 => $2) : ($_ => '') } split /;/, $1 )
  : ();
my ($host, $port, $dbname) = @dsn_part{qw(host port database)};

plan skip_all => 'This test compares the DSN a broker\'s connection '
  . 'parameters build with the same DSN given as a string; '
  . '$ENV{DBIO_TEST_SYBASE_DSN} must be exactly '
  . 'dbi:Sybase:host=<host>;port=<port>;database=<database> (nothing else, '
  . 'no server=<name>)'
  unless keys %dsn_part == 3
    and 3 == grep { defined && length } $host, $port, $dbname;

my $ASE = 'DBIO::Sybase::Storage::ASE';
my $DSN = "dbi:Sybase:host=$host;port=$port;database=$dbname";

{
  package T::K60::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k60_live_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K60::Component;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

{
  package T::K60::ASE;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
}

$_->register_class(Item => 'T::K60::Result::Item')
  for qw(T::K60::Component T::K60::ASE);

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => $user,
    password => $pass,
    @_,
  );
}

# Plain DBI, never recorded: for setup, and for looking at the server from a
# session that is no storage's.
my $admin;
sub admin {
  return $admin ||= DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }

sub db_of { ( $_[0]->selectrow_array('select db_name()') )[0] }

sub drop_table {
  admin()->do('drop table k60_live_item') if server_value(
    q{select count(*) from sysobjects where name = 'k60_live_item' and type = 'U'}
  );
}

# The DSNs DBI->connect is handed while $code runs, in order. Every call goes
# on to the real DBI->connect.
sub dsns_connected (&) {
  my $code = shift;
  my @dsns;
  my $connect = DBI->can('connect');
  no warnings 'redefine';
  local *DBI::connect = sub { push @dsns, $_[1]; goto &$connect };
  $code->();
  return \@dsns;
}

sub reconnect {
  my $storage = shift;
  return dsns_connected { $storage->disconnect; $storage->ensure_connected };
}

# $dsn is $DSN with further parts appended, $part among them.
sub carries {
  my ($dsn, $part) = @_;
  return defined $dsn && $dsn =~ /\A\Q$DSN\E(?:;[^;]+)*;\Q$part\E(?:;|\z)/;
}

# The server's address is the environment's and stays out of the output.
sub masked {
  my $dsn = shift // '(undef)';
  $dsn =~ s/\b(host|port)=[^;]*/$1=../g;
  return $dsn;
}

sub got {
  return 'DBI->connect got: '
    . ( @{$_[0]} ? join(', ', map { masked($_) } @{$_[0]}) : 'no connect' );
}

# The last connect is the one the storage stays on.
sub last_connect_carries {
  my ($dsns, $part, $name) = @_;
  ok carries($dsns->[-1], $part), $name or diag got($dsns);
}

sub every_connect_carries {
  my ($dsns, $part, $name) = @_;
  ok @$dsns && !(grep { !carries($_, $part) } @$dsns), $name or diag got($dsns);
}

my $live = 1;   # past every skip_all: from here on there is something to drop

drop_table();   # what a run that died before its END block may have left

my $FREETDS = ( admin()->{syb_oc_version} || '' ) =~ /freetds/i;

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );

# ===================================================================== A
# The DSNs that reach DBI->connect.

sub dsn_parts_reach_dbi_connect {
  my ($label, $storage) = @_;

  # The first connect runs _init, and with it _set_max_connect.
  my $main = dsns_connected { $storage->ensure_connected };

  my ($writer, $bulk) = $storage->isa($ASE)
    ? ($storage->_writer_storage, $storage->_bulk_storage)
    : ();

  ok $writer, "$label: the first connect leaves an ASE storage with a writer "
            . 'storage' or return;

  note "$label, main storage: " . got($main);

  my $writer_dsns = dsns_connected { $writer->ensure_connected };

  note "$label, writer storage: " . got($writer_dsns);

  # Whatever became of the DSN parts: these are working sessions.
  is_deeply [ map { db_of($_->dbh) } $storage, $writer ], [ $dbname, $dbname ],
    "$label: both storages are left connected, in the database the DSN names";

  {
    last_connect_carries $main, 'maxConnect=256',
      "$label: _set_max_connect leaves the storage on a connection made with "
    . 'maxConnect=256';

    last_connect_carries $writer_dsns, 'maxConnect=256',
      "$label: ... and so the writer storage";

    # disconnect goes to the writer and the bulk storage as well
    last_connect_carries reconnect($storage), 'maxConnect=256',
      "$label: after disconnect, the reconnect still carries maxConnect=256";

    last_connect_carries reconnect($writer), 'maxConnect=256',
      "$label: ... and so does the writer storage's";
  }

  SKIP: {
    skip "$label: no bulk storage -- under FreeTDS ASE::_init makes none, so "
       . 'there is no connect that should carry bulkLogin=1', 4
      unless $bulk;

    # NEVER RUN against a server: no DBD::Sybase built against Open Client
    # was at hand. The assertions are t/58's.
    my $bulk_dsns = dsns_connected { $bulk->ensure_connected };

    note "$label, bulk storage: " . got($bulk_dsns);

    every_connect_carries $bulk_dsns, 'bulkLogin=1',
      "$label: the bulk storage connects with bulkLogin=1, every time";

    last_connect_carries $bulk_dsns, 'maxConnect=256',
      "$label: ... and stays on a connection made with maxConnect=256 too";

    $bulk_dsns = reconnect($bulk);

    every_connect_carries $bulk_dsns, 'bulkLogin=1',
      "$label: after disconnect, the bulk storage's reconnect still carries "
    . 'bulkLogin=1';

    last_connect_carries $bulk_dsns, 'maxConnect=256',
      "$label: ... and maxConnect=256";
  }

  $storage->disconnect;

  # How many connections the first connect of the main storage took: for B.
  return scalar @$main;
}

# ------------------------------------------------- the control: a DSN string

my %first_connects;   # of the main storage, per way: how many it took

$first_connects{string}{component} = dsn_parts_reach_dbi_connect(
  'DSN string, Sybase component',
  T::K60::Component->connect($DSN, $user, $pass)->storage,
);

$first_connects{string}{pinned} = dsn_parts_reach_dbi_connect(
  'DSN string, ASE storage pinned',
  T::K60::ASE->connect($DSN, $user, $pass)->storage,
);

# --------------------------------------------------------- through a broker

$first_connects{broker}{component} = dsn_parts_reach_dbi_connect(
  'broker answering a whole DSN, Sybase component',
  T::K60::Component->connect(broker(dbname => $DSN))->storage,
);

$first_connects{broker}{pinned} = dsn_parts_reach_dbi_connect(
  'broker answering dbname, host and port, ASE storage pinned',
  T::K60::ASE->connect(
    broker(dbname => $dbname, host => $host, port => $port)
  )->storage,
);

# ===================================================================== B
# What the loss costs here. Both parts are instructions to the client library,
# so what they are worth depends on which one DBD::Sybase was built against.

SKIP: {
  skip 'DBD::Sybase is built against Open Client: what its connection limit '
     . 'and its bulk login do without the two DSN parts was not measured', 5
    unless $FREETDS;

  # ---- what the loss used to cost: a login more (karr k68, fixed)
  #
  # Under FreeTDS _init used to run twice on the main storage -- it called
  # itself again once the trait class was mixed in -- and so did
  # _set_max_connect. Its second call finds maxConnect= in the stored DSN and
  # does nothing; with a broker the part is gone again by then, and it
  # disconnected and connected once more. _init now runs once per connect, so
  # the first connect takes the same logins either way: a hard test. (The
  # loss of the part itself was karr k60's, fixed.)
  is_deeply $first_connects{broker}, $first_connects{string},
    'FreeTDS: the first connect of the main storage takes as many logins '
  . 'through a broker as with a DSN string'
    or diag sprintf 'with a DSN string: %s, through a broker: %s',
      map {
        my $took = $first_connects{$_};
        join ', ', map { "$_ " . ($took->{$_} // '?') } sort keys %$took;
      } qw(string broker);

  # ---- maxConnect: is the limit it sets a limit at all?
  #
  # Three connections at a time, each from a DSN that says two is the most.
  # If the client library enforced what maxConnect sets, the third would be
  # refused. It is not: the part is accepted and has no effect, so a
  # connection made without it cannot be told from one made with it.
  {
    my @open;
    my $error;
    for (1 .. 3) {
      my $dbh = eval {
        DBI->connect("$DSN;maxConnect=2", $user, $pass, {
          RaiseError => 1, PrintError => 0, AutoCommit => 1,
        });
      };
      $error = $@, last unless $dbh;
      push @open, $dbh;
    }

    is scalar(grep { $_->ping } @open), 3,
      'FreeTDS: three connections are open at a time, each made with '
    . 'maxConnect=2 -- this client library does not enforce the limit the '
    . 'part sets, so losing the part on the broker path changes nothing that '
    . 'can be observed here'
      or diag 'connection ' . (@open + 1) . ' failed: ' . masked($error);

    $_->disconnect for @open;
  }

  # ---- bulkLogin: is there a connection that needs it?
  #
  # populate() in void context is the call that goes to the bulk-copy API,
  # over the bulk storage, under Open Client.
  drop_table();
  admin()->do(
    'create table k60_live_item ('
  . ' id int identity primary key, name varchar(100) null)'
  );

  my $schema = T::K60::ASE->connect(
    broker(dbname => $dbname, host => $host, port => $port)
  );
  my $storage = $schema->storage;
  $storage->ensure_connected;

  ok !$storage->_bulk_storage,
    'FreeTDS: the storage has no bulk storage -- no connection is ever made '
  . 'that should carry bulkLogin=1, so there is nothing for the broker path '
  . 'to lose';

  lives_ok {
    $schema->resultset('Item')->populate([ map { { name => "row $_" } } 1 .. 3 ]);
  } 'FreeTDS: populate in void context runs through the broker all the same';

  is server_value('select count(*) from k60_live_item'), 3,
    'FreeTDS: ... every row arrives, by regular inserts';

  $storage->disconnect;
}

# ================================================================ the end

drop_table();

is server_value(
     q{select count(*) from sysobjects where name like 'k60[_]live%'}
   ), 0,
  'nothing of this test is left in the database';

done_testing;

# The table again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { drop_table(); 1 }
      or diag "Could not drop the k60_live_item table: $@";
  }
}
