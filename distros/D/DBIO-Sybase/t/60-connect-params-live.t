use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::AccessBroker::Static;

# LIVE (karr k59; core k242, ADR 0057). The counterpart of
# t/57-connect-params-dsn.t, which pins offline what DSN the seam
# _connect_params_dsn builds from { dbname, host, port } and says of itself:
# "Whether a server ACCEPTS these DSNs is not provable offline and is not
# claimed here." This file is where it is claimed, against a real ASE:
#
#   1. host, port and dbname from a DBIO::AccessBroker::Static are a DSN the
#      server accepts, and the session is in the database named;
#   2. the counter-proof, and the reason the seam exists: with core's default
#      form in its place -- dbname= for database= -- the same connect succeeds
#      without a word and the session is in the login's default database;
#   3. host and port without dbname connect into the login's default database:
#      no database= is made up;
#   4. a reconnect after disconnect is in the database named again -- a new
#      session placed by the DSN, built again from what the broker answers
#      then;
#   5. an insert through the broker that runs on the ASE writer storage: a
#      second connection, which builds its own DSN from the same broker;
#   6. dbname alone, dbi:Sybase:database=.., reaches the server the client
#      library names ($DSQUERY) -- and what a lone host or a lone port, which
#      the seam refuses, would have done instead.
#
# Two ways to the seam run side by side:
#
#   component  a schema that loaded the Sybase component -- the way the POD
#              recommends and karr k59 is about. Its storage is
#              DBIO::Sybase::Storage when the seam is asked, and becomes
#              DBIO::Sybase::Storage::ASE at its first use
#              (DBIO::Sybase::Storage::_adapt_to_access_path, karr k64; held
#              offline in t/59-component-rebless.t and with rows in
#              t/62-component-rebless-live.t). Here the class is asserted
#              after the connect, and beyond that only what k59 claims -- the
#              DSN, that the server accepts it, where the session is. No row
#              is written through it.
#   ase        a schema that pins DBIO::Sybase::Storage::ASE as storage_type,
#              as t/58-broker-dsn-patches.t does: connection parameters carry
#              no DSN to detect a driver from, so the class has to be a
#              driver's from the start -- the declared base, as above, or this
#              one. Pinned, it goes through _init, where the FreeTDS trait
#              class and the writer storage come from.
#
# Driver resolution is lazy: it runs at the first dbh access. So every storage
# is connected before its class is looked at.
#
# Measured 2026-10-05 against SAP ASE 16.0 SP02 PL02, with DBD::Sybase 1.27
# built against FreeTDS 1.3.17, TDS 5.0. What this file does NOT claim:
#
#   * anything about the Sybase Open Client libraries. No connection here was
#     made with them. Where a test needs FreeTDS (the server name in 6 comes
#     from a temporary freetds.conf) or cannot run under it (the TEXT write in
#     5), it says so and skips; the branch for the other client library has
#     never been run.
#   * that a TEXT/IMAGE value can be written through a broker. The card's plan
#     calls 5 a "blob insert". Under FreeTDS a TEXT write throws ("TEXT/IMAGE
#     operation failed, probably because you are using FreeTDS", seen on this
#     server with and without a broker) and the row is rolled back. What does
#     run on the writer storage under FreeTDS is every insert that has to read
#     back an IDENTITY value outside a transaction, and that is what 5 is.
#   * that the DSN keeps what the driver appends to it afterwards
#     (;maxConnect=256). With a broker it does not: karr k60,
#     t/61-broker-dsn-patches-live.t.
#   * what the component way can do beyond connecting: that is
#     t/62-component-rebless-live.t (karr k64).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

# The parameters come out of the DSN, so that the broker provably goes where
# the DSN goes. Only the form the seam builds will do: anything else in the
# DSN is something connection parameters cannot say.
my %dsn_part = $dsn =~ /\Adbi:Sybase:(.*)\z/s
  ? ( map { /\A([^=]+)=(.*)\z/s ? ($1 => $2) : ($_ => '') } split /;/, $1 )
  : ();
my ($host, $port, $dbname) = @dsn_part{qw(host port database)};

plan skip_all => 'This test checks the DSN form built from connection '
  . 'parameters; $ENV{DBIO_TEST_SYBASE_DSN} must be exactly '
  . 'dbi:Sybase:host=<host>;port=<port>;database=<database> (nothing else, '
  . 'no server=<name>)'
  unless keys %dsn_part == 3
    and 3 == grep { defined && length } $host, $port, $dbname;

my $BUILT = "dbi:Sybase:host=$host;port=$port;database=$dbname";

# A second database every ASE has, for telling "in the database named" from
# "wherever the session was".
my $OTHER = $dbname eq 'tempdb' ? 'master' : 'tempdb';

{
  package T::K59::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k59_live_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K59::Result::Blob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k59_live_blob');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    body => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K59::Component;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

{
  package T::K59::ASE;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
}

my %SCHEMA = (component => 'T::K59::Component', ase => 'T::K59::ASE');

for my $schema_class (values %SCHEMA) {
  $schema_class->register_class($_ => "T::K59::Result::$_") for qw(Item Blob);
}

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => $user,
    password => $pass,
    @_,
  );
}

# Plain DBI, with the DSN as it was given: for setup, and for looking at what
# the server holds from another session and through no storage under test.
my $admin;
sub admin {
  return $admin ||= DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }
sub server_rows  { admin()->selectall_arrayref(@_) }

sub db_of   { ( $_[0]->selectrow_array('select db_name()') )[0] }
sub spid_of { ( $_[0]->selectrow_array('select @@spid') )[0] }

# The server's address is the environment's and stays out of the output.
sub masked {
  my $dsn = shift // '(undef)';
  $dsn =~ s/\b(host|port)=[^;]*/$1=../g;
  return $dsn;
}

sub dsn_is {
  my ($got, $expected, $name) = @_;
  ok defined $got && $got eq $expected, $name
    or diag 'the DSN is ' . masked($got) . ', expected ' . masked($expected);
}

my @TABLES = qw(k59_live_item k59_live_blob);

sub drop_tables {
  for my $table (@TABLES) {
    admin()->do("drop table $table") if server_value(
      "select count(*) from sysobjects where name = '$table' and type = 'U'"
    );
  }
}

sub fresh_item_table {
  drop_tables();
  admin()->do(
    'create table k59_live_item ('
  . ' id int identity primary key, name varchar(100) null)'
  );
}

my $live = 1;   # past every skip_all: from here on there is something to drop

drop_tables();  # what a run that died before its END block may have left

my $FREETDS    = ( admin()->{syb_oc_version} || '' ) =~ /freetds/i;
my $default_db = server_value(
  'select dbname from master..syslogins where name = suser_name()'
);

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );
note "the login's default database is $default_db, the test database $dbname";

# ============================================== 1, 3, 4: on both ways in

for my $way (qw(component ase)) {

  # ------------------------------------- 1. all three parts, and where to
  {
    my $broker  = broker(host => $host, port => $port, dbname => $dbname);
    my $storage = $SCHEMA{$way}->connect($broker)->storage;

    dsn_is $storage->_dbi_connect_info->[0], $BUILT,
      "$way: host, port and dbname from a Static broker are the DSN "
    . 'dbi:Sybase:host=..;port=..;database=.. -- what t/57 pins, here on the '
    . 'storage that is about to connect with it';

    my $dbh;
    lives_ok { $dbh = $storage->dbh }
      "$way: the server accepts that DSN -- the thing t/57 could not show"
      or next;

    is $dbh->{Driver}{Name}, 'Sybase',
      "$way: the connection runs on DBD::Sybase";

    is db_of($dbh), $dbname,
      "$way: the session is in the database the parameters name";

    note "$way: connected, the storage is a " . ref $storage;

    # On the component way the storage was DBIO::Sybase::Storage when the
    # seam built the DSN, and moved here at this first use (karr k64).
    isa_ok $storage, 'DBIO::Sybase::Storage::ASE',
      "$way: the storage that connected";

    SKIP: {
      skip 'DBD::Sybase is not built against FreeTDS: no trait class', 1
        unless $FREETDS;

      isa_ok $storage, 'DBIO::Sybase::Storage::FreeTDS',
        "$way: ... reblessed by _init into the FreeTDS trait class, which "
      . 'makes every reconnect below, and it';
    }

    # ---------------------------------------- 4. reconnect after disconnect
    #
    # The session is sent somewhere else first. A reconnect that comes back
    # in the database named is then a new session placed by the DSN, and not
    # the old one, or one that merely stayed where it was.
    $dbh->do("use $OTHER");

    is db_of($storage->dbh), $OTHER,
      "$way: (the session has been moved to $OTHER)";

    $storage->disconnect;

    ok !$storage->connected, "$way: (disconnected)";

    $storage->ensure_connected;

    is db_of($storage->dbh), $dbname,
      "$way: the reconnect is in the database named again";

    # Core asks the broker anew for every connection, and the seam with it:
    # what the broker answers THEN is where the next session is.
    $broker->dbname($OTHER);
    $storage->disconnect;
    $storage->ensure_connected;

    is db_of($storage->dbh), $OTHER,
      "$way: the broker now answering dbname $OTHER, the next reconnect is "
    . 'in that one -- database= is built from the answer of the moment, and '
    . 'the server honours it for a database that is not the first one too';

    $storage->disconnect;
  }

  # ----------------------------------------- 3. host and port, no dbname
  {
    my $storage
      = $SCHEMA{$way}->connect(broker(host => $host, port => $port))->storage;

    dsn_is $storage->_dbi_connect_info->[0],
      "dbi:Sybase:host=$host;port=$port",
      "$way: host and port without dbname are a DSN without database=";

    is db_of($storage->dbh), $default_db,
      "$way: ... and it connects into the login's default database -- none "
    . 'is made up';

    $storage->disconnect;
  }
}

# The broker is not the only way to the seam.
{
  my $storage = T::K59::Component->connect({
    host => $host, port => $port, dbname => $dbname,
    user => $user, password => $pass,
  })->storage;

  dsn_is $storage->_dbi_connect_info->[0], $BUILT,
    'component: a connect-info hash without a dsn builds the same DSN';

  is db_of($storage->dbh), $dbname,
    'component: ... and connects into the same database';

  $storage->disconnect;
}

# ============================================================ 2. counter-proof
#
# Why the seam exists. Core's default form is put back in its place, and
# nothing else is changed: same schema, same broker, same path.

SKIP: {
  skip "The login's default database is the test database ($dbname): this "
     . 'run cannot tell a dbname= that is ignored from a database= that is '
     . 'honoured', 3
    if $default_db eq $dbname;

  no warnings 'redefine';
  local *DBIO::Sybase::Storage::_connect_params_dsn
    = DBIO::Storage::DBI->can('_connect_params_dsn');

  my $storage = T::K59::Component->connect(
    broker(host => $host, port => $port, dbname => $dbname)
  )->storage;

  dsn_is $storage->_dbi_connect_info->[0],
    "dbi:Sybase:dbname=$dbname;host=$host;port=$port",
    "core's default form in the seam's place names the database with dbname=";

  my $dbh;
  lives_ok { $dbh = $storage->dbh }
    '... and the server accepts that DSN as well: no error, no warning'
    or skip 'no connection to look at', 1;

  is db_of($dbh), $default_db,
    "... but the session is in $default_db, the login's default database, "
  . "and not in $dbname: DBD::Sybase does not read dbname=. Everything the "
  . 'application does next happens in the wrong database';

  $storage->disconnect;
}

# ================================================== 5. the ASE writer storage
#
# DBIO::Sybase::Storage::ASE::_init gives the storage a second one for the
# inserts that have to read a value back: outside a transaction, an insert
# into a table with an IDENTITY column runs there, inside a transaction of its
# own, followed by SELECT MAX(id). That storage is handed the first one's
# connect info -- the broker, not a DSN -- and builds its DSN itself.
#
# This is an IDENTITY insert, not a blob insert. See the head of this file.

SKIP: {
  fresh_item_table();

  my $schema  = T::K59::ASE->connect(
    broker(host => $host, port => $port, dbname => $dbname)
  );
  my $storage = $schema->storage;

  # _init, and with it the writer storage, runs at the first connect.
  $storage->ensure_connected;

  my $writer = $storage->_writer_storage;

  ok $writer && !defined $writer->_dbh,
    'ase: the connect left a writer storage, itself not connected yet'
    or skip 'no unconnected writer storage to watch', 10;

  # What each of the two storages sends, as its own trace gives it.
  my (@on_main, @on_writer);
  $storage->debugcb(sub { push @on_main, $_[1] });
  $writer->debugcb(sub { push @on_writer, $_[1] });
  $storage->debug(1);   # goes to the writer storage as well

  my $row;
  my $inserted = lives_ok {
    $row = $schema->resultset('Item')->create({ name => 'through the writer' });
  } 'ase: a row with an IDENTITY key is inserted through the broker';

  $storage->debug(0);
  $_->debugcb(undef) for $storage, $writer;

  skip 'the insert failed', 9 unless $inserted;

  my $writer_dbh = $writer->_dbh;

  ok defined $writer_dbh, 'ase: the insert connected the writer storage'
    or skip 'the writer storage did not connect', 8;

  is_deeply
    [ map { scalar grep { /\AINSERT INTO .*k59_live_item/ } @$_ }
        \@on_writer, \@on_main ],
    [ 1, 0 ],
    'ase: the INSERT was sent by the writer storage, and not by the main one';

  ok 0 == index($writer->_dbi_connect_info->[0], $BUILT),
    'ase: the writer storage built its DSN from the same broker, through the '
  . 'seam'
    or diag 'the DSN is ' . masked($writer->_dbi_connect_info->[0]);

  is db_of($writer_dbh), $dbname,
    'ase: the writer storage\'s session is in the database named';

  isnt spid_of($writer_dbh), spid_of($storage->dbh),
    'ase: ... and it is a second session, not the first one again';

  is $row->id, 1,
    'ase: create() returns the IDENTITY value read back over there';

  is_deeply server_rows('select id, name from k59_live_item'),
    [ [ 1, 'through the writer' ] ],
    'ase: ... and another session sees that row, committed, in the database '
  . 'named';

  # ---- the card's "blob insert": a TEXT value, written by the writer storage
  SKIP: {
    skip 'a TEXT/IMAGE write does not work under FreeTDS: on 2026-10-05 it '
       . 'threw "TEXT/IMAGE operation failed, probably because you are using '
       . 'FreeTDS" on this path and without a broker alike, the row rolled '
       . 'back', 2
      if $FREETDS;

    # NEVER RUN: no DBD::Sybase built against Open Client was at hand.
    admin()->do(
      'create table k59_live_blob (id int identity primary key, body text null)'
    );

    lives_ok {
      $schema->resultset('Blob')->create({ body => 'x' x 5000 });
    } 'ase: a row with a TEXT value is inserted through the broker';

    is server_value('select datalength(body) from k59_live_blob'), 5000,
      'ase: ... and the value arrives whole, in the database named';
  }

  $storage->disconnect;
}

# ================================================ 6. the server by its name
#
# { dbname } builds dbi:Sybase:database=.., and which server that reaches is
# the client library's to say: $DSQUERY, resolved against freetds.conf. Both
# variables are read at every connect, so setting them here, with other
# connections of this process open, is enough.
#
# The same setup shows what the seam's two refusals are for. DBD::Sybase sets
# the server's address only when it has host AND port; a lone one it drops,
# and the connection goes to the server $DSQUERY names -- which here is the
# test server, so the connect SUCCEEDS with a host that does not exist.
#
# And it shows what the host=..;port=.. form cannot do under FreeTDS: a second
# statement while one is still being read. DBD::Sybase opens a connection of
# its own for it and looks its server up by name. That form names none: the
# client library answers "Server name not found in configuration files", and
# the prepare of the second statement dies of that message; on the
# dbname-alone form it runs. (The second connection itself is made, by host
# and port -- a $dbh->do goes through on it. What that does to BEGIN TRAN,
# COMMIT and ROLLBACK is karr k65, t/64-txn-scope-guard-live.t.)

SKIP: {
  skip 'The server name is given through a temporary freetds.conf, which '
     . 'only FreeTDS reads; with Open Client it would have to be in the '
     . 'interfaces file', 16
    unless $FREETDS;

  my $named = 'k59_live_named';

  # tds version: ASE speaks TDS 5.0 ($TDSVER, where set, goes first anyway).
  my $conf = File::Temp->new(SUFFIX => '.conf');
  print {$conf} "[$named]\n\thost = $host\n\tport = $port\n"
              . "\ttds version = 5.0\n";
  close $conf or die "Cannot write the temporary freetds.conf: $!";

  local $ENV{FREETDSCONF} = "$conf";

  {
    local $ENV{DSQUERY} = 'k59_live_no_such_server';

    throws_ok {
      T::K59::Component->connect(broker(dbname => $dbname))->storage->dbh;
    } qr/Server name not found in configuration files/,
      'component: dbname alone, with $DSQUERY naming a server no '
    . 'configuration knows, does not connect -- the DSN carries no address, '
    . 'and nothing falls back to a host or a port of its own';
  }

  local $ENV{DSQUERY} = $named;

  fresh_item_table();
  admin()->do("insert into k59_live_item (name) values ('$_')") for qw(a b c);

  # ---- a second statement on the host=..;port=.. form: refused
  #
  # Even now, with $DSQUERY naming the very server: the lookup for the
  # connection opened for the second statement takes the server's name from
  # the DSN and from nowhere else.
  {
    my $schema = T::K59::ASE->connect(
      broker(host => $host, port => $port, dbname => $dbname)
    );
    my $rs     = $schema->resultset('Item');
    my $cursor = $rs->search({}, { order_by => 'id' });

    is $cursor->next->name, 'a',
      'ase, host and port: a cursor is open, one row fetched, more pending';

    throws_ok { $rs->find(2) }
      qr/Server name not found in configuration files/,
      'ase, host and port: a second statement while it is open is refused -- '
    . 'the DSN gives the connection opened for it no server name to find';

    is $cursor->next->name, 'b',
      'ase, host and port: the open cursor goes on where it was: the refusal '
    . 'did not cost the connection';

    $cursor->reset;

    is $rs->find(2)->name, 'b',
      'ase, host and port: ... and with the cursor closed the same statement '
    . 'runs';

    $schema->storage->disconnect;
  }

  for my $way (qw(component ase)) {
    my $schema  = $SCHEMA{$way}->connect(broker(dbname => $dbname));
    my $storage = $schema->storage;

    dsn_is $storage->_dbi_connect_info->[0], "dbi:Sybase:database=$dbname",
      "$way, named server: dbname alone is a DSN with a database and no "
    . 'server';

    is db_of($storage->dbh), $dbname,
      "$way, named server: it connects once \$DSQUERY names a server "
    . 'freetds.conf knows, and into the database= it carries';

    if ($way eq 'ase') {
      my $rs     = $schema->resultset('Item');
      my $cursor = $rs->search({}, { order_by => 'id' });

      is $cursor->next->name, 'a',
        'ase, named server: a cursor is open, one row fetched';

      lives_and { is $rs->find(2)->name, 'b' }
        'ase, named server: a second statement while it is open runs -- its '
      . 'connection finds the server by name. This is what the '
      . 'host=..;port=.. form cannot do';

      is $cursor->next->name, 'b',
        'ase, named server: ... and the first cursor is undisturbed';

      $cursor->reset;
    }

    $storage->disconnect;
  }

  # ---- what the seam refuses to build, connected with all the same
  #
  # Plain DBI: the seam throws for these, so no storage gets this far.
  for my $lone (
    [ host => 'host=k59-live-no-such-host.invalid' ],
    [ port => 'port=1' ],
  ) {
    my ($part, $pair) = @$lone;

    my $dbh;
    lives_ok {
      $dbh = DBI->connect("dbi:Sybase:$pair;database=$dbname", $user, $pass, {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
      });
    } "a DSN with a lone $part ($pair) connects -- to a $part that is not "
    . 'the server\'s'
      or skip "no connection for the lone $part", 1;

    is db_of($dbh), $dbname,
      "... DBD::Sybase dropped the $part and went to the server \$DSQUERY "
    . "names: a $part alone never says where the connection goes, which is "
    . 'why the seam refuses it';

    $dbh->disconnect;
  }
}

# ================================================================ the end

drop_tables();

is_deeply
  server_rows(q{select name from sysobjects where name like 'k59[_]live%'}),
  [],
  'nothing of this test is left in the database';

done_testing;

# The tables again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { drop_tables(); 1 }
      or diag "Could not drop the k59_live_* tables: $@";
  }
}
