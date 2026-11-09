use strict;
use warnings;
use Test::More;

# OFFLINE test: what the future_io transport reports is the error's text, not
# where in this library it was raised (karr k120).
#
# WHY: the failure of a statement reaches the caller of a Future -- and from
# there a log, a bug report, an API answer. Under RaiseError DBI raises an error
# itself and blames its caller, and its caller is always this transport:
# "DBD::Pg::db pg_result failed: ERROR:  division by zero at
# .../DBIO/PostgreSQL/Storage/Async.pm line 946." The path says where DBIO is
# installed, the line changes with every release of this file, and neither
# says anything about the statement. The refusals of the transport itself
# named a file and a line the same way -- this library's, dbio-async's or
# Future's, by where the call happened to come from. Those are a refusal of
# what the caller asked for, and the place that matters for them is the
# caller's (maintainer's decision 2026-10-16).
#
# What this file claims:
#   1. a handle _pg_connect opens raises DBI's errors itself: the text DBI
#      made, the handle's err / errstr / state as DBI left them, no file and no
#      line -- for the database handle and for a statement handle of it;
#   2. a HandleError the caller gave among the connect attributes is asked
#      first, as before: one that answers true has taken the error, one that
#      answers false leaves it to be raised, one that dies is the error;
#   3. a connection that cannot be opened is reported the same way, where the
#      message is made and where it arrives -- the pool's Future, the listen
#      Future;
#   4. the transport's own refusals are DBIO::Exception objects that name the
#      caller's file and line -- reached by a direct call, through the pool,
#      or in a callback of the event loop -- and no file of a library;
#   5. who asks for a stack trace (Carp's verbose mode) gets one, for an error
#      of DBI's as for a refusal.
#
# WHAT RUNS FOR REAL: this dist's _pg_connect and its seams, DBI's own raising
# of an error, and for 3 DBD::Pg and libpq. No server is reached: 1, 2 and 5
# run on DBD::ExampleP, which ships with DBI and reads directories -- its
# errors are a driver's own, set and raised by DBI exactly as DBD::Pg's are;
# 3 goes to a unix socket directory that does not exist. What a statement
# against a server reports is held in t/105-future-io-error-text-live.t.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use DBD::Pg;
use Future::IO;

my $ASYNC = 'DBIO::PostgreSQL::Storage::Async';

my $DEAD = '/nonexistent/dbio-postgresql-k120';
plan skip_all => "$DEAD exists on this machine" if -e $DEAD;

# libpq reads its environment for what a connection string leaves out.
delete @ENV{ grep { /^PG/ } keys %ENV };

alarm 60;

# The claim itself: a plain string that is the error's text and a newline, and
# names no perl file and no line. With the newline at its end nothing that
# rethrows it by die adds a place of its own.
sub text_only {
  my ($err, $name) = @_;
  ok defined $err && !ref $err && length $err, "$name: a plain string"
    or diag 'got: ' . (defined $err ? ref $err || "'$err'" : 'undef');
  $err = '' unless defined $err && !ref $err;
  unlike $err, qr/ at \S+ line \d+/, '... that names no file and no line';
  unlike $err, qr/\.pm\b/,           '... and no module';
  like   $err, qr/[^\n]\n\z/,        '... and ends in one newline';
}

sub example_handle {
  my (%attrs) = @_;
  my $conn = $ASYNC->_pg_connect({ dsn => 'dbi:ExampleP:', attrs => \%attrs });
  return $conn->{dbh};
}

my $NOT_SQL    = 'this is no statement';
my $NO_SUCH    = '/nonexistent/dbio-postgresql-k120-dir';
my $SYNTAX     = qr/\ADBD::ExampleP::db prepare failed: Syntax error in select statement \("\Q$NOT_SQL\E"\)/;
my $OPENDIR    = qr/\ADBD::ExampleP::st execute failed: opendir\(\Q$NO_SUCH\E\): /;

# ---------------------------------------------------------------------------
# 0. Control: this is what DBI does when it raises the error itself, so the
#    claims below are about something.
# ---------------------------------------------------------------------------
{
  my $dbh = DBI->connect('dbi:ExampleP:', undef, undef, { RaiseError => 1, PrintError => 0 });
  my $sth = eval { $dbh->prepare($NOT_SQL) };
  like $@, $SYNTAX, 'control: a handle with RaiseError and nothing else fails in DBI\'s words';
  like $@, qr/ at \Q${\ __FILE__}\E line \d+\.\n\z/,
    'control: ... and DBI names the file and line that called it';
}

# ---------------------------------------------------------------------------
# 1. A handle _pg_connect opens raises DBI's errors itself.
# ---------------------------------------------------------------------------
{
  my $dbh = example_handle();

  my $sth = eval { $dbh->prepare($NOT_SQL) };
  my $err = $@;
  ok !$sth, 'a database handle method that fails dies';
  like $err, $SYNTAX, '... in DBI\'s words: the driver, the method, the driver\'s text';
  text_only($err, 'the database handle\'s error');
  ok $dbh->err, '... the handle still has its err';
  like $dbh->errstr, qr/\ASyntax error in select statement/, '... and its errstr';

  $sth = $dbh->prepare("select name from $NO_SUCH");
  my $rv = eval { $sth->execute };
  $err = $@;
  ok !$rv, 'a statement handle method that fails dies';
  like $err, $OPENDIR, '... in DBI\'s words';
  text_only($err, 'the statement handle\'s error');

  $dbh->disconnect;
}

# The SQLSTATE travels beside the text, on the handle. (A fresh handle:
# set_err appends to an error the handle still holds.)
{
  my $dbh = example_handle();
  eval { $dbh->set_err(7, 'ERROR:  division by zero', '22012') };
  my $err = $@;
  like $err, qr/\ADBD::ExampleP::db set_err failed: ERROR:  division by zero\n\z/,
    'an error with a SQLSTATE: the text is the driver\'s';
  text_only($err, 'its error');
  is $dbh->state, '22012', '... and the SQLSTATE is on the handle';
  is $dbh->err, 7, '... beside the err';
  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 2. A HandleError of the caller is asked first.
# ---------------------------------------------------------------------------
{
  my @asked;
  my $dbh = example_handle(HandleError => sub { push @asked, [@_]; 1 });
  my $sth = eval { $dbh->prepare($NOT_SQL); };
  is $@, '', 'a HandleError that answers true has taken the error: nothing dies';
  ok !$sth, '... and the method answers false';
  is scalar(@asked), 1, '... it was asked once';
  like $asked[0][0], $SYNTAX, '... with DBI\'s message';
  is $asked[0][1], $dbh, '... and the handle';
  $dbh->disconnect;
}
{
  my @asked;
  my $dbh = example_handle(HandleError => sub { push @asked, $_[0]; 0 });
  my $sth = eval { $dbh->prepare($NOT_SQL) };
  my $err = $@;
  is scalar(@asked), 1, 'a HandleError that answers false was asked';
  like $err, $SYNTAX, '... and the error is raised behind it';
  text_only($err, 'that error');
  $dbh->disconnect;
}
{
  my $dbh = example_handle(HandleError => sub { die { mine => $_[0] } });
  my $sth = eval { $dbh->prepare($NOT_SQL) };
  my $err = $@;
  is ref $err, 'HASH', 'a HandleError that dies: its exception is the error, as it threw it';
  like $err->{mine}, $SYNTAX, '... made of DBI\'s message';
  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A connection that cannot be opened.
# ---------------------------------------------------------------------------
my $SOCKET_TRIED = qr{\Q$DEAD\E/\.s\.PGSQL\.\d+};
{
  my %conninfo = (dsn => "dbi:Pg:host=$DEAD;dbname=appdb", user => 'app', password => 'pw');

  my $conn = eval { $ASYNC->_pg_connect({ %conninfo }) };
  my $err  = $@;
  if ($conn) {
    $conn->{dbh}->disconnect;
    BAIL_OUT('a connection was opened -- this file must never reach a server');
  }
  like $err, qr/\ADBI connect\('host=\Q$DEAD\E;dbname=appdb','app',\.\.\.\) failed: /,
    'a connect DBI fails: DBI\'s message';
  like $err, $SOCKET_TRIED, '... with libpq\'s reason';
  text_only($err, 'the connect error');

  $conn = eval { $ASYNC->_pg_connect({ %conninfo, attrs => { HandleError => sub { 1 } } }) };
  $err  = $@;
  ok !$conn, 'a connect whose error a HandleError of the caller took: it fails all the same';
  like $err, qr/\ADBD::Pg connect failed: /, '... in the transport\'s words';
  like $err, $SOCKET_TRIED, '... with libpq\'s reason';
  text_only($err, 'that connect error');
}

SKIP: {
  skip "Future::IO is bound to $Future::IO::IMPL; this part drives the built-in implementation", 12
    if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

  my $s = $ASYNC->new(undef);
  $s->connect_info([ "dbi:Pg:host=$DEAD;dbname=appdb", 'app', 'pw', { pool_size => 1 } ]);

  my $f = $s->pool->acquire;
  ok $f->is_failed, 'acquiring a pool connection that cannot be opened fails';
  my ($pool_error) = $f->is_failed ? $f->failure : ();
  like $pool_error, qr/\ADBI connect\(/, '... with DBI\'s message';
  like $pool_error, $SOCKET_TRIED, '... and libpq\'s reason';
  text_only($pool_error, 'what the pool\'s Future fails with');

  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  $s->listen_backoff_initial(30);
  $s->listen_backoff_max(30);
  my $listen = $s->listen(jobs => sub { });
  ok $listen->is_failed, 'listen on a connection that cannot be opened fails';
  my ($listen_error) = $listen->is_failed ? $listen->failure : ();
  like $listen_error, qr/\Aopening the listen connection failed: DBI connect\(/,
    '... in core\'s words and DBI\'s';
  text_only($listen_error, 'what the listen Future fails with');
  $s->unlisten('jobs');
}

# ---------------------------------------------------------------------------
# 4. The transport's own refusals: a DBIO::Exception at the caller's place.
#
#    Until karr k120 they were croaked, and croak named whatever called into
#    this file -- the caller's script, DBIO/Async/Pool.pm or this library,
#    by the way the call came. Since a7cdff7 they were plain strings without a
#    place. Decided 2026-10-16: they are DBIO::Exception objects, as core
#    raises its own, naming the place in the caller's code the refusal was
#    reached from -- whether the call into the transport was the caller's own,
#    went through the pool, or ran in a callback of the event loop. What the
#    database or DBI says stays a string (sections 1 to 3).
#
#    The claims of text_only (a plain string, no file and no line) are
#    replaced for these: refused() asserts the object, the caller's file and
#    line, and still no library file and one newline at the end.
# ---------------------------------------------------------------------------

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# Without the object's own words around it -- core's origin "Some::sub(): "
# in front, " at FILE line N" behind -- the refusal says what it said.
sub refusal_text {
  my ($err) = @_;
  (my $text = "$err") =~ s/\A[\w:]+\(\): //;
  $text =~ s/ at \S+ line \d+\n\z/\n/;
  return $text;
}

# $err is a refusal raised at $line of this file. $object: whether it arrives
# as the exception itself (a statement's Future, a direct call) or inside the
# text of a failure core makes of it (listen).
sub refused {
  my ($err, $line, $name, %opt) = @_;
  if ($opt{wrapped}) {
    ok defined $err && !ref $err, "$name: core's failure text, around the refusal";
  }
  else {
    isa_ok $err, 'DBIO::Exception', "$name: the refusal";
  }
  my $text = defined $err ? "$err" : '';
  like $text, qr/ at \Q${\ __FILE__}\E line $line\n\z/,
    "... naming the caller's place: this file, line $line";
  unlike $text, qr/\.pm\b/, '... and no library file -- not this transport, not the pool, not Future';
  like $text, qr/[^\n]\n\z/, '... ending in one newline';
}

{
  my $s = $ASYNC->new(undef);

  # Reached by a call of the caller's own: the seam called directly.
  my @refusals = (
    [ 'conninfo that is no hashref with a dsn',
      __LINE__, sub { $ASYNC->_pg_connect({}) },
      qr/\APostgreSQL async conninfo must be a hashref with a dsn\n\z/ ],
    [ 'no AccessBroker attached',
      __LINE__, sub { $s->_async_broker_conninfo },
      qr/\A\Q$ASYNC\E has no AccessBroker attached to ask for connect info\n\z/ ],
    [ 'a broker answer of no shape it can connect from',
      __LINE__, sub { $s->_pg_broker_connect_info('just a string') },
      qr/\APostgreSQL future_io cannot connect from what the AccessBroker returned: a plain string\. / ],
    [ 'a broker answer with an empty dbname',
      __LINE__, sub { $s->_pg_broker_conninfo_hash({ dbname => '' }) },
      qr/\APostgreSQL future_io cannot connect from what the AccessBroker returned: its dbname is an empty dbname/ ],
    [ 'a parameter beside a dbname that is a whole DSN',
      __LINE__, sub { $s->_pg_broker_conninfo_hash({ dbname => 'dbi:Pg:dbname=appdb', host => 'db' }) },
      qr/\AConnection parameter\(s\) 'host' given beside a dbname that is a whole DSN/ ],
    [ 'a connection parameter that is a reference',
      __LINE__, sub { $s->_pg_broker_conninfo_hash({ dbname => 'appdb', host => [ 'db' ] }) },
      qr/its libpq connection parameter 'host' is a reference, not a value\n\z/ ],
    [ 'a connection parameter with a NUL character',
      __LINE__, sub { $s->_pg_broker_conninfo_hash({ dbname => "app\0db" }) },
      qr/its libpq connection parameter 'dbname' contains a NUL character/ ],
    [ 'LISTEN on a closed listen connection',
      __LINE__, sub { $s->_listen_subscribe({}, 'jobs') },
      qr/\ALISTEN: the listen connection is closed\n\z/ ],
    [ 'UNLISTEN on a closed listen connection',
      __LINE__, sub { $s->_listen_unsubscribe({}, 'jobs') },
      qr/\AUNLISTEN: the listen connection is closed\n\z/ ],
    [ 'a drain of a closed listen connection',
      __LINE__, sub { $s->_listen_drain({}) },
      qr/\Athe listen connection is closed\n\z/ ],
    [ 'a channel name the rule refuses',
      __LINE__, sub { $s->_listen_subscribe({}, 'x' x 64) },
      qr/\ALISTEN channel name 'x{64}' is 64 bytes long; .* at most 63 bytes .* pg_notify refuses it\n\z/ ],
    [ 'a statement that mixes $N and ?',
      __LINE__, sub { $s->_query_async(q{SELECT $1, ?}, [ 1 ]) },
      qr/\Arefusing to number placeholders: the statement mixes \$N and \?/ ],
    [ 'no statement',
      __LINE__, sub { $s->_query_async(undef, []) },
      qr/\Aa statement must be a defined, plain value\n\z/ ],
  );

  for my $case (@refusals) {
    my ($name, $line, $code, $says) = @$case;
    my $ok  = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "$name: refused";
    like refusal_text($err), $says, '... saying why, all of it';
    refused($err, $line, $name);
  }
}

SKIP: {
  skip "Future::IO is bound to $Future::IO::IMPL; this part drives the built-in implementation", 3 * 6 + 6 + 6
    if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

  # Reached through the pool: a statement's connection is spawned from what the
  # broker answers, through DBIO::Async::Pool and core's provider. The Future
  # of the statement fails with the refusal itself.
  for my $case (
    [ 'an empty dbname',             { dbname => '' },
      qr/its dbname is an empty dbname/ ],
    [ 'a parameter beside a DSN',    { dbname => 'dbi:Pg:dbname=appdb', host => 'db' },
      qr/'host' given beside a dbname that is a whole DSN/ ],
    [ 'a parameter that is a reference', { dbname => 'appdb', host => [ 'db' ] },
      qr/parameter 'host' is a reference/ ],
  ) {
    my ($what, $answer, $says) = @$case;
    my $s = $ASYNC->new(undef);
    $s->connect_info([ HashBroker->new($answer) ]);
    my $line = __LINE__; my $f = eval { $s->select_async('artist', ['*'], {}, {}) };
    ok $f && $f->is_failed, "a statement whose connection the broker answers with $what: its Future fails"
      or diag $@;
    my ($err) = $f && $f->is_failed ? $f->failure : ($@);
    like refusal_text($err), $says, '... with the refusal';
    refused($err, $line, "the pool's refusal of $what");
  }

  # Reached in a callback the event loop runs: the caller's code goes on in a
  # Future of its own, and the statement it issues there is refused.
  {
    my $s = $ASYNC->new(undef);
    $s->connect_info([ HashBroker->new({ dbname => '' }) ]);
    my $line;
    my $f = Future::IO->sleep(0)->then(sub {
      $line = __LINE__; $s->select_async('artist', ['*'], {}, {});
    });
    my $ok  = eval { $f->get; 1 };
    my $err = $@;
    ok !$ok, 'a statement issued in a callback of the loop, from what the broker cannot connect from: refused';
    like refusal_text($err), qr/its dbname is an empty dbname/, '... with the refusal';
    refused($err, $line, 'the refusal reached from a callback of the loop');
  }

  # Reached in callbacks of the transport's own: listen() opens the listen
  # connection and subscribes in callbacks core chains onto Futures, run by
  # Future's code. Core fails the listen Future with its own words around the
  # refusal; the place inside them is the caller's call of listen(), not the
  # frame of Future's that ran the callback (Future/PP.pm, before Future's
  # frames were skipped).
  {
    my $s = $ASYNC->new(undef);
    $s->connect_info([ 'dbi:ExampleP:', undef, undef ]);
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my $line = __LINE__; my $listen = $s->listen(('x' x 64) => sub { });
    Future::IO->sleep(0.05)->get unless $listen->is_ready;
    ok $listen->is_failed, 'listen on a channel name the rule refuses fails, from a callback';
    my ($err) = $listen->is_failed ? $listen->failure : ();
    like $err, qr/\ALISTEN on channel 'x{64}' failed: \S+ LISTEN channel name 'x{64}' is 64 bytes long; /,
      '... in core\'s words around the refusal';
    refused($err, $line, 'the refusal reached in a callback of the transport', wrapped => 1);
    $s->unlisten('x' x 64);
    $s->disconnect;
  }
}

# The frames between the caller and a callback of DBIO's own that a loop
# runs: Future's, and IO::Async's when it is the loop. The callback below is
# compiled in a DBIO package, as core's and dbio-async's are; the first frame
# that is the caller's is the line here that runs it.
{
  package DBIO::Test::K120Callback;
  sub refusing { my $s = shift; sub { $s->_listen_drain({}) } }
}
{
  my $s  = $ASYNC->new(undef);
  my $cb = DBIO::Test::K120Callback::refusing($s);

  my $line = __LINE__; my $f = Future->done->then($cb);
  my ($err) = $f->is_failed ? $f->failure : ();
  refused($err, $line, 'a refusal in a callback of DBIO\'s that Future runs');

  SKIP: {
    skip 'IO::Async not installed (recommends only)', 4
      unless eval { require IO::Async::Loop; 1 };
    my $loop = IO::Async::Loop->new;
    $loop->later($cb);
    $line = __LINE__; my $ran = eval { $loop->loop_once(0); 1 };
    refused($ran ? undef : $@, $line, 'a refusal in a callback IO::Async\'s loop runs');
  }
}

# ---------------------------------------------------------------------------
# 5. Who asks Carp for a stack trace still gets one.
# ---------------------------------------------------------------------------
#
#    The transport's refusals were Carp's and always honoured its verbose mode,
#    and so did DBI's message for a failed connect (t/87 holds what that trace
#    must not show). An error DBI raised on an open handle never did: DBI
#    raises those from C, past Carp. Both places that raise them ask Carp now:
#    DBI's errors one, the refusals -- DBIO::Exception objects, with or without
#    the trace -- the other (t/131 holds that no password shows in either).
# ---------------------------------------------------------------------------
{
  my $dbh = example_handle();
  my $s   = $ASYNC->new(undef);
  my %asks = (
    'an error of DBI\'s'             => [ sub { $dbh->prepare($NOT_SQL) }, $SYNTAX ],
    'a refusal of the transport\'s'  => [ sub { $s->_listen_drain({}) }, qr/\Athe listen connection is closed/ ],
  );
  for my $what (sort keys %asks) {
    my ($code, $says) = @{ $asks{$what} };
    local $Carp::Verbose = 1;
    my $ok  = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "$what under Carp's verbose mode: it fails";
    isa_ok $err, 'DBIO::Exception', '... a refusal as it is without the trace:'
      if $what =~ /refusal/;
    like $err, $says, '... starting with its message';
    like $err, qr/\n\s+main::__ANON__\(\) called at \Q${\ __FILE__}\E line \d+/,
      '... followed by the stack trace that was asked for, down to the caller';
  }
  $dbh->disconnect;
}

done_testing;
