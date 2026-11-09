use strict;
use warnings;
use Test::More;

# OFFLINE test: an AccessBroker whose answer carries a libpq parameter
# (sslmode, connect_timeout, ...), through a schema connected with
# { async => 'ev' } (karr k78, k81; core k298).
#
# WHY: a schema connected through a broker has two halves that open
# connections from the broker's answer -- the owning sync storage, over
# DBI / DBD::Pg, and this transport, over libpq. A hash of libpq parameters is
# this transport's own shape, and every key of it reaches libpq. The sync
# storage builds a DSN out of dbname, host and port and nothing else; any other
# key went to DBI->connect as an attribute DBD::Pg does not read, and the dbh
# was opened without it. With core k298 the sync storage refuses such an
# answer instead -- where it opens a connection of its own (the first use of
# its dbh, every reconnect), not when it is configured: what a schema is
# connected with may be for the transport alone. So the one answer this
# transport's documentation offers for "any libpq parameter" --
#
#   { dbname => ..., host => ..., user => ..., password => ..., sslmode => 'verify-full' }
#
# -- connects a schema, and every connection of the transport is opened with
# the parameter, which is what it is given for. Only the owner's dbh is not
# opened: no connection of the schema exists without the parameter the broker
# answered. This file holds that, and the two answers that carry a libpq
# parameter to both halves.
#
# What it claims:
#   1. the hash with a libpq parameter, answered to every storage alike:
#      Schema->connect goes through and opens nothing. The transport is built
#      at the first ->async, and a pool connection and the listen connection
#      are opened with every key of the answer -- without the sync storage
#      connecting for any of it: DBI is not asked. The owner's dbh, when it is
#      used, is refused by the sync storage, naming the broker class and the
#      parameters, never a value -- not the parameter's, not the password in
#      the same answer -- and DBI is not asked for a connection; used again,
#      it is refused again. The transport goes on opening connections with
#      the parameters after that. The transport addressed directly takes the
#      very same answer, every key of it;
#   2. the broker answers by the storage that asks (connect_info_for_storage):
#      this transport the hash with the parameters, every other storage one
#      without. The schema connects, and a pool connection and the listen
#      connection are opened with the parameters;
#   3. the DBI form with the parameter in the DSN, one answer for every
#      storage: the schema connects, the pool and the listen connection are
#      opened with the parameter, and the owner's dbh is opened from the very
#      DSN -- one answer that carries a libpq parameter to both halves;
#   4. a hash with a dsn key -- { dsn => 'dbi:Pg:...;sslmode=...', user => ...,
#      password => ... }, the answer core's refusal of section 1 names as the
#      way out -- is that DBI form written as a hash, to both halves: the sync
#      storage opens its dbh from the DSN, and this transport opens the pool
#      and the listen connection with the DSN's parameters and the hash's user
#      and password (karr k79). Before it the transport took the hash for
#      libpq parameters and handed libpq one named dsn, which libpq refused at
#      the first connection.
#
# WHAT RUNS FOR REAL: core's broker attach on both halves, core's sync
# storage and its _async_storage, this dist's Storage, ConnectInfo and Pool.
# THE SUBSTITUTIONS: EV::Pg records what it is constructed with (the test plays
# the server's connect); DBI->connect records what it is called with and
# reports that there is no server.

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
use DBI;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;

alarm 60;

my $EV = 'DBIO::PostgreSQL::EV::Storage';

# Every DBI->connect of this file: [ $dsn, $user, $password, \%attrs ]. There
# is no server to answer one.
my @DBI_CONNECT;
{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, @args) = @_;
    push @DBI_CONNECT, [ @args ];
    die "this test has no server\n";
  };
}

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

# One new pool connection: what EV::Pg was constructed with.
sub spawn_conninfo {
  my ($s) = @_;
  my $before = @EV::Pg::NEW;
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::Pg::NEW) - $before . " EV::Pg handles made for one spawn\n" unless @EV::Pg::NEW == $before + 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[-1] };
  $pg->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $pg;
  return $conninfo;
}

# One open of the listen connection: what EV::Pg was constructed with.
sub listen_conninfo {
  my ($s) = @_;
  my $before = @EV::Pg::NEW;
  my $f = $s->_listen_open;
  die scalar(@EV::Pg::NEW) - $before . " EV::Pg handles made for one listen open\n" unless @EV::Pg::NEW == $before + 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[-1] };
  $pg->t_connect;
  $s->_listen_close($f->get);
  return $conninfo;
}

# The DSN the owner's dbh is opened from: what DBI->connect is called with
# when the sync storage connects.
sub owner_dsn {
  my ($schema) = @_;
  @DBI_CONNECT = ();
  eval { $schema->storage->dbh };
  return @DBI_CONNECT == 1 ? $DBI_CONNECT[0][0] : undef;
}

# A broker answering every storage alike, whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# A broker answering by the storage that asks: this transport {ev}, every
# other storage {dbi}. It keeps what it was asked by.
{
  package PerStorageBroker;
  use base 'DBIO::AccessBroker';

  sub new { my ($class, %arg) = @_; bless { %arg, asked => [] }, $class }

  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    my $ev = $storage->isa('DBIO::PostgreSQL::EV::Storage');
    push @{ $self->{asked} }, $ev ? 'ev' : 'dbi';
    return { %{ $self->{ $ev ? 'ev' : 'dbi' } } };
  }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $SECRET = 'k78-pw';
my %LOGIN  = (dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => $SECRET);

# The parameters, with values nothing else in this file contains.
my %PARAM = (sslmode => 'k78-verify-full', connect_timeout => 'k78-7', application_name => 'k78-app');
my $LEAK  = qr/\Q$SECRET\E|k78-verify-full|k78-7|k78-app/;

# ---------------------------------------------------------------------------
# 1. The hash with a libpq parameter, answered to every storage alike.
# ---------------------------------------------------------------------------

for my $case (
  [ 'sslmode',                           [ 'sslmode' ] ],
  [ 'connect_timeout',                   [ 'connect_timeout' ] ],
  [ 'application_name',                  [ 'application_name' ] ],
  [ 'sslmode and connect_timeout',       [ 'connect_timeout', 'sslmode' ] ],
) {
  my ($label, $names) = @$case;
  my %answer = (%LOGIN, map { $_ => $PARAM{$_} } @$names);
  my $listed = join ', ', @$names;

  @EV::Pg::NEW = @DBI_CONNECT = ();
  my $schema = eval { BrokerSchema->connect(AnswerBroker->new({ %answer }), { async => 'ev' }) };
  ok $schema, "a hash answer with $label, to every storage: the schema is connected" or diag $@;

  SKIP: {
    skip 'the connect was refused', 13 unless $schema;
    is scalar(@DBI_CONNECT) + scalar(@EV::Pg::NEW), 0, '... and nothing is opened for it yet';

    # What the parameter is given for: the transport's connections carry it.
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... ->async: the transport' or diag $@;
    skip 'the transport was refused', 11 unless $async;

    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%answer,
      '... a pool connection is opened with every key of the answer' or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, \%answer,
      '... and so is the listen connection' or diag $@;
    is scalar(@DBI_CONNECT), 0, '... without the sync storage connecting for either: DBI was not asked';

    # The owner's dbh is the sync storage's own connection, and that one would
    # be opened without the parameter. It is refused where it is opened, every
    # time.
    for my $use ('the owner\'s dbh, when it is used', 'used again') {
      my $dbh = eval { $schema->storage->dbh };
      my $err = "$@";
      ok !$dbh, "... $use: no dbh";
      like $err, qr/\bAccessBroker AnswerBroker answered connect info with parameter\(s\) a DBI storage does not apply \(\Q$listed\E\)/,
        '... the sync storage refuses, naming the broker class and the parameters';
      unlike $err, $LEAK, '... and no value: not the parameter\'s, not the password of the same answer';
    }
    is scalar(@DBI_CONNECT), 0, '... DBI was not asked for a connection: none is opened without the parameter';

    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%answer,
      '... and the transport still opens a pool connection with every key of the answer' or diag $@;
  }

  # The transport addressed directly is not the sync storage: the same answer
  # is its own shape, and every key of it reaches libpq.
  my $s = $EV->new(undef);
  ok eval { $s->connect_info([ AnswerBroker->new({ %answer }) ]); 1 },
    '... the transport addressed directly takes the same answer' or diag $@;
  is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%answer,
    '... and opens a pool connection with every key of it' or diag $@;
}

# ---------------------------------------------------------------------------
# 2. The broker answers by the storage that asks.
# ---------------------------------------------------------------------------

{
  @EV::Pg::NEW = @DBI_CONNECT = ();
  my $broker = PerStorageBroker->new(ev => { %LOGIN, %PARAM }, dbi => { %LOGIN });
  my $schema = eval { BrokerSchema->connect($broker, { async => 'ev' }) };
  ok $schema, 'a hash with the parameters for this transport, one without for the sync storage: the schema is connected'
    or diag $@;

  SKIP: {
    skip 'the connect was refused', 6 unless $schema;
    is_deeply $broker->{asked}, [ 'dbi' ], '... the sync storage asked the broker, and got the hash without';

    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... ->async: the transport' or diag $@;
    skip 'the transport was refused', 4 unless $async;

    is $broker->{asked}[-1], 'ev', '... which asked the broker itself, and got the hash with the parameters';
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, { %LOGIN, %PARAM },
      '... a pool connection is opened with them' or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, { %LOGIN, %PARAM },
      '... and so is the listen connection' or diag $@;
    is owner_dsn($schema), 'dbi:Pg:dbname=appdb;host=db.example;port=5433',
      '... while the owner\'s dbh is opened from the answer the sync storage got: no parameter in its DSN';
  }
}

# ---------------------------------------------------------------------------
# 3. The DBI form with the parameter in the DSN: one answer for both halves.
# ---------------------------------------------------------------------------

{
  @EV::Pg::NEW = @DBI_CONNECT = ();
  my $dsn = 'dbi:Pg:dbname=appdb;host=db.example;port=5433'
          . ";sslmode=$PARAM{sslmode};connect_timeout=$PARAM{connect_timeout};application_name=$PARAM{application_name}";
  my $schema = eval { BrokerSchema->connect(AnswerBroker->new([ $dsn, 'app', $SECRET ]), { async => 'ev' }) };
  ok $schema, 'the DBI form with the parameters in the DSN, to every storage: the schema is connected'
    or diag $@;

  SKIP: {
    skip 'the connect was refused', 4 unless $schema;
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... ->async: the transport' or diag $@;
    skip 'the transport was refused', 3 unless $async;

    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, { %LOGIN, %PARAM },
      '... a pool connection is opened with the parameters of the DSN' or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, { %LOGIN, %PARAM },
      '... and so is the listen connection' or diag $@;
    is owner_dsn($schema), $dsn,
      '... and the owner\'s dbh is opened from that very DSN: DBD::Pg hands libpq the same parameters';
  }
}

# ---------------------------------------------------------------------------
# 4. A hash with a dsn key (karr k79).
# ---------------------------------------------------------------------------

{
  @EV::Pg::NEW = @DBI_CONNECT = ();
  my $dsn    = "dbi:Pg:dbname=appdb;host=db.example;port=5433;sslmode=$PARAM{sslmode}";
  my $schema = eval {
    BrokerSchema->connect(AnswerBroker->new({ dsn => $dsn, user => 'app', password => $SECRET }), { async => 'ev' })
  };
  ok $schema, 'a hash with a dsn key, to every storage: the schema is connected' or diag $@;

  SKIP: {
    skip 'the connect was refused', 6 unless $schema;
    is owner_dsn($schema), $dsn, '... and the owner\'s dbh is opened from that DSN, parameter included';

    # The transport reads the dsn key as the sync storage does: the hash is
    # the DBI form, and libpq is never handed a parameter named dsn.
    @EV::Pg::NEW = ();
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, '... ->async: the transport' or diag $@;
    skip 'the transport was refused', 4 unless $async;

    my %want = (%LOGIN, sslmode => $PARAM{sslmode});
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($async)) }, \%want,
      '... a pool connection is opened with the parameters of the DSN, and the user and password of the hash' or diag $@;
    is_deeply scalar eval { parse_conninfo(listen_conninfo($async)) }, \%want,
      '... and so is the listen connection' or diag $@;
    my @named_dsn = grep { /(?:^|\s)dsn=/ } map { $_->[0] // '' } @EV::Pg::NEW;
    is scalar(@named_dsn), 0, '... no connection of the transport is opened with a libpq parameter named dsn';

    # The same answer as the DBI form of section 3 would give.
    my $s = $EV->new(undef);
    $s->connect_info([ AnswerBroker->new([ $dsn, 'app', $SECRET ]) ]);
    is_deeply scalar eval { parse_conninfo(spawn_conninfo($s)) }, \%want,
      '... which is what the DBI form [ $dsn, $user, $password ] opens one with' or diag $@;
  }
}

done_testing;
