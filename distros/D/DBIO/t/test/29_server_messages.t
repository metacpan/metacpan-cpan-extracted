use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;

# ADR 0040 section 7: the server-message seam. Sybase ASE emits
# showplan as SERVER MESSAGES -- the channel Transact-SQL print and dbcc output
# use -- which DBD::Sybase exposes only through the syb_err_handler callback on
# the CONNECTION, never on the statement handle. Nothing reaches
# $sth->fetchall_arrayref, so _explain_query's row-shaped return had no outlet
# for ASE at all.
#
# The seam: _execute_sth wraps the execute verb of _dbh_execute so a driver can
# collect the messages a statement produced during its execution, and core
# stores them where the driver reads them back (_server_messages). The driver
# installs its handler on the handle the statement actually runs on -- the one
# _dbh_execute received, which on a replicated storage is the read handler's
# handle -- never on $self->dbh, so tracing/redact_bind_value (ADR 0025),
# dbh_do retry and the read handler all survive.
#
# This file is about the SEAM. The driver-shaped ASE _explain_query (five
# statements, messages wrapped as rows) is pinned in t/helpers/explain.t
# section 8.
#
# Everything here runs against stub handles -- no database, per house rules.
# The stubs count what was called on them and fire the message handler the
# storage installed, which is the whole point: the channel is the connection,
# and the seam is what makes it per-statement.

# ---- counting stub handles ------------------------------------------------
#
# The sth carries a reference to the dbh that prepared it, and its execute
# fires the message handler the storage installed on that dbh -- the way
# DBD::Sybase's syb_err_handler fires for showplan output. The message depends
# on the statement, so the per-statement claim is observable.

{
  package My::Counting::Sth;
  sub new   { bless { bound => [], executed => 0, finished => 0, dbh => undef, sql => undef, die_on_execute => 0 }, shift }
  sub bind_param       { my $s = shift; push @{$s->{bound}}, [ @_ ]; 1 }
  sub bind_param_inout { my $s = shift; push @{$s->{bound}}, [ @_ ]; 1 }
  sub execute {
    my $s = shift;
    if ($s->{die_on_execute}) {
      # DBD::Sybase's syb_err_handler fires for the error message, then
      # RaiseError raises -- the normal error path under DBIO, not an edge
      # case. ADR 0040 section 7: the handler-restore must hold
      # on this path too, which is what section 7 below proves.
      if (my $h = $s->{dbh}{syb_err_handler}) {
        my $msg = $s->{sql} =~ /^SELECT/ ? 'PLAN: scan artist' : 'SET: showplan on';
        $h->($s->{dbh}, 0, 0, $msg, undef, 0, 0, 'server');
      }
      die "execute failed (RaiseError=1)\n";
    }
    $s->{executed}++;
    # simulate the engine answering on the connection: fire the handler the
    # storage installed on the handle, exactly where DBD::Sybase's
    # syb_err_handler fires
    if (my $h = $s->{dbh}{syb_err_handler}) {
      my $msg = $s->{sql} =~ /^SELECT/ ? 'PLAN: scan artist' : 'SET: showplan on';
      $h->($s->{dbh}, 0, 0, $msg, undef, 0, 0, 'server');
    }
    '0E0';
  }
  sub finish           { $_[0]{finished}++; 1 }
  sub errstr           { undef }
  sub err              { undef }

  package My::Counting::Dbh;
  sub new { bless { prepared => [], cached => 0, sths => [], die_once => 0, next_die_on_execute => 0 }, shift }
  sub _make {
    my ($self, $sql) = @_;
    if ($self->{die_once}) {
      $self->{die_once} = 0;
      die "server has gone away\n";
    }
    push @{ $self->{prepared} }, $sql;
    my $sth = My::Counting::Sth->new;
    $sth->{dbh} = $self;
    $sth->{sql} = $sql;
    $sth->{die_on_execute} = delete $self->{next_die_on_execute} ? 1 : 0;
    push @{ $self->{sths} }, $sth;
    return $sth;
  }
  sub prepare        { my ($s, $sql) = @_; $s->_make($sql) }
  sub prepare_cached { my ($s, $sql) = @_; $s->{cached}++; $s->_make($sql) }
  sub quote          { my ($s, $v) = @_; defined $v ? "'$v'" : 'NULL' }
  sub errstr         { undef }

  package My::Counting::Storage;
  our @ISA = ('DBIO::Storage::DBI');
  use mro 'c3';
  sub _populate_dbh    { }
  sub _dbh             { $_[0]->{stub_dbh} }
  sub _get_dbh         { $_[0]->{stub_dbh} }
  sub connected        { $_[0]->{stub_connected} }
  sub _seems_connected { $_[0]->{stub_connected} }

  # The driver-shaped half: install a message handler on the handle the
  # statement runs on, execute, remove the handler, hand the messages back.
  # This is the shape a DBD::Sybase driver writes -- syb_err_handler on the
  # $dbh _dbh_execute gave it, never on $self->dbh. The restore is wrapped in
  # DBIO::Util::scope_guard so a dying $sth->execute (RaiseError=1 is normal,
  # not edge) still cleans the handler off the shared $dbh --
  # ADR 0040 section 7.
  package My::Collecting::Storage;
  our @ISA = ('My::Counting::Storage');
  use mro 'c3';
  use DBIO::Util qw(scope_guard);
  sub _execute_sth {
    my ($self, $dbh, $sth) = @_;
    my $messages = [];
    my $old = $dbh->{syb_err_handler};
    $dbh->{syb_err_handler} = sub { push @$messages, $_[3]; 0 };
    my $guard = scope_guard { $dbh->{syb_err_handler} = $old };
    my $rv = $sth->execute;
    return ($rv, $messages);
  }
}
$INC{'My/Counting/Storage.pm'}    = __FILE__;
$INC{'My/Collecting/Storage.pm'} = __FILE__;

sub build_storage {
  my $class   = shift || 'My::Counting::Storage';
  my $storage = $class->new;
  $storage->{stub_dbh}       = My::Counting::Dbh->new;
  $storage->{stub_connected} = 1;
  $storage->{_driver_determined} = 1;
  return $storage;
}

my $BIND = [ [ { dbic_colname => 'password' }, 'hunter2' ] ];
my $SQL  = 'SELECT plan FROM t WHERE secret = ?';

# --- 1. THE POINT: the base executes, collects nothing ---------------------
#
# The base _execute_sth is the bare execute; _server_messages is undef -- the
# "this engine does not collect" answer. The seam must not change what a
# storage that does not use it sees.

{
  my $storage = build_storage();

  my (undef, $sth) = $storage->_execute_rendered($SQL, $BIND);

  is $sth->{executed}, 1,
    'the base _execute_sth executes the statement it was handed';
  is $storage->_server_messages, undef,
    '... and collects no messages: _server_messages is undef on the base';
}

# --- 2. a driver-shaped _execute_sth collects the messages -----------------
#
# The driver installs its handler on the handle the statement runs on, the
# execute fires it, and the collected messages are readable back through
# _server_messages -- the driver never touched $self->dbh.

{
  my $storage = build_storage('My::Collecting::Storage');

  my (undef, $sth) = $storage->_execute_rendered($SQL, $BIND);

  is $sth->{executed}, 1,
    'the driver-shaped _execute_sth executes the statement';
  is_deeply $storage->_server_messages, [ 'PLAN: scan artist' ],
    'the messages the handler collected are readable via _server_messages';
  is $storage->{stub_dbh}{syb_err_handler}, undef,
    'the handler was removed after the execute -- not left on the handle';
}

# --- 3. the messages are per-statement -------------------------------------
#
# Each execute overwrites _server_messages with that statement's own messages.
# The ASE driver reads the messages right after the statement that produced
# them; a stale value from an earlier statement would be a silent wrong plan.

{
  my $storage = build_storage('My::Collecting::Storage');

  $storage->_execute_rendered('set showplan on', []);
  is_deeply $storage->_server_messages, [ 'SET: showplan on' ],
    'the set statement produced its own message';

  $storage->_execute_rendered($SQL, $BIND);
  is_deeply $storage->_server_messages, [ 'PLAN: scan artist' ],
    'the query statement overwrote it -- messages are per-statement, not cumulative';
}

# --- 4. dbh_do retry re-installs the collector on the fresh handle ---------
#
# The named defect of installing syb_err_handler on $self->dbh was that it
# does not survive dbh_do's reconnect retry -- the handler hangs on the dead
# handle. Here the handler is installed inside _execute_sth, which _dbh_execute
# re-runs on every retry, so the retried statement collects on the handle it
# actually ran on.

{
  my $storage = build_storage('My::Collecting::Storage');
  $storage->{stub_dbh}{die_once} = 1;
  $storage->{stub_connected}     = 0;   # what makes the retry_handler fire

  my (undef, $sth) = $storage->_execute_rendered($SQL, $BIND);

  is $sth->{executed}, 1,
    'the retried statement executed on the fresh handle';
  is_deeply $storage->_server_messages, [ 'PLAN: scan artist' ],
    '... and its messages were collected -- the handler rode the retry';
}

# --- 5. tracing survives, and with it redact_bind_value (ADR 0025) ---------
#
# The seam keeps the execute inside _query_start / _query_end, so the trace
# and the redactor still see the statement -- the guarantee the whole routing
# rule exists to preserve.

{
  my $storage = build_storage('My::Collecting::Storage');

  $storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'password' ? '[redacted]' : $value;
  });

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $storage->_execute_rendered($SQL, $BIND);
  $storage->debug(0);
  $storage->debugcb(undef);

  ok scalar(grep { /^\Q$SQL\E/ } @traced),
    'the statement reaches the trace sink';
  ok scalar(grep { /\[redacted\]/ } @traced),
    '... with redact_bind_value applied to its binds (ADR 0025)';
  ok !scalar(grep { /hunter2/ } @traced),
    '... and the raw value never got there';
}

# --- 6. the fake storage answers the seam ----------------------------------
#
# Core's suite is mock-only, and so is every driver's offline suite: the seam
# has to be usable there or a driver cannot test its ASE _explain_query at all.
# The fake storage routes its execute through _execute_sth exactly like the
# real _dbh_execute does, so a driver-shaped override is exercised against it.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->reset_captured;
  my (undef, $sth) = $storage->_execute_rendered('SELECT 1 FROM "artist"', []);

  ok $sth, 'the fake storage answers _execute_rendered with a handle';
  is $storage->_server_messages, undef,
    'the base fake storage collects no messages';
}

# --- 7. dying execute still restores the handler --------------------------
#
# DBIO has RaiseError=1 globally, so $sth->execute dying is the normal
# error case, not an edge case. A _execute_sth that installs a handler on
# the shared $dbh and then calls $sth->execute MUST restore the prior
# handler even when execute dies -- otherwise the dead handler sticks to
# the $dbh and contaminates the next statement. DBIO::Util::scope_guard is
# the standard pattern; this section proves the pattern holds.

{
  my $storage = build_storage('My::Collecting::Storage');

  # arrange: the first prepare produces an sth whose execute dies
  $storage->{stub_dbh}{next_die_on_execute} = 1;

  eval { $storage->_execute_rendered($SQL, $BIND); };
  ok $@, 'a dying $sth->execute makes _execute_rendered throw (RaiseError=1)';

  is $storage->{stub_dbh}{syb_err_handler}, undef,
    'the dying _execute_sth still restored the prior handler -- scope_guard ran';

  # follow-up: a fresh execute on the same handle collects ONLY its own
  # messages, never the dead statement's -- the handler slot is clean.
  $storage->_execute_rendered($SQL, $BIND);
  is_deeply $storage->_server_messages, [ 'PLAN: scan artist' ],
    'the next statement on the same handle collects its own messages -- no contamination';
}

done_testing;
