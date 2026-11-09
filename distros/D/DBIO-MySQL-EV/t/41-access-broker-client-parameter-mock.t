use strict;
use warnings;
use Test::More;

# OFFLINE test: an EV::MariaDB parameter in an AccessBroker's hash answer
# (karr k76, for core k298; the counterpart of
# t/39-access-broker-parameters-beside-mock.t, where the parameter stands
# beside the broker).
#
# WHY: the refusal of a parameter beside a broker tells the caller to give it
# in the broker's answer. A hash of EV::MariaDB parameters is this transport's
# shape -- charset, connect_timeout, ssl_ca, ... are handed to EV::MariaDB --
# but a schema's broker is asked by two storages, and the owning sync storage
# builds only dbname, host and port of a hash into its DSN. Since core k298 it
# refuses a hash carrying anything else when it is about to open its dbh,
# rather than connect without it. What a caller of this transport gets is
# therefore not obvious from either half, and this distribution's POD states
# it; this file holds what the POD says:
#
#   1. the transport given the broker directly takes the hash with an
#      EV::MariaDB parameter in it, and every connection it opens -- pooled
#      and the listen connection -- is opened with the parameter;
#   2. through a schema, connect and ->async go through and a pooled
#      connection is opened with the parameter; the owner's dbh is refused by
#      core, naming the broker class and the parameter and no value, before
#      anything is handed to DBI;
#   3. a broker answering by the storage that asks -- this transport the hash
#      with the parameter, every other storage an answer without it -- is
#      taken by both halves: the pool gets the parameter and the owner's dbh
#      is not refused.
#
# Nothing here was changed by k76: the file is green before and after it. It
# is here because the behaviour is core's on one side and this transport's on
# the other, and only a test over both keeps the POD's statement true.
#
# WHAT RUNS FOR REAL: core's broker attach, its sync storage and its
# _async_storage, this dist's Storage, ConnectInfo and Pool (and EV, for the
# fork watchers both arm). THE SUBSTITUTIONS: EV::MariaDB records what it is
# constructed with -- the fake of t/29-access-broker-conninfo-mock.t -- and
# DBI->connect records what it is called with and fails: there is no server.

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Scalar::Util ();

  our @NEW;   # every handle made: [ \%named (without the callbacks), the handle (weak) ]

  # What EV::MariaDB 0.08's constructor takes; it croaks on anything else.
  my %ALLOWED = map { $_ => 1 } qw(
    connect_timeout read_timeout write_timeout
    compress multi_statements charset init_command
    ssl_key ssl_cert ssl_ca ssl_capath ssl_cipher ssl_verify_server_cert
    utf8 found_rows
    loop on_connect on_error
    host user password database db port unix_socket
  );

  sub new {
    my ($class, %args) = @_;
    if (my @unknown = grep { !$ALLOWED{$_} } keys %args) {
      Carp::croak('unknown argument(s) to new(): ' . join(', ', sort @unknown));
    }
    my $self = bless {
      on_connect => delete $args{on_connect},
      on_error   => delete $args{on_error},
      connected  => 0,
    }, $class;
    push @NEW, [ { %args }, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }   # the handle seam asks (karr k95); no socket here
  sub finish       { $_[0]{connected} = 0; return }
  sub close_async  { my ($self, $cb) = @_; $self->finish; $cb->(1) if $cb; return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($self) = @_;
    $self->{connected} = 1;
    $self->{on_connect}->() if $self->{on_connect};
    return;
  }

  $INC{'EV/MariaDB.pm'} = __FILE__;
}

use EV;
use DBI;
use DBIO::AccessBroker;
use DBIO::MySQL::EV::Storage;

alarm 60;

# The read of character set and collation after a spawn (karr k100) blocks
# until the handle is connected; this test connects its fake handles itself,
# after the spawn. t/59-session-reset-mock.t and t/07 hold that read.
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Storage::_mysql_remember_session_names = sub { return };
}

my $EV = 'DBIO::MySQL::EV::Storage';

# Every DBI->connect of this file: the DSN it was called with. None connects.
my @DBI_CONNECT;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @DBI_CONNECT, $_[1]; die "no server in this test\n" };
}

# A broker answering whatever the test puts in it, to every storage.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# A broker answering by the storage that asks.
{
  package ByStorageBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %answer) = @_; bless { %answer }, $class }
  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    return $storage->isa('DBIO::MySQL::EV::Storage') ? $self->{ev} : $self->{other};
  }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

# One new pool connection: the named parameters EV::MariaDB was constructed
# with. The connection is acquired and kept, so the next spawn is a new one.
sub spawn_params {
  my ($s) = @_;
  @EV::MariaDB::NEW = ();
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::MariaDB::NEW) . " EV::MariaDB handles made for one spawn\n"
    unless @EV::MariaDB::NEW == 1;
  my ($params, $mdb) = @{ $EV::MariaDB::NEW[0] };
  delete $params->{found_rows};   # on for every handle (karr k80, t/54); not what this file is about
  $mdb->t_connect;
  return $params;
}

# One open of the listen connection: the named parameters EV::MariaDB was
# constructed with. The connection is closed again.
sub listen_params {
  my ($s) = @_;
  @EV::MariaDB::NEW = ();
  my $f = $s->_listen_open;
  die scalar(@EV::MariaDB::NEW) . " EV::MariaDB handles made for one listen open\n"
    unless @EV::MariaDB::NEW == 1;
  my ($params, $mdb) = @{ $EV::MariaDB::NEW[0] };
  delete $params->{found_rows};   # on for every handle (karr k80, t/54); not what this file is about
  $mdb->t_connect;
  $s->_listen_close($f->get);
  return $params;
}

# Every value of a parameter in this file carries this, and the password its
# own marker, so one pattern finds either in a message.
my $VALUE = 'k76-value';
my $LEAK  = qr/\Q$VALUE\E|k76-broker-pw/;

my %PLAIN  = (dbname => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 'k76-broker-pw');
my %CLIENT = (charset => "$VALUE-charset", connect_timeout => "$VALUE-7");
my %NAMED  = (database => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 'k76-broker-pw',
              %CLIENT);

# ---------------------------------------------------------------------------
# 1. The transport given the broker directly.
# ---------------------------------------------------------------------------

{
  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ AnswerBroker->new({ %PLAIN, %CLIENT }) ]); 1 },
    'a hash answer with charset and connect_timeout: the transport takes it' or diag $@;
  is_deeply scalar eval { spawn_params($s) }, \%NAMED,
    '... a pool connection is opened with both, dbname as database' or diag $@;
  is_deeply scalar eval { listen_params($s) }, \%NAMED,
    '... and so is the listen connection' or diag $@;
}

# ---------------------------------------------------------------------------
# 2. The same answer through a schema.
# ---------------------------------------------------------------------------

{
  @DBI_CONNECT = ();
  my $schema = eval { BrokerSchema->connect(AnswerBroker->new({ %PLAIN, %CLIENT }), { async => 'ev' }) };
  ok $schema, 'the same answer through a schema: connect goes through' or diag $@;

  SKIP: {
    skip 'the connect itself was refused', 7 unless $schema;
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... and so does ->async: the transport' or diag $@;
    is_deeply scalar eval { $async && spawn_params($async) }, \%NAMED,
      '... its pool connection is opened with the parameters' or diag $@;

    # The owner. Core refuses the answer for a connection of its own (k298):
    # it would build dbname, host and port into the DSN and lose the rest.
    my $dbh = eval { $schema->storage->dbh };
    my $err = "$@";
    ok !$dbh, 'the owner\'s dbh is not opened';
    like $err, qr/AccessBroker AnswerBroker answered connect info with parameter\(s\) a DBI storage does not apply \(charset, connect_timeout\)/,
      '... core refuses the answer, naming the broker class and the parameters';
    like $err, qr/connect_info_for_storage/, '... and the way out this file holds below';
    unlike $err, $LEAK, '... no value of the answer is in the message';
    is_deeply \@DBI_CONNECT, [], '... and nothing was handed to DBI';
  }
}

# A hash answer that names no database is refused earlier, when the schema is
# connected: the sync storage has no DSN to build (core k271). EV::MariaDB's
# own spelling, database, is not read there.
{
  my $schema = eval {
    BrokerSchema->connect(
      AnswerBroker->new({ database => 'appdb', host => 'db.example', user => 'app', password => 'k76-broker-pw' }),
      { async => 'ev' },
    );
  };
  my $err = "$@";
  ok !$schema, 'a hash answer with database and no dbname, through a schema: connect is refused';
  like $err, qr/AccessBroker AnswerBroker answered connect info without a DSN \(a hash with host, but neither a dsn nor a dbname key\)/,
    '... by core, naming the shape';
  unlike $err, $LEAK, '... and no value';
}

# ---------------------------------------------------------------------------
# 3. An answer by the storage that asks.
# ---------------------------------------------------------------------------

{
  @DBI_CONNECT = ();
  my $schema = eval {
    BrokerSchema->connect(
      ByStorageBroker->new(ev => { %PLAIN, %CLIENT }, other => { %PLAIN }),
      { async => 'ev' },
    );
  };
  ok $schema, 'a broker answering by the storage that asks: connect goes through' or diag $@;

  SKIP: {
    skip 'the connect itself was refused', 4 unless $schema;
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... the transport' or diag $@;
    is_deeply scalar eval { $async && spawn_params($async) }, \%NAMED,
      '... its pool connection is opened with the parameters of its own answer' or diag $@;

    # The owner is not refused: it gets as far as DBI, with the DSN it built
    # from the answer that was for it. (DBI is the stand-in; nothing connects.)
    my $dbh = eval { $schema->storage->dbh };
    my $err = "$@";
    unlike $err, qr/does not apply/, '... the owner\'s dbh is not refused by core';
    is scalar(@DBI_CONNECT), 1, '... it is handed to DBI, once';
  }
}

done_testing;
