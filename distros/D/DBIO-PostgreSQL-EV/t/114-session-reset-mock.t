use strict;
use warnings;
use Test::More;

# OFFLINE test for the session reset of a pool connection (karr k99, core k398).
#
# CLAIM: every borrow of a pooled connection has a session of its own. When a
# borrow ends -- a statement, a transaction after COMMIT or ROLLBACK, a COPY --
# the pool resets the connection before anyone else gets it:
#   a. DISCARD ALL goes out as a bare statement (Simple Query, no binds) on
#      exactly that connection, once per borrow, never twice;
#   b. the connect actions (on_connect_do, ...) run again after it, in that
#      order;
#   c. the connection goes to the next borrower -- also one already queued for
#      it -- only after the reset is answered, never before;
#   d. a reset that fails (DISCARD ALL or a connect action) retires the
#      connection: it is closed, the caller that borrowed before is not told,
#      and the next borrower runs on a fresh connection with a session of its
#      own;
#   e. the failure text names the step and carries no statement text, bind or
#      connection parameter;
#   f. the reset is the pool's: the COPY's end and a transaction's end reach it
#      through release, and the transport has no reset path of its own.
#
# WHY it matters: SET ROLE, set_config(..., false), a temporary table, a
# prepared statement or a session advisory lock of one borrower is otherwise
# there for the next, which may be another request of the application. The
# order in c is the whole point: a connection handed out while its reset is
# still on the wire would run the next statement before DISCARD ALL.
#
# Without the fix a to f fail: nothing is sent on release, the queued caller
# gets the connection at once, and a failing reset is never asked.
#
# THE ONE SUBSTITUTION is EV::Pg: a stand-in that answers on EV timers, keeps
# every statement it was sent, can withhold answers, and fails a statement on
# request. Pool, storage and the pool's reset are real.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @OPENED;          # every handle made, in order (weak)
  our $HOLD_SQL;        # a statement matching this waits for t_release
  our %FAIL;            # sql => error message: that statement is answered with it
  our @ORDER;           # [ handle id, how, sql ] over all handles, in the order sent
  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      %args, id => ++$ID, up => 0, queue => [], wire => [], finished => 0,
    }, $class;
    push @OPENED, $self;
    Scalar::Util::weaken($OPENED[-1]);
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak && !$weak->{finished};
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{up} }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub result_meta   { { cmd_status => 'SELECT 1' } }
  sub error_fields  { undef }
  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->{up} = 0;
    my @queue = splice @{ $self->{queue} };
    for my $entry (@queue) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 };
    }
    return;
  }

  sub _send {
    my ($self, $how, $sql, $cb) = @_;
    die "not connected\n" unless $self->{up};
    push @{ $self->{wire} }, $sql;
    push @ORDER, [ $self->{id}, $how, $sql ];
    push @{ $self->{queue} }, { sql => $sql, cb => $cb };
    $self->_arm;
    return;
  }

  sub query        { my ($s, $sql, $cb) = @_;        $s->_send(query => $sql, $cb) }
  sub query_params { my ($s, $sql, $bind, $cb) = @_; $s->_send(query_params => $sql, $cb) }

  sub put_copy_data { 1 }
  sub put_copy_end  {
    my ($self) = @_;
    $self->{queue}[0]{ended} = 1;
    $self->_arm;
    return 1;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    return if $HOLD_SQL && $self->{queue}[0]{sql} =~ $HOLD_SQL;
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub t_release { $HOLD_SQL = undef; $_[0]->_arm; return }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;
    my @result;
    if (defined(my $error = $FAIL{ $head->{sql} })) {
      @result = (undef, $error);
    }
    elsif ($head->{sql} =~ /^COPY /) {
      if (!$head->{started}) { $head->{started} = 1; @result = ('COPY_IN') }
      elsif ($head->{ended})  { @result = ('2') }
      else                    { return }
    }
    elsif ($head->{sql} =~ /^SELECT/) { @result = ([ [ 1, 'one' ] ]) }
    else                              { @result = ('') }
    # The head leaves the queue before its callback runs, so that what the
    # callback sends (the reset after a statement) queues behind it. A COPY's
    # first firing stays at the head, as EV::Pg keeps it.
    shift @{ $self->{queue} } unless $head->{sql} =~ /^COPY / && $result[0] && $result[0] eq 'COPY_IN';
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# The owning sync storage as far as the pool asks it: the connect statements of
# every new connection and of every reset (the shape of core's
# _run_pool_connect_actions), and the context ownership check.
{
  package K99::Owner;
  our @ACTIONS;
  sub new { bless {}, shift }
  sub _run_pool_connect_actions {
    my ($self, $runner) = @_;
    $runner->($_, undef) for @ACTIONS;
    return $self;
  }
  sub _assert_async_context_owner { $_[1] }
}

sub storage_of {
  my ($size, @actions) = @_;
  @K99::Owner::ACTIONS = @actions;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => $size }, {} ]);
  # An owner only where there are connect actions: the transport asks nothing
  # else of it here.
  my $owner;
  if (@actions) {
    $owner = K99::Owner->new;
    $storage->_owner_storage($owner);
  }
  return ($storage, $owner);
}

sub wait_for {
  my ($f) = @_;
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub reset_state { @EV::Pg::OPENED = (); @EV::Pg::ORDER = (); %EV::Pg::FAIL = (); $EV::Pg::HOLD_SQL = undef; @warnings = () }
sub wire        { [ @{ $_[0]{wire} } ] }
sub handles     { grep { defined } @EV::Pg::OPENED }
sub select_one  { $_[0]->_query_async('SELECT ?::text', [ $_[1] ]) }

sub quiet {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar(@died), 0, "$label: no callback died out of EV::Pg" or diag @died;
  @warnings = ();
}

# --- a, f: a statement's end -------------------------------------------------------

{
  my $label = 'a statement';
  reset_state();
  my ($storage) = storage_of(1);
  my ($ok, @r) = wait_for(select_one($storage, 'a'));
  ok $ok, "$label: the statement completes" or diag $r[0];
  settle();

  my ($pg) = handles();
  is scalar(@{ wire($pg) }), 2, "$label: two statements went out on the one connection";
  is $pg->{wire}[1], 'DISCARD ALL', "$label: the second is DISCARD ALL";
  is_deeply [ map { $_->[1] } @EV::Pg::ORDER ], [ 'query_params', 'query' ],
    "$label: the statement with its binds, the reset bare (Simple Query, no binds)";
  is $storage->pool->available, 1, "$label: the connection is idle once the reset is answered";
  quiet($label);
  $storage->disconnect;
}

# --- b: the connect actions run after DISCARD ALL -----------------------------------

{
  my $label = 'connect actions';
  reset_state();
  my ($storage, $owner) = storage_of(1, q{SET search_path = k99}, q{SET application_name = 'k99'});
  my ($ok) = wait_for(select_one($storage, 'a'));
  settle();
  my ($pg) = handles();
  # the spawn replays the actions first; the borrow's statement; then the reset
  is_deeply [ map { s/^SELECT.*/SELECT/r } @{ wire($pg) } ],
    [ q{SET search_path = k99}, q{SET application_name = 'k99'}, 'SELECT',
      'DISCARD ALL', q{SET search_path = k99}, q{SET application_name = 'k99'} ],
    "$label: at the end of the borrow DISCARD ALL, then the connect actions again, in order";
  is $storage->pool->available, 1, "$label: and the connection is idle after them";

  ($ok) = wait_for(select_one($storage, 'b'));
  settle();
  is scalar(grep { $_ eq 'DISCARD ALL' } @{ wire($pg) }), 2, "$label: a second borrow, a second reset, not two";
  quiet($label);
  $storage->disconnect;
}

# --- c: the connection goes on only after the reset's answer ------------------------

{
  my $label = 'queued caller';
  reset_state();
  my ($storage) = storage_of(1);
  my ($ok) = wait_for(select_one($storage, 'warm'));
  settle();
  my ($pg) = handles();
  @{ $pg->{wire} } = ();
  @EV::Pg::ORDER = ();

  # The reset's answer is withheld. The second statement is queued for the
  # pool's one connection while the first runs.
  $EV::Pg::HOLD_SQL = qr/^DISCARD ALL\z/;
  my $first  = select_one($storage, 'first');
  my $second = select_one($storage, 'second');
  ok !$second->is_ready, "$label: the second is queued for the connection";
  wait_for($first);
  settle();   # the reset has gone out; its answer has not come

  is $pg->{wire}[-1], 'DISCARD ALL', "$label: DISCARD ALL is on the wire";
  is scalar(@{ wire($pg) }), 2, "$label: the second statement is not: the connection is not handed on";
  ok !$second->is_ready, "$label: the queued caller still waits";
  is $storage->pool->available, 0, "$label: and the connection is not idle";

  # DISCARD ALL is answered: now the queued caller gets the connection.
  $pg->t_release;
  my ($ok2) = wait_for($second);
  ok $ok2, "$label: the queued caller gets the connection once the reset is answered";
  settle();
  my @order = map { $_->[2] eq 'DISCARD ALL' ? 'reset' : 'statement' } @EV::Pg::ORDER;
  is_deeply \@order, [qw( statement reset statement reset )],
    "$label: each borrow's statement, then its reset; the second statement came after the first one's reset";
  quiet($label);
  $storage->disconnect;
}

# --- d, e: a failing reset retires the connection -----------------------------------

for my $case (
  [ 'DISCARD ALL fails', 'DISCARD ALL', [] ],
  [ 'a connect action fails on the replay', q{SET application_name = 'k99-secret'}, [ q{SET application_name = 'k99-secret'} ] ],
) {
  my ($label, $failing, $actions) = @$case;
  reset_state();
  my ($storage, $owner) = storage_of(1, @$actions);
  my ($ok, @r) = wait_for(select_one($storage, 'borrow'));
  ok $ok, "$label: the borrow itself is not told (its statement completes)" or diag $r[0];
  settle();   # the first borrow's own reset is answered
  # The spawn's own replay of the action succeeded; from now on it fails.
  $EV::Pg::FAIL{$failing} = "ERROR:  boom\n";
  my ($old) = handles();
  # The next borrow's end is the failing reset: its statement is fine.
  ($ok, @r) = wait_for(select_one($storage, 'borrow'));
  ok $ok, "$label: the statement that ends in the failing reset completes" or diag $r[0];
  settle();
  %EV::Pg::FAIL = ();

  ok $old->{finished}, "$label: the connection is closed (retired)";
  is $storage->pool->available, 0, "$label: and not idle";
  is scalar(grep { $_ == $old } @{ $storage->pool->{_connections} }), 0, "$label: the pool no longer holds it";

  ($ok, @r) = wait_for(select_one($storage, 'after'));
  ok $ok, "$label: the next borrower gets a connection" or diag $r[0];
  my @h = handles();
  isnt $h[-1], $old, "$label: a fresh one, with a session of its own";
  is scalar(grep { /^SELECT/ && /after/ } @{ wire($old) }), 0, "$label: nothing more went to the retired one";
  settle();
  quiet($label);
  $storage->disconnect;
}

# The failure text: names the step, no statement text, bind or parameter.
{
  my $label = 'failure text';
  reset_state();
  my ($storage, $owner) = storage_of(1, q{SET application_name = 'k99-secret'});
  my ($ok) = wait_for(select_one($storage, 'x'));
  settle();
  my ($pg) = handles();
  $EV::Pg::FAIL{q{SET application_name = 'k99-secret'}} = "ERROR:  boom\n";
  my $f = $storage->_reset_pool_connection($pg);
  my ($done, $error) = wait_for($f);
  ok !$done, "$label: a failing connect action fails the reset";
  like $error, qr/could not be reset/, "$label: the text says the reset failed";
  like $error, qr/connect actions/, "$label: and names the step";
  unlike $error, qr/k99-secret|application_name|SET /, "$label: without the statement text";
  %EV::Pg::FAIL = ();
  $storage->disconnect;
}

# --- f: COPY's end reaches the reset through release -------------------------------

{
  my $label = 'copy_in';
  reset_state();
  my ($storage) = storage_of(1);
  my ($ok, @r) = wait_for($storage->copy_in('thing', [qw( id name )], sub { $_[0]->([ 1, 'a' ]); $_[0]->([ 2, 'b' ]) }));
  ok $ok, "$label: the COPY completes" or diag $r[0];
  settle();
  my ($pg) = handles();
  my @discards = grep { $_ eq 'DISCARD ALL' } @{ wire($pg) };
  is scalar(@discards), 1, "$label: its end resets the connection, once";
  like $pg->{wire}[0], qr/^COPY /, "$label: the COPY went first";
  is $pg->{wire}[-1], 'DISCARD ALL', "$label: the reset is the last statement on the connection";
  is $storage->pool->available, 1, "$label: and the connection is idle after it";
  quiet($label);
  $storage->disconnect;
}

# --- f: a transaction's end ---------------------------------------------------------

{
  my $label = 'txn_do_async';
  reset_state();
  my ($storage) = storage_of(1);
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SELECT 1', []);
  }));
  ok $ok, "$label: the transaction commits" or diag $r[0];
  settle();
  my ($pg) = handles();
  my @sent = map { s/^SELECT.*/SELECT/r } @{ wire($pg) };
  is_deeply \@sent, [ 'BEGIN', 'SELECT', 'COMMIT', 'DISCARD ALL' ],
    "$label: DISCARD ALL after COMMIT, outside the transaction (it cannot run inside one), once";
  is $storage->pool->available, 1, "$label: the connection is idle after it";
  quiet($label);
  $storage->disconnect;
}

done_testing;
