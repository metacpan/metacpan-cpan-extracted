use strict;
use warnings;
use Test::More;

# LIVE test for karr k63: a DBIO::AccessBroker::Static whose dbname is a whole
# DSN,
#
#   DBIO::AccessBroker::Static->new(
#     dbname => 'dbi:mysql:database=app;host=db1', username => ..., password => ...,
#   );
#
# WHY: that is a form core documents (DBIO::AccessBroker::Static, ADR 0057): a
# dbname that starts with dbi: is taken as the DSN, and the sync storage
# connects to the server it names. The broker still answers a hash of
# connection parameters -- { dbname => <the DSN>, host => undef, port => undef,
# user, password } -- and this transport reads a hash as EV::MariaDB named
# parameters, dbname as database. So the DSN string became the database NAME,
# no host was given, and EV::MariaDB, which had a user, started a connect: to
# the client library's default, the local server, with the broker's user and
# password. The server the DSN names was never asked. A caller who moved a
# working sync connect to { async => 'ev' } sent that broker's credentials to
# whatever listens on the local socket.
#
# Measured before the fix, 2026-10-05, with EV::MariaDB 0.08, the DSN of a
# MySQL 8.0.30 and of a MariaDB 11.8.8 server (both on another host), the same
# for both:
#   - the sync storage connects to the server in the DSN, DATABASE() is the
#     database the DSN names;
#   - the ev attach was accepted (connect_info refuses an answer that names
#     neither a host nor a user; this one names a user);
#   - _async_broker_conninfo, and with it EV::MariaDB->new, got
#     database = the DSN string, host = undef, port = undef, the user and the
#     password;
#   - the connect went to the client library's default unix socket. Nothing
#     listened there on the measuring host, so the pool's acquire, and the
#     first call alike, failed at once with the client library's
#       Can't connect to local server through socket '<path>' (2)
#     What a local server answers to those credentials was not measured.
#
# Decided (karr k63): the transport refuses such an answer. It does not read
# the DSN out of the hash. What this file holds, against a server:
#   1. the reference: the sync storage connects from this broker, to the
#      database the DSN names;
#   2. the same broker with { async => 'ev' }: Schema->connect goes through --
#      the transport is not built yet -- and the first ->async is refused, and
#      every one after it, and a statement on the async API, naming the form
#      and what the broker is to answer instead, and nothing of the DSN;
#   3. the transport given the broker directly refuses it at connect_info, and
#      under a HostBound view that binds the server's own host in as well;
#   4. a broker whose answer TURNS into this form after the pool has a
#      connection: the next pool connection and the listen connection are
#      refused, and the connection already out stays where it is;
#   5. what the refusal says to do instead works: the same DSN answered in the
#      DBI form puts the pooled connection on the server and in the database
#      the sync storage reached.
# And for the whole file: EV::MariaDB is never handed a DSN string as its
# database, and no handle is made without the host the DSN names. Every
# EV::MariaDB->new of the process is recorded, the pool's and the listen
# connection's alike, so this file makes no connect attempt at the client
# library's default any more.
#
# What was measured is printed. The DSN, the user and the password come from
# the environment and are never printed: parameters are shown by shape.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::MariaDB;
use Future;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Storage;

# Every wait below is bounded by a timer of its own; nothing here awaits
# through the harness, so the file's alarm stays set.
$SIG{ALRM} = sub { BAIL_OUT('t/38-access-broker-dsn-dbname-live.t: alarm, a wait did not end') };
alarm 120;

my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

# What the DSN means, as this transport reads a DBI DSN everywhere else.
my $want = eval { DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo([ $DSN ])->[0] }
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN is not a dbi:mysql: / dbi:MariaDB: DSN';

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package T38L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

# A broker answering whatever the test puts in it.
{
  package T38L::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# Which server a session is on, and which database it is in.
my $WHERE = 'SELECT VERSION(), @@hostname, @@port, DATABASE()';

sub wait_for {
  my ($f, $seconds) = @_;
  my $late  = 0;
  my $timer = EV::timer($seconds, 0, sub { $late = 1 });
  EV::run(EV::RUN_ONCE) until $f->is_ready || $late;
  return $f->is_ready;
}

# An error on one line, without the places it was raised at.
sub bare {
  my ($err) = @_;
  $err = "$err";
  $err =~ s{ at \S+ line \d+\.?}{}g;
  $err =~ s{\s*\n\s*\.?\s*}{ | }g;
  $err =~ s{[\s|]+\z}{};
  return $err;
}

# Named parameters by shape: never a value.
sub shape {
  my ($params) = @_;
  return join ', ', map {
    my $value = $params->{$_};
    "$_ = " . ( !defined $value         ? 'undef'
              : ref $value              ? lc(ref $value) . ' ref'
              : $value eq $DSN          ? 'the DSN string'
              : $value =~ /^dbi:/i      ? 'a DSN string'
              :                           'set' );
  } sort keys %$params;
}

# Every handle made in this process, the pool's and the listen connection's:
# the named parameters EV::MariaDB is given.
our @NEW;
{
  no warnings 'redefine';
  my $new = \&EV::MariaDB::new;
  *EV::MariaDB::new = sub {
    my ($class, %args) = @_;
    push @NEW, { map { $_ => $args{$_} } grep { !/^on_/ } keys %args };
    goto &$new;
  };
}

# One pooled connection of $storage, and where its session is: the row of
# $WHERE, or an error. The connection is given back.
sub pooled_where {
  my ($storage) = @_;
  my $acquire = eval { $storage->pool->acquire } // Future->fail(bare($@));
  return (undef, 'the acquire was not answered within 30s') unless wait_for($acquire, 30);
  return (undef, bare(($acquire->failure)[0])) if $acquire->is_failed;

  my $conn  = $acquire->get;
  my $asked = Future->new;
  $conn->query($WHERE, sub {
    my ($rows, $err) = @_;
    $err ? $asked->fail($err) : $asked->done($rows->[0]);
  });
  wait_for($asked, 30);
  $storage->pool->release($conn);
  return ($asked->get) if $asked->is_done;
  return (undef, $asked->is_ready ? bare($asked->failure) : 'not answered within 30s');
}

sub same_place {
  my ($one, $other) = @_;
  return $one && $other
    && join("\0", map { $_ // '' } @$one) eq join("\0", map { $_ // '' } @$other);
}

my $REFUSED = qr/MySQL ev cannot connect from what the AccessBroker returned: a hashref with keys \(dbname, host, password, port, user\) whose database name is a whole DBI DSN/;

# The refusal: what it says, and what it must not. The values the DSN is made
# of are looked for one by one; a short one (a port, a one-letter name) says
# nothing when it turns up in a sentence, so only those of four characters
# and more are.
sub is_the_refusal {
  my ($err, $when) = @_;
  $err = bare($err // '');
  like $err, $REFUSED, "$when: refused, naming the form of the answer";
  like $err, qr/answer the DSN in the DBI form \[ \$dsn, \$user, \$password \], or the database name as dbname with host and port beside it/,
    '... and what the broker is to answer instead';
  my @quoted = grep { defined($_) && length($_) > 3 && index($err, $_) >= 0 }
    $DSN, $PASS, values %$want;
  is scalar(@quoted), 0, '... with nothing of the DSN, and not the password';
  return;
}

my $broker = DBIO::AccessBroker::Static->new(
  dbname   => $DSN,
  username => $USER,
  password => $PASS,
);

my ($sync_schema, $ev_schema, @storages);
END {
  eval { $_->disconnect } for grep { $_ } @storages;
  eval { $_->storage->disconnect } for grep { $_ } $ev_schema, $sync_schema;
}

# ---------------------------------------------------------------------------
# 1. The reference: the sync storage, from the same broker.
# ---------------------------------------------------------------------------

$sync_schema = T38L::Schema->connect($broker);
my $sync_where = eval { $sync_schema->storage->dbh->selectrow_arrayref($WHERE) };
ok $sync_where, 'sync: a Static broker whose dbname is a whole DSN connects'
  or diag bare($@);
is $sync_where && $sync_where->[3], $want->{database},
  '... to the database the DSN names';
diag 'server: ' . ($sync_where ? $sync_where->[0] : 'not reached') . ', EV::MariaDB ' . EV::MariaDB->VERSION;

# ---------------------------------------------------------------------------
# 2. The same broker with { async => 'ev' }.
# ---------------------------------------------------------------------------

$ev_schema = eval { T38L::Schema->connect($broker, { async => 'ev', pool_size => 1 }) };
ok $ev_schema, 'ev: Schema->connect with that broker goes through -- the transport is not built yet'
  or diag bare($@);

SKIP: {
  skip 'the connect itself was refused', 9 unless $ev_schema;

  for my $ask ('the first ->async', '->async again') {
    my $async = eval { $ev_schema->storage->async };
    my $err   = $@;
    ok !$async, "ev, $ask: no transport is handed out";
    is_the_refusal($err, "ev, $ask");
    push @storages, $async if $async;
  }

  my $f   = eval { $ev_schema->storage->select_async(\'(SELECT 1 AS one) me', [ 'one' ]) };
  my $err = !$f ? $@ : wait_for($f, 30) ? ($f->is_failed ? ($f->failure)[0] : 'it ran') : 'it did not settle';
  like bare($err), $REFUSED, 'ev: a statement on the async API is not run, for the same reason';
}

is scalar(@NEW), 0, 'ev: nothing was handed to EV::MariaDB';

# ---------------------------------------------------------------------------
# 3. The transport given the broker directly, and a HostBound view over it.
# ---------------------------------------------------------------------------

{
  my $s   = DBIO::MySQL::EV::Storage->new(undef);
  my $ok  = eval { $s->connect_info([ $broker ]); 1 };
  my $err = $@;
  push @storages, $s;
  ok !$ok, 'the transport, connect_info([ $broker ]): it croaks';
  is_the_refusal($err, 'the transport');
  ok !eval { my $f = $s->pool->acquire; wait_for($f, 30); die +($f->failure)[0] if $f->is_failed; 1 },
    '... and a pool connection asked for afterwards is not opened';

  SKIP: {
    skip 'the DSN names no host: there is none to bind in', 4 unless defined $want->{host};
    # The view binds the very host the DSN names into the hash: the answer has
    # a host now, and the database's name is still a DSN.
    my $bound = $broker->for_host({ host => $want->{host}, port => $want->{port} // 3306 });
    my $s     = DBIO::MySQL::EV::Storage->new(undef);
    my $ok    = eval { $s->connect_info([ $bound ]); 1 };
    my $err   = $@;
    push @storages, $s;
    ok !$ok, 'the transport, a HostBound view over that broker: it croaks';
    is_the_refusal($err, 'HostBound over it');
  }

  is scalar(@NEW), 0, '... nothing was handed to EV::MariaDB';
}

# ---------------------------------------------------------------------------
# 4. An answer that turns into this form with a pool connection out.
# ---------------------------------------------------------------------------

{
  my %good = (
    ( map { ($_ eq 'database' ? 'dbname' : $_) => $want->{$_} } keys %$want ),
    user => $USER, password => $PASS,
  );
  my $turning = T38L::AnswerBroker->new({ %good });
  my $s       = DBIO::MySQL::EV::Storage->new(undef);
  push @storages, $s;
  ok eval { $s->connect_info([ $turning, { pool_size => 2 } ]); 1 },
    'a broker answering the DSN\'s parts as parameters: the transport takes it' or diag bare($@);

  my $first = eval { $s->pool->acquire };
  ok $first && wait_for($first, 30) && $first->is_done, '... and a pool connection is opened'
    or diag $first && $first->is_failed ? bare(($first->failure)[0]) : bare($@);
  my $made = @NEW;

  $turning->{answer} = $broker->connect_info_for('write');

  my $second = eval { $s->pool->acquire } // Future->fail($@);
  wait_for($second, 30);
  is_the_refusal($second->is_failed ? ($second->failure)[0] : 'a connection was handed out',
    'the answer turns into a DSN as dbname: the next pool connection');

  my $listen = eval { $s->_listen_open };
  my $err    = $@;
  ok !$listen, '... the listen connection is not opened either';
  like bare($err), $REFUSED, '... for the same reason';
  is scalar(@NEW), $made, '... and no further handle was made';

  SKIP: {
    skip 'the first pool connection was not opened', 1 unless $first && $first->is_done;
    my $conn  = $first->get;
    my $asked = Future->new;
    $conn->query($WHERE, sub { $_[1] ? $asked->fail($_[1]) : $asked->done($_[0][0]) });
    wait_for($asked, 30);
    ok same_place($asked->is_done ? $asked->get : undef, $sync_where),
      '... the connection already out is still on the server the sync storage reached';
    $s->pool->release($conn);
  }
}

# ---------------------------------------------------------------------------
# 5. What the refusal says to do instead: the DSN in the DBI form.
# ---------------------------------------------------------------------------

{
  my $schema = eval {
    T38L::Schema->connect(T38L::AnswerBroker->new([ $DSN, $USER, $PASS ]), { async => 'ev', pool_size => 1 });
  };
  my $async = $schema && eval { $schema->storage->async };
  ok $async, 'the same DSN answered in the DBI form: the transport is built' or diag bare($@);

  SKIP: {
    skip 'no transport', 1 unless $async;
    push @storages, $async;
    my ($where, $err) = pooled_where($async);
    ok same_place($where, $sync_where),
      '... and its pooled connection is on the server and in the database the sync storage reached'
      or diag $err // 'it is somewhere else';
  }
  eval { $schema->storage->disconnect } if $schema;
}

# ---------------------------------------------------------------------------
# For the whole file.
# ---------------------------------------------------------------------------

diag 'EV::MariaDB->new was given: ' . shape($_) for @NEW;
diag 'no handle was made' unless @NEW;
diag 'warned: ' . bare($_) for @warnings;

ok !( grep { defined $_->{database} && $_->{database} =~ /^dbi:/i } @NEW ),
  'EV::MariaDB was never handed a DSN string as its database';

SKIP: {
  skip 'the DSN names no host', 1 unless defined $want->{host};
  ok !( grep { !defined $_->{host} || $_->{host} ne $want->{host} } @NEW ),
    'no handle was made without the host the DSN names: nothing went to the client library\'s default';
}

done_testing;
