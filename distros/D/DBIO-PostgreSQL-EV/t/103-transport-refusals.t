use strict;
use warnings;

use Test::More;

# OFFLINE test, karr k88 (maintainer's decision 2026-10-16, as dbio-postgresql
# karr k120 for the future_io transport): a refusal of the transport's own is
# a DBIO::Exception that names the caller's place.
#
# Until now the transport croaked them: a plain string whose place Carp chose
# by the way the call came -- the caller's script for a direct call, core's
# pool or Future's code for a refusal reached through the pool or in a
# callback the loop ran. What the database, libpq or EV::Pg says is not the
# transport's refusal and stays a string (t/89, t/98).
#
# What this file claims:
#   1. each refusal -- no AccessBroker attached, connect info or a broker's
#      answer the transport cannot connect from, a connection parameter beside
#      the broker, a listen connection that is closed or has no connect info,
#      a channel name the rule refuses, a statement the placeholder rule
#      refuses -- is a DBIO::Exception, says what it said before, and names the
#      file and line of the call and no file of a library;
#   2. reached through the pool, the statement's Future fails with it, and
#      the place is the call that issued the statement;
#   3. reached in a callback the EV loop runs, the place is the caller's line
#      in that callback; reached in a callback of the transport's own, it is
#      where the caller ran the loop -- not a frame of Future, of EV, of core;
#   4. under Carp's verbose mode it carries a stack trace, and the password of
#      the connect info it refused is not in it;
#   5. EV::Pg's own croaks at pipeline enter and exit are no refusal of the
#      transport's: they stay strings, the text and its newline without the
#      place of the library line that called EV::Pg (as t/89 holds for the
#      dispatch croaks).
#
# THE ONE SUBSTITUTION is EV::Pg itself, for the listen connection of 3: a
# fake whose connect the test completes.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @NEW;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { args => { %args }, connected => 0, queue => [] }, $class;
    push @NEW, $self;
    Scalar::Util::weaken($NEW[-1]);
    return $self;
  }
  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{args}{$h} = $_[0] if @_; $s->{args}{$h} };
  }
  sub is_connected  { $_[0]{connected} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub finish        { $_[0]{connected} = 0; return }
  sub query         { my ($s, $sql, $cb) = @_; push @{ $s->{queue} }, [ $sql, $cb ]; return }

  # EV::Pg croaks from XS: the place is the perl line that called it.
  our %CROAK;
  sub enter_pipeline { Carp::croak($CROAK{enter_pipeline}) if $CROAK{enter_pipeline}; return }
  sub exit_pipeline  { Carp::croak($CROAK{exit_pipeline})  if $CROAK{exit_pipeline};  return }

  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{args}{on_connect}->() if $s->{args}{on_connect};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::Future;

alarm 60;

my $EV_STORAGE = 'DBIO::PostgreSQL::EV::Storage';

{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# Without the object's own words around it -- core's origin "Some::sub(): " in
# front, " at FILE line N" behind -- the refusal says what it said.
sub refusal_text {
  my ($err) = @_;
  (my $text = defined $err ? "$err" : '') =~ s/\A[\w:]+\(\): //;
  $text =~ s/ at \S+ line \d+\n\z/\n/;
  return $text;
}

# $err is a refusal reached from line $line of this file. wrapped: it arrives
# inside the text of a failure core makes of it.
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
    "$name: ... naming the caller's place: this file, line $line";
  unlike $text, qr/\.pm\b/, "$name: ... and no library file";
  like $text, qr/[^\n]\n\z/, "$name: ... ending in one newline";
}

# ---------------------------------------------------------------------------
# 1. Reached by a call of the caller's own.
# ---------------------------------------------------------------------------
{
  my $s = $EV_STORAGE->new(undef);
  my $fake_down = bless { connected => 0 }, 'EV::Pg';

  my @refusals = (
    [ 'no AccessBroker attached',
      __LINE__, sub { $s->_async_broker_conninfo },
      qr/\APostgreSQL ev has no AccessBroker attached to ask for connect info\n\z/ ],
    [ 'connect info that makes a DBI handle',
      __LINE__, sub { $EV_STORAGE->new(undef)->connect_info([ sub { } ]) },
      qr/\APostgreSQL ev cannot connect from this connect info: a code reference that makes a DBI handle/ ],
    [ q{another driver's DSN},
      __LINE__, sub { $EV_STORAGE->new(undef)->connect_info([ 'dbi:mysql:dbname=app', 'u', 'p' ]) },
      qr/\APostgreSQL ev cannot connect from this connect info: a DBI-form arrayref whose DSN is not dbi:Pg:/ ],
    [ q{a broker's answer without a parameter},
      __LINE__, sub { $EV_STORAGE->new(undef)->connect_info([ AnswerBroker->new({ pool_size => 3 }) ]) },
      qr/\APostgreSQL ev cannot connect from what the AccessBroker returned: no libpq connection parameter with a value/ ],
    [ q{a broker's answer with a reference for a parameter},
      __LINE__, sub { $EV_STORAGE->new(undef)->connect_info([ AnswerBroker->new({ dbname => 'app', host => ['db'] }) ]) },
      qr/its libpq connection parameter 'host' is a reference, not a value/ ],
    [ 'a connection parameter beside the broker',
      __LINE__, sub { $EV_STORAGE->new(undef)->connect_info([ AnswerBroker->new({ dbname => 'app' }), { sslmode => 'require' } ]) },
      qr/\APostgreSQL ev does not apply connection parameter\(s\) given beside an AccessBroker \(sslmode\)/ ],
    [ 'a listen connection without connect info',
      __LINE__, sub { $s->_listen_open },
      qr/\Athe listen connection has no connect info -- call connect_info first\n\z/ ],
    [ 'LISTEN on a closed listen connection',
      __LINE__, sub { $s->_listen_subscribe({}, 'jobs') },
      qr/\ALISTEN on channel 'jobs': the listen connection is closed\n\z/ ],
    [ 'UNLISTEN on a closed listen connection',
      __LINE__, sub { $s->_listen_unsubscribe({}, 'jobs') },
      qr/\AUNLISTEN on channel 'jobs': the listen connection is closed\n\z/ ],
    [ 'watching a closed listen connection',
      __LINE__, sub { $s->_listen_watch({}) },
      qr/\Athe listen connection is closed\n\z/ ],
    [ 'watching a listen connection that is not connected',
      __LINE__, sub { $s->_listen_watch({ pg => $fake_down }) },
      qr/\Athe listen connection is not connected\n\z/ ],
    [ 'a channel name over 63 bytes',
      __LINE__, sub { $s->_listen_subscribe({}, 'x' x 64) },
      qr/\ALISTEN channel name 'x{64}' is 64 bytes long; .*at most 63 bytes/s ],
    [ 'no channel name',
      __LINE__, sub { $s->_listen_subscribe({}, undef) },
      qr/\Aa LISTEN channel name must be a non-empty string\n\z/ ],
    [ 'a statement that mixes $N and ?',
      __LINE__, sub { $s->_transform_sql(q{SELECT $1, ?}) },
      qr/mixes \$N and \?/ ],
    [ 'a statement that mixes $N and ?, issued',
      __LINE__, sub { $s->_query_async(q{SELECT $1, ?}, [ 1 ]) },
      qr/mixes \$N and \?/ ],
  );

  for my $case (@refusals) {
    my ($name, $line, $code, $says) = @$case;
    my $ok  = eval { $code->(); 1 };
    my $err = $@;
    ok !$ok, "$name: refused";
    like refusal_text($err), $says, "$name: ... saying why, as before";
    refused($err, $line, $name);
  }

  like eval { $s->_async_broker_conninfo; 1 } ? '' : "$@",
    qr/\ADBIO::PostgreSQL::EV::Storage::_async_broker_conninfo\(\): /,
    q{the refusal names the transport's method that refused, as core's exceptions do};
}

# ---------------------------------------------------------------------------
# 2. Reached through the pool: the broker answers what the transport cannot
#    connect from when the pool asks for a connection.
# ---------------------------------------------------------------------------
{
  my $broker = AnswerBroker->new({ dbname => 'app', host => 'db' });
  my $s = $EV_STORAGE->new(undef);
  $s->connect_info([ $broker ]);
  $broker->{answer} = { dbname => 'app', host => ['db'] };

  my $line = __LINE__; my $f = eval { $s->select_async('artist', ['*'], {}, {}) };
  ok $f && $f->is_failed, q{a statement whose connection the broker answers with a reference: its Future fails}
    or diag $@;
  my ($err) = $f && $f->is_failed ? $f->failure : ($@);
  like refusal_text($err), qr/its libpq connection parameter 'host' is a reference/, '... with the refusal';
  refused($err, $line, q{the pool's refusal});
  is scalar(@EV::Pg::NEW), 0, '... and no connection was opened';
}

# ---------------------------------------------------------------------------
# 3. Reached in callbacks the EV loop runs.
# ---------------------------------------------------------------------------
{
  # A callback of the caller's: the statement it issues is refused at the line
  # that issued it, though the loop ran the callback inside $f->get.
  my $s = $EV_STORAGE->new(undef);
  my $timer_done = DBIO::PostgreSQL::EV::Future->new;
  my $w = EV::timer(0, 0, sub { $timer_done->done });
  my $line;
  my $f = $timer_done->then(sub {
    $line = __LINE__; $s->_query_async(q{SELECT $1, ?}, [ 1 ]);
  });
  my $ok  = eval { $f->get; 1 };
  my $err = $@;
  ok !$ok, 'a statement issued in a callback of the loop, mixing $N and ?: refused';
  like refusal_text($err), qr/mixes \$N and \?/, '... with the refusal';
  refused($err, $line, 'the refusal reached in a callback of the loop');
}

SKIP: {
  skip 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)', 4
    unless DBIO::Storage::Async->can('listen_alive');

  # A callback of the transport's own: core subscribes the channel once the
  # listen connection is up, inside EV::Pg's on_connect, and the refusal is
  # reached there. Core fails the listen Future with its words around it; the
  # place inside them is where the caller let EV::Pg call back -- here the line
  # that completes the fake's connect, under EV the caller's ->get or EV::run.
  my $s = $EV_STORAGE->new(undef);
  $s->connect_info([ { dbname => 'app', host => 'db' } ]);
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  $s->on_listen_error(sub { });
  @EV::Pg::NEW = ();
  my $listen = $s->listen(('x' x 64) => sub { });
  my ($pg) = grep { defined } @EV::Pg::NEW;
  my $line = __LINE__; $pg->t_connect if $pg;
  ok $listen->is_failed, 'listen on a channel name the rule refuses fails, in a callback';
  my ($err) = $listen->is_failed ? $listen->failure : ();
  like $err // '', qr/\ALISTEN on channel 'x{64}' failed: \S+ LISTEN channel name 'x{64}' is 64 bytes long; /,
    q{... in core's words around the refusal};
  refused($err, $line, 'the refusal reached in a callback of the transport', wrapped => 1);
  $s->disconnect;
}

SKIP: {
  skip 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)', 4
    unless DBIO::Storage::Async->can('listen_alive');

  # The same, the way EV::Pg calls back: from XS, inside EV::run. The
  # connection's own on_connect is the callback of an EV timer -- no frame of
  # the test's between the loop and it -- and the loop is run by the ->get of
  # the listen Future. The place is the line of that ->get.
  my $s = $EV_STORAGE->new(undef);
  $s->connect_info([ { dbname => 'app', host => 'db' } ]);
  $s->on_listen_error(sub { });
  @EV::Pg::NEW = ();
  my $listen = $s->listen(('x' x 64) => sub { });
  my ($pg) = grep { defined } @EV::Pg::NEW;
  $pg->{connected} = 1;
  my $w = EV::timer(0, 0, $pg->{args}{on_connect});
  my $line = __LINE__; my $ok = eval { $listen->get; 1 };
  my $err = $ok ? undef : $@;
  ok !$ok, 'listen on a channel name the rule refuses fails, the callback run by EV';
  like $err // '', qr/\ALISTEN on channel 'x{64}' failed: \S+ LISTEN channel name 'x{64}' is 64 bytes long; /,
    q{... in core's words around the refusal};
  refused($err, $line, 'the refusal reached in a callback EV ran', wrapped => 1);
  $s->disconnect;
}

# ---------------------------------------------------------------------------
# 4. Carp's verbose mode: a stack trace, and no password of the connect info
#    the refusal is about -- not where a frame of the caller's repeats it.
# ---------------------------------------------------------------------------
{
  my $secret = 'tr0ub4dor-k88';
  {
    package K88::Answer;
    sub refuse_static {
      my ($password) = @_;
      DBIO::PostgreSQL::EV::Storage->new(undef)->connect_info(
        [ { dbname => 'app', host => ['db'], user => 'app', password => $password } ],
      );
    }
    sub refuse_broker {
      my ($password) = @_;
      DBIO::PostgreSQL::EV::Storage->new(undef)->connect_info(
        [ AnswerBroker->new([ 'dbi:mysql:dbname=app', 'app', $password ]) ],
      );
    }
  }

  for my $way (qw( refuse_static refuse_broker )) {
    local $Carp::Verbose = 1;
    eval { K88::Answer->can($way)->($secret) };
    my $err = $@;
    isa_ok $err, 'DBIO::Exception', "$way under verbose: the refusal";
    like "$err", qr/K88::Answer::\Q$way\E\(/, "$way: ... a stack trace was written, the caller's frame in it";
    unlike "$err", qr/\Q$secret\E/, "$way: ... and the password is not in it";
  }
}

# ---------------------------------------------------------------------------
# 5. EV::Pg's croaks at pipeline enter and exit: strings, without the place.
# ---------------------------------------------------------------------------
{
  my $s  = $EV_STORAGE->new(undef);
  my $pg = bless { connected => 1, queue => [] }, 'EV::Pg';

  {
    local $EV::Pg::CROAK{enter_pipeline} = 'PQenterPipelineMode failed: cannot enter pipeline mode, connection not idle';
    my $ok = eval { $s->_pipeline_enter($pg); 1 };
    is $ok ? undef : $@, "PQenterPipelineMode failed: cannot enter pipeline mode, connection not idle\n",
      q{EV::Pg's croak at enter_pipeline: its text and a newline, no place of the library};
  }
  {
    local $EV::Pg::CROAK{exit_pipeline} = 'PQexitPipelineMode failed: cannot exit pipeline mode while busy';
    my $ok = eval { $s->_pipeline_exit($pg); 1 };
    is $ok ? undef : $@, "PQexitPipelineMode failed: cannot exit pipeline mode while busy\n",
      q{EV::Pg's croak at exit_pipeline: its text and a newline, no place of the library};
  }
}

done_testing;
