use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use IO::Select;
use IO::Socket::IP;
use POSIX ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::AccessBroker::Static;
use DBIO::Util qw(file_path write_file);

# LIVE (karr k33; core k242, ADR 0057). The counterpart of
# t/37-connect-params-dsn.t, which pins offline what DSN the seam
# _connect_params_dsn builds from { dbname, host, port } and says of itself:
# "Whether an Oracle listener ACCEPTS these DSNs is not provable offline and
# is not claimed here." This file is where it is claimed, against a real
# Oracle database over DBD::Oracle. The sections follow the live plan on the
# card:
#
#   1. host, port and dbname are a DSN the server accepts, the session is in
#      the SERVICE named, and the everyday operations run on it. As a SID the
#      same name is unknown to the listener: reading dbname as the service
#      name is what reaches a pluggable database at all.
#   2. host and dbname without a port: no port in the DSN, and the Oracle
#      client goes to 1521 by itself.
#   3. dbname alone is a name the Oracle client resolves: an alias from
#      tnsnames.ora and, failing that, an Easy Connect string. A name that is
#      neither does not connect anywhere.
#   4. What IS today where the card's question to the maintainer is still
#      open -- host without dbname, and no parameters at all. Nothing here
#      decides it; the tests hold what happens and who says so, so that a
#      decision has to touch them knowingly.
#   5. A reconnect after the broker's host changed goes to the new host.
#   6. An IPv6 host in brackets is taken by the client as the address it is;
#      without the brackets it is not.
#
# Two ways to the same database run side by side in 1:
#
#   pinned   a schema that loaded the Oracle component, connected with
#            connection parameters (DBIO::AccessBroker::Static, or a
#            connect-info hash without a dsn). This is the way karr k33 is
#            about.
#   written  a schema that declares the driver by storage_type, connected
#            with the DSN written by hand. (A schema without a declared
#            driver is refused at connect, whatever its DSN names -- core
#            ADR 0067; t/39-driver-declared.t pins that offline.)
#
# Both end as the same class, DBIO::Oracle::Storage (asserted below, after
# the connect: driver resolution is lazy). So the comparison is not between
# two storages but between a DSN this driver built and one a person wrote.
#
# Three things in here are not a plain connect, and why:
#
#   * a relay. A child process listens on a loopback address and passes every
#     connection on to the server of the DSN, noting the connect descriptor
#     the Oracle client sends first. It is how "no port means 1521" (it
#     listens on 127.0.0.1:1521), an IPv6 address ([::1]) and a second host
#     for the same database (5) exist on a machine that has none of them, and
#     how 4 can say what the client asks the listener for. The session behind
#     it is a real one. Where the address cannot be listened on, the section
#     skips and says so.
#   * a fresh perl for 3, for the empty DSN in 4 and for the bare IPv6 host in
#     6. The Oracle client reads tnsnames.ora once per process -- measured: a
#     TNS_ADMIN set after the first connect is named in the error message and
#     its aliases are still not found. That process gets a temporary
#     TNS_ADMIN holding tnsnames.ora and a sqlnet.ora that limits name
#     resolution to tnsnames.ora and Easy Connect. Without the second file
#     the same errors came 12 to 15 seconds later, once per process: the
#     client tries something else first for a name it cannot find.
#   * an alarm without a handler at the top. An OCI call cannot be
#     interrupted from Perl; a run that hangs ends after five minutes instead
#     of never. The next run drops what it left.
#
# Measured 2026-10-05 against Oracle Database 23ai Free (23.26.3), a pluggable
# database reached by its service name, with DBD::Oracle 1.95 built against
# Instant Client 23.26. What this file does NOT claim:
#
#   * a local SID. "dbi:Oracle:<SID>" for an instance on the same machine is
#     the Oracle client's bequeath connection; there is no local instance
#     here and Instant Client has no ORACLE_HOME to find one with. What was
#     seen instead: the SID as dbname alone is looked up like any other name
#     and ends in ORA-12154 (printed as a note in 3, not asserted); with
#     ORACLE_SID set to it and the empty DSN it is ORA-12545. Neither says
#     anything about a machine that has the instance.
#   * that a listener is reachable on port 1521, or over IPv6. Both arrive at
#     the relay on this machine. The claim is about the client: which port it
#     picks when the DSN names none, and that it takes a bracketed IPv6 host.
#   * what a listener does with a connection that names no service (4). That
#     is the listener's configuration. This one attaches the connection to a
#     database -- the error comes at the logon, not at the attach -- and the
#     logon of the test user is refused there: ORA-01017, the error of a
#     wrong password. Naming the instance's own service, the container
#     database's, gives the same answer, so that is presumably where it
#     went: a user of a pluggable database does not exist there. It could not
#     be looked at, there being no session. Other listeners were not seen;
#     by the Oracle documentation one without a default service refuses
#     (ORA-12504). The test asserts what the client sends and that the
#     answer is Oracle's; which answer it was is printed as a note.
#   * the error numbers on another client. ORA-12154, ORA-12162, ORA-12505
#     and ORA-12514 are what Instant Client 23.26 and this listener say.
#   * anything about DBIO::Oracle::Storage::WhereJoins. It inherits the seam
#     (t/37); no connection here is made with it.
#   * anything connection parameters cannot say: a SID on a host, TCPS, a
#     full descriptor. Those go in as a whole DSN (t/37).
#   * a test of its own for core's default form. t/37 has DBD::Oracle refuse
#     it without a server; here, taking the seam out turns 1 red (tried).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

# The parameters come out of the DSN, so that both ways provably go to the
# same place. Only the form the seam builds will do -- anything else in the
# DSN is something connection parameters cannot say, and the pinned way would
# silently be a different connection than the written one.
my ($host, $port, $dbname)
  = $dsn =~ m{\Adbi:Oracle://(\[[^\]/]+\]|[^:/\[\]]+):(\d+)/([^/:;?]+)\z};

plan skip_all => 'This test checks the DSN form built from connection '
  . 'parameters; $ENV{DBIO_TEST_ORA_DSN} must be exactly '
  . 'dbi:Oracle://<host>:<port>/<service name> (nothing else: no tnsnames '
  . 'alias, no host=..;sid=.., no descriptor)'
  unless defined $dbname;

my $BUILT = "dbi:Oracle://$host:$port/$dbname";

# Where a socket or tnsnames.ora wants the address itself.
( my $bare_host = $host ) =~ s/\A\[(.*)\]\z/$1/;

# A service is reported in the server's spelling, and with the database's
# domain where it has one.
my $SERVICE = qr/\Q$dbname\E(?:\.\S+)?/i;

my $PARENT = $$;

alarm 300;   # no handler: see above

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0]; warn $_[0] };

{
  # "id" comes from a sequence, through a BEFORE INSERT trigger.
  package T::K33::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k33_live_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  # "id" is an IDENTITY column: no trigger, no sequence of its own to name.
  package T::K33::Result::Ident;
  use base 'DBIO::Core';
  __PACKAGE__->table('k33_live_ident');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K33::Pinned;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
}

{
  # No driver component: the driver is declared by its storage class.
  package T::K33::Written;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Oracle::Storage');
}

for my $schema_class (qw(T::K33::Pinned T::K33::Written)) {
  $schema_class->register_class($_ => "T::K33::Result::$_") for qw(Item Ident);
}

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => $user,
    password => $pass,
    @_,
  );
}

my %CONNECT = (
  pinned => sub {
    T::K33::Pinned->connect(
      broker(host => $host, port => $port, dbname => $dbname),
    );
  },
  written => sub { T::K33::Written->connect($dsn, $user, $pass) },
);

# A third connection, plain DBI, for setup and for looking at what the server
# really holds: from another session, and through neither storage under test.
# A reader never waits for a writer on Oracle, so an uncommitted row of the
# other session is simply not there for this one.
my $admin;
sub admin {
  return $admin ||= DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }
sub server_rows  { admin()->selectall_arrayref(@_) }

# The service and the container a session is in, and the session itself: a
# number the server counts up, never given twice.
sub place_of {
  return join ' in ', $_[0]->selectrow_array(
    q{SELECT SYS_CONTEXT('USERENV', 'SERVICE_NAME'), }
  . q{SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL}
  );
}

sub session_of {
  return +( $_[0]->selectrow_array(
    q{SELECT SYS_CONTEXT('USERENV', 'SESSIONID') FROM DUAL}
  ) )[0];
}

# The driver quotes identifiers, so these names are lower case on the server
# and need their quotes there too. PURGE keeps the tables out of the recycle
# bin, where they would still be something of this test.
sub drop_tables {
  my $dbh = admin();
  for my $statement (
    'DROP TABLE "k33_live_item" PURGE',
    'DROP SEQUENCE "k33_live_item_seq"',
    'DROP TABLE "k33_live_ident" PURGE',
  ) {
    eval { $dbh->do($statement); 1 }
      or $@ =~ /ORA-(?:00942|02289)\b/   # nothing there to drop
      or die $@;
  }
}

# Every way starts from empty tables with the keys at their start, so the ids
# asserted below are the same on both.
sub fresh_tables {
  my $dbh = admin();
  drop_tables();
  $dbh->do($_) for (
    'CREATE TABLE "k33_live_item" ('
  . ' "id" NUMBER(12) PRIMARY KEY, "name" VARCHAR2(100))',
    'CREATE SEQUENCE "k33_live_item_seq" START WITH 1 INCREMENT BY 1 NOCACHE',
    'CREATE TRIGGER "k33_live_item_bi" BEFORE INSERT ON "k33_live_item" '
  . 'FOR EACH ROW BEGIN IF :new."id" IS NULL THEN '
  . 'SELECT "k33_live_item_seq".nextval INTO :new."id" FROM DUAL; '
  . 'END IF; END;',
    'CREATE TABLE "k33_live_ident" ('
  . ' "id" NUMBER(12) GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,'
  . ' "name" VARCHAR2(100))',
  );
}

# ---------------------------------------------------------------- the relay
#
# start_relay($address, $port) listens there ($port 0: any free one) and
# passes every connection on to the server of the DSN. stop_relay returns the
# connect descriptors it saw, one per connection, in the order they came --
# read after the child is gone, so there is nothing to wait for.

my %relay_pid;

sub descriptor_in {
  my ($bytes) = @_;
  my $start = index $bytes, '(DESCRIPTION=';
  return if $start < 0;

  my $depth = 0;
  for my $at ($start .. length($bytes) - 1) {
    my $char = substr $bytes, $at, 1;
    $depth++ if $char eq '(';
    $depth-- if $char eq ')';
    return substr $bytes, $start, $at - $start + 1 if !$depth;
  }
  return;
}

sub relay_loop {
  my ($listen, $report) = @_;

  my $select = IO::Select->new($listen);
  my (%peer, %head);

  while (1) {
    for my $socket ($select->can_read) {
      if ($socket == $listen) {
        my $client = $listen->accept or next;
        my $server = IO::Socket::IP->new(
          PeerHost => $bare_host, PeerPort => $port, Proto => 'tcp',
        ) or do { close $client; next };

        @peer{ $client, $server } = ($server, $client);
        $head{$client} = '';
        $select->add($client, $server);
        next;
      }

      my $other = $peer{$socket} or next;   # closed earlier in this round

      my $bytes;
      if (!sysread $socket, $bytes, 65536) {
        $select->remove($socket, $other);
        delete @peer{ $socket, $other };
        delete @head{ $socket, $other };
        close $_ for $socket, $other;
        next;
      }

      # The descriptor is at the start of what the client sends; a long one
      # comes in a packet of its own, so collect until it is whole.
      if (exists $head{$socket}) {
        $head{$socket} .= $bytes;
        if (defined( my $descriptor = descriptor_in($head{$socket}) )) {
          syswrite $report, "$descriptor\n";
          delete $head{$socket};
        }
        elsif (length $head{$socket} > 16384) {
          delete $head{$socket};
        }
      }

      my $sent = 0;
      while ($sent < length $bytes) {
        my $written = syswrite $other, $bytes, length($bytes) - $sent, $sent;
        last unless defined $written;
        $sent += $written;
      }
    }
  }
}

sub start_relay {
  my ($address, $listen_port) = @_;

  my $listen = IO::Socket::IP->new(
    LocalHost => $address, LocalPort => $listen_port,
    Listen    => 5,        ReuseAddr => 1,
    Proto     => 'tcp',
  ) or do {
    $@ = "cannot listen on $address port $listen_port ($@)";
    return;
  };

  pipe my $read, my $report or die "pipe: $!";

  my $pid = fork;
  die "fork: $!" unless defined $pid;

  if (!$pid) {
    # The child. It leaves through _exit and nowhere else: no END block of
    # this file, no destructor of a handle that is the parent's.
    eval {
      $SIG{ALRM} = $SIG{TERM} = 'DEFAULT';
      $SIG{PIPE} = 'IGNORE';
      alarm 120;   # outlives no run, whatever becomes of the parent

      # Nothing of the parent's stays open here, least of all the sockets of
      # its database connections.
      my %mine = map { fileno($_) => 1 } $listen, $report;
      POSIX::close($_) for grep { !$mine{$_} } 3 .. 1023;

      relay_loop($listen, $report);
    };
    POSIX::_exit(0);
  }

  close $report;
  $relay_pid{$pid} = 1;

  return { pid => $pid, port => $listen->sockport, read => $read };
}

sub stop_relay {
  my ($relay) = @_;

  kill TERM => $relay->{pid};
  waitpid $relay->{pid}, 0;
  delete $relay_pid{ $relay->{pid} };

  my $read = $relay->{read};
  chomp( my @descriptors = <$read> );
  return @descriptors;
}

# What a descriptor asks for: [ host, port ] of the address, and the service.
sub address_in {
  my ($address) = $_[0] =~ /\(ADDRESS=((?:\([^()]*\))+)\)/i or return [];
  my %part = map { lc } $address =~ /\((\w+)=([^()]*)\)/g;
  return [ @part{qw(host port)} ];
}

sub service_in { ( $_[0] =~ /\(SERVICE_NAME=([^()]*)\)/i )[0] }

# -------------------------------------------------------------- a fresh perl
#
# in_fresh_process(\%env, @given) connects once for each of @given -- broker
# parameters as "key=value,key=value", or '' for none -- through a Static
# broker and a schema with the Oracle component, in a new process with %env
# and its own TNS_ADMIN. For each it returns [ $dsn, $outcome ]: the DSN the
# storage built, and "in <service>" or the error.

my $FRESH_PROCESS = <<'PERL';
use strict;
use warnings;
use DBIO::Schema;
use DBIO::AccessBroker::Static;

{
  package T::K33::Fresh;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
}

alarm 60;   # no handler: a connect that hangs ends the process
$| = 1;     # ... and what was found until then is not lost with it

for my $given (@ARGV) {
  my $storage = T::K33::Fresh->connect(DBIO::AccessBroker::Static->new(
    username => $ENV{DBIO_TEST_ORA_USER},
    password => $ENV{DBIO_TEST_ORA_PASS},
    map { split /=/, $_, 2 } split(/,/, $given),
  ))->storage;

  my $service = eval {
    ( $storage->dbh->selectrow_array(
      q{SELECT SYS_CONTEXT('USERENV', 'SERVICE_NAME') FROM DUAL}
    ) )[0];
  };

  ( my $outcome = defined $service ? "in $service" : "$@" ) =~ s/\s+/ /g;
  print $storage->_dbi_connect_info->[0], "\t$outcome\n";
}
PERL

my $ALIAS = 'K33_LIVE_ALIAS';

my $tns_admin = File::Temp->newdir;

write_file(
  file_path("$tns_admin", 'tnsnames.ora'),
  "$ALIAS = (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$bare_host)(PORT=$port))"
. "(CONNECT_DATA=(SERVICE_NAME=$dbname)))\n",
);
write_file(
  file_path("$tns_admin", 'sqlnet.ora'),
  "NAMES.DIRECTORY_PATH = (TNSNAMES, EZCONNECT)\n",
);

sub in_fresh_process {
  my ($env, @given) = @_;

  # Neither variable is this test's to inherit: both name a database for the
  # empty DSN.
  delete local @ENV{qw(TWO_TASK ORACLE_SID)};
  local $ENV{TNS_ADMIN} = "$tns_admin";
  local @ENV{ keys %$env } = values %$env;

  open my $out, '-|', $^X, ( map { "-I$_" } grep { !ref } @INC ),
    '-e', $FRESH_PROCESS, @given
    or die "Cannot start a fresh perl: $!";

  chomp( my @lines = <$out> );
  close $out;

  return map { [ split /\t/, $_, 2 ] } @lines;
}

plan skip_all => 'This test needs Oracle 12c or later: it creates an IDENTITY column '
  . 'and asks which container a session is in'
  unless admin()->func('ora_server_version')->[0] >= 12;

my $live = 1;   # past every skip_all: from here on there is something to drop

drop_tables();  # what a run that died before its END block may have left

my $admin_place = place_of(admin());
my $instance
  = server_value(q{SELECT SYS_CONTEXT('USERENV', 'INSTANCE_NAME') FROM DUAL});

# ===================================================================== 1
# host + port + dbname: the DSN is accepted, reaches the service named, and
# carries the everyday operations.

# ------------------------------------------ 1a. the DSN connects, and where

{
  my $storage = $CONNECT{pinned}->()->storage;

  is $storage->_dbi_connect_info->[0], $BUILT,
    'pinned: host, port and dbname from a Static broker are the DSN '
  . 'dbi:Oracle://host:port/dbname -- what t/37 pins, here on the storage '
  . 'that is about to connect with it';

  lives_ok { $storage->ensure_connected }
    'pinned: the server accepts that DSN -- the thing t/37 could not show';

  lives_and { is place_of($storage->dbh), $admin_place }
    'pinned: the session is in the service and the container the DSN '
  . 'written by hand reaches';

  like $admin_place, qr/\A$SERVICE in /,
    '... and that service is the one dbname names: dbname went to the '
  . 'listener as the service name';
}

{
  my $storage = T::K33::Pinned->connect({
    host => $host, port => $port, dbname => $dbname,
    user => $user, password => $pass,
  })->storage;

  is $storage->_dbi_connect_info->[0], $BUILT,
    'pinned: a connect-info hash without a dsn builds the same DSN';

  lives_and { is place_of($storage->dbh), $admin_place }
    'pinned: ... and connects into the same service -- the broker is not '
  . 'the only way to the seam';
}

# The counter-proofs. That the session above is in the right service proves
# little if the listener would have put it there whatever the DSN said.

throws_ok {
  T::K33::Pinned->connect(
    broker(host => $host, port => $port, dbname => 'K33_LIVE_NO_SUCH_SERVICE'),
  )->storage->ensure_connected;
} qr/ORA-12514/,
  'pinned: a dbname the listener knows no service for does not connect -- '
. 'the name in the DSN is what the listener is asked for, nothing falls '
. 'back to a default';

# dbname as the SID is what DBD::Oracle's keyed form (host=..;sid=..;port=..)
# would have meant, and the other way these three parts could have been read.
SKIP: {
  skip 'The service name is the instance name too: on this database a SID '
     . 'and a service cannot be told apart', 1
    if lc $instance eq lc $dbname;

  my $dbh = DBI->connect(
    "dbi:Oracle:host=$bare_host;sid=$dbname;port=$port", $user, $pass,
    { RaiseError => 0, PrintError => 0 },
  );

  like +( $dbh ? 'connected' : DBI->errstr ), qr/ORA-12505/,
    'the same name as a SID is unknown to the listener: reading dbname as '
  . 'the SERVICE name is what reaches this database -- its instance is '
  . "$instance, and a pluggable database has no SID of its own";
}

# ---------------------------- 1b. everyday operations, the same on both ways
#
# What a broker user does all day, on the DSN this driver built and on the
# one written by hand. Each goes through SQL or a lookup only this driver has
# (RETURNING ... INTO, the sequence behind a trigger, SAVEPOINT, the ROWNUM
# window), and a second session looks at what the server holds afterwards.

for my $way (qw(pinned written)) {
  fresh_tables();

  my $schema  = $CONNECT{$way}->();
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Item');

  # Driver resolution is lazy: connect before looking at the class.
  $storage->ensure_connected;

  is ref $storage, 'DBIO::Oracle::Storage',
    "$way: connected, the storage is DBIO::Oracle::Storage -- "
  . ( $way eq 'pinned' ? 'the class the component named'
                       : 'the class storage_type declared, kept by driver '
                       . 'resolution on the hand-written DSN' );

  # the key of a new row, from the sequence behind the trigger
  my @ids = map { $rs->create({ name => "row $_" })->id } 1, 2;

  is_deeply \@ids, [ 1, 2 ],
    "$way: create() returns the key the trigger took from the sequence";

  is_deeply server_rows('SELECT "id", "name" FROM "k33_live_item" ORDER BY "id"'),
    [ [ 1, 'row 1' ], [ 2, 'row 2' ] ],
    "$way: ... and those are the keys the server gave these rows -- a key "
  . 'that merely looks plausible would send every later update and delete '
  . 'to the wrong row';

  my $ident = $schema->resultset('Ident');

  is_deeply [ map { $ident->create({ name => "row $_" })->id } 1, 2 ], [ 1, 2 ],
    "$way: create() returns the key of an IDENTITY column";

  is_deeply server_rows('SELECT "id", "name" FROM "k33_live_ident" ORDER BY "id"'),
    [ [ 1, 'row 1' ], [ 2, 'row 2' ] ],
    "$way: ... and those are the rows' keys on the server";

  # transactions, looked at from the other session: only a real COMMIT or
  # ROLLBACK is visible there
  $schema->txn_do(sub { $rs->create({ name => 'committed' }) });

  is server_value(
       q{SELECT COUNT(*) FROM "k33_live_item" WHERE "name" = 'committed'}
     ), 1,
    "$way: txn_do commits -- another session sees the row";

  throws_ok {
    $schema->txn_do(sub {
      $rs->create({ name => 'rolled back' });
      die "k33 rollback\n";
    });
  } qr/k33 rollback/, "$way: an exception inside txn_do comes out of it";

  is server_value(
       q{SELECT COUNT(*) FROM "k33_live_item" WHERE "name" = 'rolled back'}
     ), 0,
    "$way: ... and the row is gone: no half transaction left on the server";

  $schema->txn_do(sub {
    $rs->create({ name => 'before savepoint' });
    $schema->svp_begin('k33_sp');
    $rs->create({ name => 'after savepoint' });
    $schema->svp_rollback('k33_sp');
  });

  is_deeply
    server_rows(
      q{SELECT "name" FROM "k33_live_item" WHERE "name" LIKE '%savepoint'}
    ),
    [ [ 'before savepoint' ] ],
    "$way: a savepoint rollback undoes what came after it and keeps the "
  . 'transaction around it';

  # void context: the bulk path
  $rs->populate([ map { { name => "bulk $_" } } 1 .. 3 ]);

  is server_value(
       q{SELECT COUNT(*) FROM "k33_live_item" WHERE "name" LIKE 'bulk %'}
     ), 3,
    "$way: populate in void context inserts every row";

  my @all_ids = map { $_->[0] }
    @{ server_rows('SELECT "id" FROM "k33_live_item" ORDER BY "id"') };

  cmp_ok scalar @all_ids, '>', 3,
    "$way: (there are rows beyond the window asked for next)";

  is_deeply
    [ map { $_->id }
        $rs->search({}, { order_by => 'id', rows => 2, offset => 1 })->all ],
    [ @all_ids[ 1, 2 ] ],
    "$way: rows => 2, offset => 1 is the second and third row";

  # Without RETURNING the key is read back from the sequence, and which
  # sequence that is the driver finds in the trigger: a lookup in
  # ALL_TRIGGERS on the connection the parameters made.
  $storage->_use_insert_returning(0);

  my $by_sequence = $rs->create({ name => 'by sequence' });

  is $by_sequence->id,
    server_value(
      q{SELECT "id" FROM "k33_live_item" WHERE "name" = 'by sequence'}
    ),
    "$way: without INSERT ... RETURNING, create() still returns the row's key";

  my $sequence = $storage->get_autoinc_seq($rs->result_source, 'id');

  like +( ref $sequence ? $$sequence : $sequence ), qr/\."k33_live_item_seq"\z/,
    "$way: ... read from the sequence the trigger names";
}

# ===================================================================== 2
# host + dbname, no port. The DSN names none, and the documented default is
# the Oracle client's to apply. That it does is seen where the connection
# arrives: at a relay on port 1521 of this machine.

SKIP: {
  my $relay = start_relay('127.0.0.1', 1521)
    or skip "Nothing of this test can stand in for a listener on 1521: $@", 4;

  my $storage = T::K33::Pinned->connect(
    broker(host => '127.0.0.1', dbname => $dbname),
  )->storage;

  is $storage->_dbi_connect_info->[0], "dbi:Oracle://127.0.0.1/$dbname",
    'pinned: host and dbname without a port are //host/dbname -- no port in '
  . 'the DSN, no ":1521" made up';

  lives_and { is place_of($storage->dbh), $admin_place }
    'pinned: that DSN connects, into the service named -- through whatever '
  . 'listens on port 1521 of the host';

  $storage->disconnect;

  my @seen = stop_relay($relay);

  is_deeply [ map { address_in($_) } @seen ], [ [ '127.0.0.1', 1521 ] ],
    'the Oracle client went to port 1521 by itself, once: the default is '
  . 'the client\'s, as the DSN leaves it';

  like service_in($seen[0] // ''), qr/\A\Q$dbname\E\z/i,
    '... asking the listener for the service dbname names';
}

# ===================================================================== 3
# dbname alone: dbi:Oracle:<dbname>, a name for the Oracle client to resolve.
# In a fresh perl each, see the head of this file.

{
  my ($alias, $unknown, $easy, $sid) = in_fresh_process(
    {},
    "dbname=$ALIAS",
    'dbname=k33-live.invalid',
    "dbname=$host:$port/$dbname",
    "dbname=$instance",
  );

  is $alias->[0], "dbi:Oracle:$ALIAS",
    'pinned: dbname alone is the DSN dbi:Oracle:<dbname>';

  like $alias->[1], qr/\Ain $SERVICE\z/,
    'pinned: a dbname that tnsnames.ora defines connects, into the service '
  . 'the alias stands for -- host and port come from that file, the DSN '
  . 'has none';

  like $unknown->[1], qr/ORA-12154/,
    'pinned: a dbname that is neither an alias nor a host does not connect: '
  . 'the client cannot resolve it, and nothing falls back to a local '
  . 'instance or a default host';

  # What "a name the client resolves" means beyond tnsnames.ora, on a client
  # without a local instance: the next thing it tries is Easy Connect.
  is $easy->[0], "dbi:Oracle:$host:$port/$dbname",
    'pinned: a dbname with a host and a port in it is passed on as it is';

  like $easy->[1], qr/\Ain $SERVICE\z/,
    'pinned: ... and connects: a name tnsnames.ora does not define is read '
  . 'as an Easy Connect string by the client, host first';

  # Not asserted: what the instance's SID does as a dbname alone is this
  # machine's answer and no other's, see the head of this file.
  note "dbname alone, the SID of the instance ($instance), from this "
     . 'machine: ' . ( $sid->[1] // 'no answer' );
}

# ===================================================================== 4
# What IS today, where the question to the maintainer is open (karr k33:
# allow host without dbname, and no parameters at all, or refuse them as the
# DB2 driver does). The seam builds a DSN for both and refuses neither.

# ------------------------------------------------ 4a. host without dbname

SKIP: {
  my $relay = start_relay('127.0.0.1', 0)
    or skip "No relay on the loopback address: $@", 3;

  my $storage = T::K33::Pinned->connect(
    broker(host => '127.0.0.1', port => $relay->{port}),
  )->storage;

  is $storage->_dbi_connect_info->[0], "dbi:Oracle://127.0.0.1:$relay->{port}",
    'IS: host and port without dbname are the DSN //host:port -- built, not '
  . 'refused';

  my $place = eval { place_of($storage->dbh) };
  my $error = $@;

  $storage->disconnect;

  my @seen = stop_relay($relay);

  is_deeply [ map { service_in($_) } @seen ], [ '' ],
    'IS: the client asks the listener for no service at all -- SERVICE_NAME '
  . 'is empty in what it sends. Not the host name, which is what the '
  . 'DBD::Oracle documentation says it would be';

  # Which service a listener gives a connection that names none is its
  # configuration. Whatever it is, it is the Oracle side that says so.
  my $answer = defined $place ? "a session in $place"
    : $error =~ /(ORA-\d+[^\n]*).*?DBD ERROR: (\w+)/s ? "$1 (at $2)"
    : "no ORA error: $error";

  like $answer, qr/\A(?:a session in |ORA-\d+)/,
    'IS: what comes of it is the Oracle side\'s answer, a session or an ORA '
  . 'error -- this driver neither refuses the parameters nor names a '
  . 'service for them';

  note "host without dbname, on this server: $answer";
  note "(with dbname the same connection is in: $admin_place)";
}

# --------------------------------------------- 4b. no parameters at all

{
  my ($nothing) = in_fresh_process({}, '');

  is $nothing->[0], 'dbi:Oracle:',
    'IS: no connection parameters at all are the DSN dbi:Oracle: -- built, '
  . 'not refused';

  like $nothing->[1], qr/ORA-12162/,
    'IS: with neither TWO_TASK nor ORACLE_SID set it does not connect, and '
  . 'the one who says so is the Oracle client: the DSN names no database '
  . 'and the environment none either';

  my ($two_task) = in_fresh_process({ TWO_TASK => "//$host:$port/$dbname" }, '');

  is $two_task->[0], 'dbi:Oracle:',
    'IS: (the same empty DSN)';

  like $two_task->[1], qr/\Ain $SERVICE\z/,
    'IS: with TWO_TASK naming a database it connects there -- the empty DSN '
  . 'is the form DBD::Oracle documents for exactly that';
}

# ===================================================================== 5
# A reconnect after the host changed. Core asks the broker anew for every
# connection (t/37 shows the DSN it then hands to DBI->connect); here the
# first host really goes away under an open connection.

SKIP: {
  my $relay = start_relay('127.0.0.1', 0)
    or skip "No relay on the loopback address: $@", 8;

  my $broker
    = broker(host => '127.0.0.1', port => $relay->{port}, dbname => $dbname);
  my $storage = T::K33::Pinned->connect($broker)->storage;

  my $first = session_of($storage->dbh);

  is $storage->_dbi_connect_info->[0],
    "dbi:Oracle://127.0.0.1:$relay->{port}/$dbname",
    'pinned: the first connection is made with the host the broker names '
  . 'then';

  $broker->host($host);
  $broker->port($port);

  is session_of($storage->dbh), $first,
    'pinned: a new answer of the broker alone moves nothing -- the open '
  . 'connection stays the session it was';

  # The first host is gone, and the connection that ran over it with it.
  my @seen = stop_relay($relay);

  is_deeply [ map { address_in($_) } @seen ],
    [ [ '127.0.0.1', $relay->{port} ] ],
    'pinned: (that connection, and no other, went to the first host)';

  # Core (karr dbio k303) discards the old handle before it reconnects, and
  # says so once: that one warning is expected here, anything else is not.
  my ($second, @retry);
  {
    my $outer = $SIG{__WARN__};
    local $SIG{__WARN__} = sub {
      $_[0] =~ /_abandon_handle_before_reconnect\(\): Retrying on a new connection: the old handle is disconnected/
        ? push @retry, $_[0] : $outer->(@_);
    };
    lives_ok { $second = $storage->dbh_do(sub { session_of($_[1]) }) }
      'pinned: the next statement runs all the same: the storage reconnects';
  }

  is scalar(@retry), 1,
    'pinned: ... and core says once that it retries on a new connection';

  isnt $second, $first,
    'pinned: ... as a new session';

  is $storage->_dbi_connect_info->[0], $BUILT,
    'pinned: ... with a DSN built again from what the broker answers now: '
  . 'the other host and port';

  lives_and { is place_of($storage->dbh), $admin_place }
    'pinned: ... in the service named, as before';
}

# ===================================================================== 6
# An IPv6 host. The seam writes host into the DSN as given and adds no
# brackets; the Oracle client takes an IPv6 address only inside them.

SKIP: {
  my $relay = start_relay('::1', 0)
    or skip "No IPv6 loopback address to listen on: $@", 5;

  # Without the brackets first, in a fresh perl: see the head of this file.
  my ($bare) = in_fresh_process(
    {}, "host=::1,port=$relay->{port},dbname=$dbname",
  );

  is $bare->[0], "dbi:Oracle://::1:$relay->{port}/$dbname",
    'pinned: a bare IPv6 host goes into the DSN as given -- no brackets '
  . 'added';

  like $bare->[1], qr/ORA-\d+/,
    'pinned: ... and that DSN does not connect';

  my $storage = T::K33::Pinned->connect(
    broker(host => '[::1]', port => $relay->{port}, dbname => $dbname),
  )->storage;

  is $storage->_dbi_connect_info->[0],
    "dbi:Oracle://[::1]:$relay->{port}/$dbname",
    'pinned: an IPv6 host in brackets goes into the DSN with them';

  lives_and { is place_of($storage->dbh), $admin_place }
    'pinned: ... and that DSN connects, into the service named';

  $storage->disconnect;

  my @seen = stop_relay($relay);

  is_deeply [ map { address_in($_) } @seen ], [ [ '::1', $relay->{port} ] ],
    'the client went to the IPv6 address once, for the bracketed host: the '
  . 'bare one never arrived there -- it was not read as an address at all';
}

# ================================================================ the end

drop_tables();

is_deeply
  server_rows(
    q{SELECT object_name FROM user_objects }
  . q{WHERE LOWER(object_name) LIKE 'k33\_live%' ESCAPE '\'}
  ),
  [],
  'nothing of this test is left in the schema';

is_deeply
  server_rows(
    q{SELECT original_name FROM user_recyclebin }
  . q{WHERE LOWER(original_name) LIKE 'k33\_live%' ESCAPE '\'}
  ),
  [],
  '... and nothing in its recycle bin';

is_deeply \@warnings, [], 'no warning on the way';

done_testing;

# The relays and the tables again, on a new connection: for a run that died
# on the way.
END {
  if ($live && $$ == $PARENT) {
    local $?;
    kill TERM => keys %relay_pid;
    waitpid $_, 0 for keys %relay_pid;
    undef $admin;
    eval { drop_tables(); 1 }
      or diag "Could not drop the k33_live_* objects: $@";
  }
}
