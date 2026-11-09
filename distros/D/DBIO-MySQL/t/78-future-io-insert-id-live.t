use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE half of karr k69 (karr k71, point 1): on the future_io transport an
# insert_async resolves with the id of ITS OWN statement, or with none --
# against real servers, with inserts that really overlap.
#
# WHY IT MATTERS. MySQL has no RETURNING on this path: the key of a freshly
# inserted row is the insertid its statement reported, folded into the
# returned-columns hashref, which becomes the Row, whose key is the WHERE of
# every update_async and delete_async after it. An insert that is handed
# another statement's id does not fail; it yields a Row that names somebody
# else's row. t/70 pins the logic offline over a fake DBD whose server reports
# what the test tells it to. What only a server can show:
#
#   - what the DBDs report for which statement: 0 for a table with no
#     AUTO_INCREMENT column (the premise of the k69 fix), and what for a key
#     the caller supplied on an AUTO_INCREMENT column;
#   - that the id still reaches the right insert when statements overlap on
#     several connections and their results arrive in another order than they
#     were sent. The id travels through the storage object, not through
#     arguments (POD of _insert_returned_columns), which holds only as long as
#     nothing is collected between a statement's result and its hashref.
#
# What this file claims, on a pool of two:
#   a. after an insert that generated an id, an insert into a table with no
#      AUTO_INCREMENT column resolves with the data it was given and nothing
#      else: the DBD reported 0 for it, a key it did not supply stays out, a
#      key it did supply on a column flagged is_auto_increment is kept -- as
#      a hashref and as a Row;
#   b. a key supplied on a real AUTO_INCREMENT column: the DBD reports that
#      key, and hashref and Row carry it -- above and below the counter;
#   c. six inserts started at once on the two connections -- four that
#      generate an id, two that do not -- overlap on the server and finish in
#      another order than they were sent, and each resolves with what its own
#      statement generated: read back by the id it resolved with, each row is
#      the one that insert wrote;
#   d. the same for the inserts of a txn_do_async, issued unchained, while
#      pooled inserts run beside it on the other connection.
#
# HOW THE OVERLAP IS MADE, AND SHOWN (karr k90: by locks, not by time). A
# BEFORE INSERT trigger waits for a named lock (GET_LOCK, then RELEASE_LOCK)
# whose name carries the gate the row says (artist: `rank`; liner_notes: the
# number before the colon in notes; 0 = no gate) and stamps the row with
# CONNECTION_ID(). A helper session holds the locks of all gates; the test
# waits until the server shows the statements parked on them (state 'User
# lock' in the processlist), and lets them through one gate at a time, in the
# order it wants them to finish. The wait comes before the server hands out the
# AUTO_INCREMENT value, so the insert sent first, whose gate opens last,
# finishes last and gets the highest id. Nothing here depends on how long
# anything takes: the order is the order of the releases. The test asserts
# exactly that -- finishing order against sending order, two sessions parked at
# once, the highest id on the insert sent first -- so a run in which nothing
# overlapped fails instead of passing for nothing.
#
# The tables are those of the shared test schema's Artist, LinerNotes and
# ArtistGUID sources, as t/70 uses them: artistid AUTO_INCREMENT; liner_id a
# key the database fills by itself (here the trigger), not flagged; artist_guid
# with a key the application supplies on a column flagged is_auto_increment.
#
# Runs through whichever DBD the DSN names. Gated like the other live tests:
# needs DBIO_TEST_MYSQL_DSN, _USER and _PASS. Creates and drops the tables
# artist, liner_notes and artist_guid.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use DBI;
use Future;
use DBIO::Test;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A schema always declares its driver (core ADR 0067), and DBIO::Test::Schema
# keeps none in its class: declare the storage class the DSN's DBD is
# registered for -- DBIO::MySQL::Storage::MariaDB for a dbi:MariaDB: DSN.
my $test_schema = DBIO::Test::Schema->clone;
$test_schema->storage_type(
  $dsn =~ /\Adbi:MariaDB:/i ? '+DBIO::MySQL::Storage::MariaDB' : '+DBIO::MySQL::Storage'
);

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

# Another session, for the fixture and for reading back what was written.
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
note sprintf 'server %s, DBD::%s %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION;

my @TABLES = qw( artist liner_notes artist_guid );
sub drop_tables {
  local $raw->{Warn} = 0;
  $raw->do("DROP TABLE IF EXISTS `$_`") for @TABLES;   # takes the triggers along
}

# Whatever happens below: the pool's sessions go first -- one left inside a
# transaction on a table would make its DROP wait for the metadata lock, for
# good -- then the tables.
my ($schema, $async, $helper);
END {
  if ($raw) {
    local ($@, $?);
    eval { $async->disconnect } if $async;
    eval { $helper->disconnect } if $helper;
    eval { drop_tables() };
  }
}

# A statement nobody answers would leave its Future pending for good.
local $SIG{ALRM} = sub { die "t/78 timed out: a Future never settled\n" };
alarm 120;

my $SEED = 4711;
drop_tables();
$raw->do(<<'SQL');
CREATE TABLE artist (
    artistid  INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY
  , name      VARCHAR(100)
  , `rank`    INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
)
SQL
$raw->do(<<'SQL');
CREATE TABLE liner_notes (
    liner_id INTEGER NOT NULL DEFAULT 0 PRIMARY KEY
  , notes    VARCHAR(100)
)
SQL
$raw->do(<<'SQL');
CREATE TABLE artist_guid (
    artistid  CHAR(36) NOT NULL PRIMARY KEY
  , name      VARCHAR(100)
  , `rank`    INTEGER NOT NULL DEFAULT 13
  , charfield CHAR(10)
  , a_guid    CHAR(36)
)
SQL
# Wait at the gate first, then let the server assign the id; stamp the
# session. A gate is a lock name unique to this run; a rank or notes prefix of
# 0 passes without waiting.
my $LOCK = sprintf 'dbio_k90_%d_%d_', $$, time;
sub gate_name { my ($kind, $n) = @_; return "$LOCK$kind$n" }
$raw->do(<<"SQL");
CREATE TRIGGER dbio_k71_artist_bi BEFORE INSERT ON artist FOR EACH ROW
  SET NEW.charfield = CONNECTION_ID() + 0 * IF(NEW.`rank` > 0,
    GET_LOCK(CONCAT('${LOCK}a', NEW.`rank`), 30) + RELEASE_LOCK(CONCAT('${LOCK}a', NEW.`rank`)), 0)
SQL
# liner_id is filled by the database, as the source expects of it: from the
# counter bits of UUID_SHORT(), which rise by one per call.
$raw->do(<<"SQL");
CREATE TRIGGER dbio_k71_liner_bi BEFORE INSERT ON liner_notes FOR EACH ROW
  SET NEW.liner_id = (UUID_SHORT() & 16777215) + 0 * IF(SUBSTRING_INDEX(NEW.notes, ':', 1) + 0 > 0,
    GET_LOCK(CONCAT('${LOCK}l', SUBSTRING_INDEX(NEW.notes, ':', 1) + 0), 30)
      + RELEASE_LOCK(CONCAT('${LOCK}l', SUBSTRING_INDEX(NEW.notes, ':', 1) + 0)), 0)
SQL
$raw->do('INSERT INTO artist (artistid, name, `rank`) VALUES (?, ?, 0)', undef, $SEED, 'k71 seed');

# What the DBD reported as the insertid of each statement the transport
# collected, as the transport read it. The wrapper only watches.
my @reported;
{
  my $insertid = \&DBIO::MySQL::Storage::Async::_async_insertid;
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_async_insertid = sub {
    my $id = $insertid->(@_);
    push @reported, [ $_[1]{sth}{Statement}, $id ];
    return $id;
  };
}
# The gates: a helper session of its own holds the lock of each gate until the
# test opens it. Closing the session (END, or the end of the run) frees them all.
$helper = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub close_gates {
  my (@gates) = @_;                       # [ kind, number ]
  for my $g (@gates) {
    $helper->selectrow_array('SELECT GET_LOCK(?, 0)', undef, gate_name(@$g))
      or die "gate @$g is held already\n";
  }
}
sub open_gate {
  my ($kind, $n) = @_;
  my ($released) = $helper->selectrow_array('SELECT RELEASE_LOCK(?)', undef, gate_name($kind, $n));
  die "gate $kind$n was not held\n" unless $released;
}
# How many sessions of the server are parked at a gate right now.
sub parked {
  return scalar $raw->selectrow_array(
    q{SELECT COUNT(*) FROM information_schema.processlist WHERE state = 'User lock' AND info LIKE 'INSERT INTO%'}
  );
}

# The insertid of the last statement on $table.
sub reported_for {
  my ($table) = @_;
  my ($last) = grep { $_->[0] =~ /\AINSERT INTO `?\Q$table\E`? / } reverse @reported;
  return $last ? $last->[1] : 'no such statement';
}

$schema = $test_schema->connect($dsn, $user, $pass, { async => 'future_io', pool_size => 2 });
$async  = $schema->storage->async;
my ($Artist, $Liner, $Guid) = map { $schema->source($_) } qw( Artist LinerNotes ArtistGUID );

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# The row an artist insert wrote, by the id it resolved with.
sub artist_named {
  my ($id) = @_;
  return undef unless defined $id;
  return scalar $raw->selectrow_array('SELECT name FROM artist WHERE artistid = ?', undef, $id);
}
sub liner_key { scalar $raw->selectrow_array('SELECT liner_id FROM liner_notes WHERE notes = ?', undef, $_[0]) }

my $GUID   = 'c9bf9e57-1685-4c89-bafb-ff5af830be8a';
my $A_GUID = '0f3c5e2a-6d52-4a54-9a61-5d0b1a7d8f11';

# ---------------------------------------------------------------------------
# a. One insert after the other: a statement that generates no id, right
#    after one that did.
# ---------------------------------------------------------------------------
{
  my $first = $async->insert_async($Artist, { name => 'a: generated', rank => 0 })->get;
  my $id    = $first->{artistid};
  ok defined $id && $id > $SEED, 'a: an insert into the AUTO_INCREMENT table resolves with a generated id';
  is artist_named($id), 'a: generated', '... the id of the row it wrote';
  is reported_for('artist'), $id, '... which is what the DBD reported for that statement';

  # Before k69 this hashref carried liner_id => the artist's id.
  is_deeply $async->insert_async($Liner, { notes => '0:a: no id' })->get, { notes => '0:a: no id' },
    'a: right after it, an insert into a table with no AUTO_INCREMENT column resolves with its own data only';
  is reported_for('liner_notes'), 0, '... the DBD reported 0 as its insertid';
  my $liner_id = liner_key('0:a: no id');
  ok defined $liner_id && $liner_id != $id, '... and the row is there, under a key the database chose';
  is $async->last_insert_id, $id, '... last_insert_id still names the last id a statement GENERATED';

  # Before k69 the previous insert's id was written over the supplied key.
  $async->insert_async($Artist, { name => 'a: generated again', rank => 0 })->get;
  # ArtistGUID also has a_guid, flagged auto_nextval: the synchronous insert
  # fetches it, the asynchronous one does not, and since core k331 it refuses
  # an insert that leaves it out instead of sending NULL. The refusal comes
  # first and sends nothing; the insert then supplies the value, as the
  # refusal says, and the property is checked on it.
  my $sent = @reported;
  my $refused = '';
  {
    local $@;
    eval { $async->insert_async($Guid, { artistid => $GUID, name => 'a: refused' })->get; 1 }
      or $refused = $@;
  }
  like "$refused", qr/cannot fill the auto_nextval column 'a_guid' of ArtistGUID/,
    'a: an insert leaving the auto_nextval column a_guid out is refused, naming it';
  is scalar(@reported), $sent, '... and sends no statement';
  is $raw->selectrow_array('SELECT COUNT(*) FROM artist_guid WHERE name = ?', undef, 'a: refused'), 0,
    '... no row was written';
  is_deeply $async->insert_async($Guid, { artistid => $GUID, name => 'a: supplied', a_guid => $A_GUID })->get,
    { artistid => $GUID, name => 'a: supplied', a_guid => $A_GUID },
    'a: a key supplied on a column flagged is_auto_increment is kept when the statement generated no id';
  is reported_for('artist_guid'), 0, '... the DBD reported 0 for that one too';

  # The same as Rows: what the next update_async or delete_async would name.
  my $artist = $schema->resultset('Artist')->create_async({ name => 'a: row', rank => 0 })->get;
  is artist_named($artist->artistid), 'a: row', 'a: create_async stores the generated id on the Row';
  my $liner = $schema->resultset('LinerNotes')->create_async({ notes => '0:a: row' })->get;
  is $liner->liner_id, undef, '... a Row whose insert generated no id carries no key -- not the artist\'s';
}

# ---------------------------------------------------------------------------
# b. A key the caller supplied on a real AUTO_INCREMENT column.
# ---------------------------------------------------------------------------
{
  my $above = $async->insert_async($Artist, { artistid => 9000, name => 'b: above the counter', rank => 0 })->get;
  note 'b: for a supplied key above the counter the DBD reports ' . reported_for('artist');
  is reported_for('artist'), 9000, 'b: for a key supplied on the AUTO_INCREMENT column the DBD reports that key';
  is $above->{artistid}, 9000, '... and the insert resolves with it';
  is $async->last_insert_id, 9000,
    '... last_insert_id names it too: the DBD does not tell a supplied key from a generated one';

  $async->insert_async($Artist, { name => 'b: generated in between', rank => 0 })->get;
  my $below = $async->insert_async($Artist, { artistid => 100, name => 'b: below the counter', rank => 0 })->get;
  note 'b: for a supplied key below the counter the DBD reports ' . reported_for('artist');
  is $below->{artistid}, 100, 'b: a supplied key below the counter is kept too, right after a generated one';
  is artist_named(100), 'b: below the counter', '... and names the row that was written';

  my $row = $schema->resultset('Artist')->create_async({ artistid => 9100, name => 'b: row', rank => 0 })->get;
  is $row->artistid, 9100, 'b: the Row of a create_async with a supplied key carries that key';
  is artist_named(9100), 'b: row', '... which is its row';
}

# ---------------------------------------------------------------------------
# c. Six inserts at once on two connections.
# ---------------------------------------------------------------------------

# Start the inserts of @plan together; returns what each resolved with, by
# label, and the labels in the order they finished.
#   [ label, source, \%data ]
sub together {
  my (@plan) = @_;
  my (%got, @finished, @futures);
  for my $insert (@plan) {
    my ($label, $source, $data) = @$insert;
    my $f = $async->insert_async($source, { %$data });
    $f->on_ready(sub {
      push @finished, $label;
      $got{$label} = $_[0]->is_done ? $_[0]->get : 'FAILED: ' . ($_[0]->failure // 'cancelled');
    });
    push @futures, $f;
  }
  return (\%got, \@finished, \@futures);
}

{
  my @plan = (
    [ c1 => $Artist, { name => 'c1: sent first, slowest', rank => 700 } ],
    [ c2 => $Artist, { name => 'c2', rank => 100 } ],
    [ c3 => $Liner,  { notes => '50:c3: no id' } ],
    [ c4 => $Artist, { name => 'c4', rank => 300 } ],
    [ c5 => $Guid,   { artistid => 'c5-supplied-key', name => 'c5: no id', a_guid => $A_GUID } ],
    [ c6 => $Artist, { name => 'c6', rank => 0 } ],
  );
  # Two statements parked at their gates, one on each connection: the one
  # sent first behind the longest, the one sent second behind the shortest.
  close_gates([ a => 700 ], [ a => 100 ], [ l => 50 ], [ a => 300 ]);
  my ($got, $finished, $futures) = together(@plan);
  ok wait_until(sub { parked() >= 2 }, 20), 'c: two inserts are in the server at once, waiting at their gates';
  # Open the gates of everything but c1; c1 stays where it is while the other
  # connection works off the rest of the queue.
  open_gate(a => 100); open_gate(l => 50); open_gate(a => 300);
  ok wait_until(sub { 5 == grep { $_ ne 'c1' } @$finished }, 20), '... the other five settle behind it';
  ok !$futures->[0]->is_ready, '... while c1 still waits at its gate';
  open_gate(a => 700);
  wait_until(sub { !grep { !$_->is_ready } @$futures }, 20);

  is scalar(@$finished), 6, 'c: six inserts started at once on a pool of two all settle';

  # That they overlapped, from what the server did.
  is $finished->[-1], 'c1', '... the one sent first finishes last'
    or diag "finished in the order @$finished";
  isnt "@$finished", 'c1 c2 c3 c4 c5 c6', '... so the results arrive in another order than the statements were sent';
  my %session = map { @$_ } @{ $raw->selectall_arrayref(
    'SELECT name, charfield FROM artist WHERE name LIKE ?', undef, 'c%',
  ) };
  # The pool retires a connection at the end of every borrow (core ADR 0079), so
  # six inserts are written by up to six sessions; that they ran on at least two
  # at once is what the gates above showed, and is asked of the rows here.
  cmp_ok scalar( keys %{ { map { $_ => 1 } values %session } } ), '>=', 2, '... written by at least two sessions';
  my @artists = grep { ref $got->{$_} eq 'HASH' && defined $got->{$_}{artistid} } qw( c1 c2 c4 c6 );
  is scalar(@artists), 4, '... each of the four artist inserts resolves with an id';
  is_deeply [ sort { $got->{$a}{artistid} <=> $got->{$b}{artistid} } @artists ], [qw( c2 c4 c6 c1 )],
    '... the server having handed them out in another order than the inserts were sent: the first got the last';

  # Each with its own.
  for my $insert (grep { $_->[1] == $Artist } @plan) {
    my ($label, undef, $data) = @$insert;
    my $id = ref $got->{$label} eq 'HASH' ? $got->{$label}{artistid} : undef;
    is artist_named($id), $data->{name}, "c: $label resolves with the id of the row IT wrote";
  }
  is_deeply $got->{c3}, { notes => '50:c3: no id' },
    'c: the insert without an id, finishing between two with one, takes none over';
  is_deeply $got->{c5}, { artistid => 'c5-supplied-key', name => 'c5: no id', a_guid => $A_GUID },
    'c: the insert with a supplied key, finishing between two with an id, keeps its key';
}

# ---------------------------------------------------------------------------
# d. The inserts of a transaction, issued unchained, beside pooled inserts on
#    the other connection.
# ---------------------------------------------------------------------------
{
  my (%got, @finished);
  my $take = sub {
    my ($label) = @_;
    return sub {
      push @finished, $label;
      $got{$label} = $_[0]->is_done ? $_[0]->get : 'FAILED: ' . ($_[0]->failure // 'cancelled');
    };
  };

  # The gates, in the order they open: p1, t1, p3, t3. The transaction's
  # statements and the pooled ones each run one after the other on their own
  # connection, so the first of each is parked first.
  close_gates([ a => 150 ], [ a => 300 ], [ a => 250 ], [ a => 600 ]);
  my $txn = $async->txn_do_async(sub {
    my ($t) = @_;
    my @inserts = (
      [ t1 => $Artist, { name => 't1: in the transaction', rank => 300 } ],
      [ t2 => $Liner,  { notes => '0:t2: no id' } ],
      [ t3 => $Artist, { name => 't3: in the transaction', rank => 600 } ],
      [ t4 => $Guid,   { artistid => 't4-supplied-key', name => 't4: no id', a_guid => $A_GUID } ],
    );
    return Future->needs_all(map {
      my ($label, $source, $data) = @$_;
      $t->insert_async($source, $data)->on_ready($take->($label));
    } @inserts);
  });
  # Pooled, on the other connection, finishing between the transaction's.
  my @pooled = map {
    my ($label, $source, $data) = @$_;
    $async->insert_async($source, $data)->on_ready($take->($label));
  } (
    [ p1 => $Artist, { name => 'p1: pooled', rank => 150 } ],
    [ p2 => $Liner,  { notes => '0:p2: no id' } ],
    [ p3 => $Artist, { name => 'p3: pooled', rank => 250 } ],
  );
  ok wait_until(sub { parked() >= 2 }, 20), 'd: two inserts, one of each connection, wait at their gates';
  for my $step ([ 150 => 'p2' ], [ 300 => 't2' ], [ 250 => 'p3' ], [ 600 => 't4' ]) {
    my ($gate, $until) = @$step;
    open_gate(a => $gate);
    wait_until(sub { grep { $_ eq $until } @finished }, 20);
  }
  ok wait_until(sub { $txn->is_ready && !grep { !$_->is_ready } @pooled }, 20),
    'd: a transaction of four unchained inserts and three pooled inserts beside it all settle';
  ok $txn->is_done, '... the transaction commits' or diag scalar $txn->failure;

  my %session = map { @$_ } @{ $raw->selectall_arrayref(
    'SELECT name, charfield FROM artist WHERE name LIKE ? OR name LIKE ?', undef, 't%', 'p%',
  ) };
  isnt $session{'t1: in the transaction'}, $session{'p1: pooled'},
    '... the pooled inserts on another session than the transaction\'s';
  my %at = map { $finished[$_] => $_ } 0 .. $#finished;
  ok defined $at{p1} && defined $at{t3} && $at{t1} < $at{p3} && $at{p1} < $at{t3},
    '... and their results interleaved with the transaction\'s'
    or diag "finished in the order @finished";

  for my $check (
    [ t1 => 't1: in the transaction' ], [ t3 => 't3: in the transaction' ],
    [ p1 => 'p1: pooled' ],             [ p3 => 'p3: pooled' ],
  ) {
    my ($label, $name) = @$check;
    my $id = ref $got{$label} eq 'HASH' ? $got{$label}{artistid} : undef;
    is artist_named($id), $name, "d: $label resolves with the id of the row IT wrote";
  }
  is_deeply $got{t2}, { notes => '0:t2: no id' }, 'd: the transaction\'s insert without an id takes none over';
  is_deeply $got{t4}, { artistid => 't4-supplied-key', name => 't4: no id', a_guid => $A_GUID },
    'd: the transaction\'s insert with a supplied key keeps it';
  is_deeply $got{p2}, { notes => '0:p2: no id' }, 'd: the pooled insert without an id takes none over';
}

is_deeply \@warnings, [], 'none of it warned';

alarm 0;
$async->disconnect;
undef $async;
drop_tables();
$raw->disconnect;
undef $raw;

done_testing;
