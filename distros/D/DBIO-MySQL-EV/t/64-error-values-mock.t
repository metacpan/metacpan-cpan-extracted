use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::QueryExecutor;

# OFFLINE (ADR 0075 of the core): an error message names keys, columns and
# options, never a value. MySQL and MariaDB write the offending value into
# their error text, bind or not -- `Duplicate entry 'x' for key ...`,
# `Incorrect integer value: 'x' for column ...` -- so the executor masks the
# text BEFORE it builds the exception (DBIO::MySQL::Util::mask_error_details
# plus DBIO::Util::mask_bound_values, through the storage's masker). This file
# drives the real executor and the real storage against a fake EV::MariaDB
# handle that answers with the server's text, and pins every way such a text
# reaches a Future: the statement callbacks (prepare, execute, query), a
# croaking execute, a dispatch that dies, the reset, and the listen
# connection's runner. The sqlstate of the exception stays.

{
  package FakeConn;
  sub new { my $c = shift; bless { @_ }, $c }
  # What the handle holds after an error: the server's own state and number.
  sub sqlstate      { $_[0]{state}   // '23000' }
  sub error_number  { $_[0]{number}  // 1062 }
  sub error_message { $_[0]{message} }
  sub _fail {
    my ($self, $cb, $text) = @_;
    $self->{message} = $text;
    $cb->(undef, $text);
  }
  sub prepare {
    my ($self, $sql, $cb) = @_;
    die $self->{prepare_die} if $self->{prepare_die};
    return $self->_fail($cb, $self->{prepare_err}) if $self->{prepare_err};
    $cb->(7);
  }
  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    die $self->{execute_die} if $self->{execute_die};
    return $self->_fail($cb, $self->{execute_err}) if $self->{execute_err};
    $cb->([[1]]);
  }
  sub close_stmt { my ($self, $stmt, $cb) = @_; $cb->(1) }
  sub query {
    my ($self, $sql, $cb) = @_;
    return $self->_fail($cb, $self->{query_err}) if $self->{query_err};
    $cb->([[1]]);
  }
  sub reset_connection {
    my ($self, $cb) = @_;
    return $self->_fail($cb, $self->{reset_err}) if $self->{reset_err};
    $cb->(1);
  }
}

sub failure_of {
  my ($f) = @_;
  EV::run(EV::RUN_NOWAIT());   # a Future settles from the loop's idle watcher
  ok $f->is_ready && $f->is_failed, '... the Future failed' or return;
  return ($f->failure)[0];
}

my $storage  = DBIO::MySQL::EV::Storage->new(undef);
my $executor = $storage->_executor;

# --- the storage's executor masks --------------------------------------------

{
  my $conn = FakeConn->new(
    state => '22007', number => 1366,
    execute_err => q{Incorrect integer value: 'geheim42' for column 'i' at row 1},
  );
  my $err = failure_of($executor->execute($conn, 'INSERT INTO t (i) VALUES (?)', ['geheim42']));
  isa_ok $err, 'DBIO::Exception::Server', 'a refused execute';
  unlike "$err", qr/geheim42/, '... its text holds no value';
  is "$err", q{Incorrect integer value: '***' for column 'i' at row 1},
    '... it keeps the type and the column';
  is $err->sqlstate, '22007', '... and the SQLSTATE';
}

{
  my $conn = FakeConn->new(
    execute_err => q{Duplicate entry '987654321' for key 'fw_ev_t.PRIMARY'},
  );
  my $err = failure_of($executor->execute($conn, 'INSERT INTO t (id) VALUES (?)', [987654321]));
  is "$err", q{Duplicate entry '***' for key 'fw_ev_t.PRIMARY'}, 'a duplicate entry keeps the key name';
  is $err->sqlstate, '23000', '... and the SQLSTATE';
}

{
  my $conn = FakeConn->new(
    state => '42000', number => 1064,
    prepare_err => q{You have an error in your SQL syntax; check the manual that corresponds to your server version for the right syntax to use near 'wrong geheim42' at line 1},
  );
  my $err = failure_of($executor->execute($conn, 'SELEC ? FROM t', ['geheim42']));
  isa_ok $err, 'DBIO::Exception::Server', 'a refused prepare';
  unlike "$err", qr/geheim42/, '... its text holds no bound value';
  is $err->sqlstate, '42000', '... and the SQLSTATE';
}

{
  my $conn = FakeConn->new(
    state => '22001', number => 1406,
    query_err => q{Duplicate entry 'geheim-lit' for key 'PRIMARY'},
  );
  my $err = failure_of($executor->execute($conn, q{INSERT INTO t VALUES ('geheim-lit')}, []));
  is "$err", q{Duplicate entry '***' for key 'PRIMARY'}, 'a query without binds is masked too';
}

# The bind values reach the masker (a value that is no sentence of the engine).
{
  my $conn = FakeConn->new(
    state => 'HY000', number => 1105,
    execute_err => q{Unknown error: handler said geheim-wert-77 about it},
  );
  my $err = failure_of($executor->execute($conn, 'CALL p(?)', ['geheim-wert-77']));
  unlike "$err", qr/geheim-wert-77/, 'a bound value found elsewhere in the text is masked';
  like "$err", qr/handler said \*\*\* about it/, '... and the words around it stay';
}

# A client library error (not the server's) is masked as a string as well.
{
  my $conn = FakeConn->new(state => 'HY000', number => 2013, message => 'x');
  $conn->{execute_err} = q{Lost connection, last value was geheim-wert-77};
  my $err = failure_of($executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']));
  ok !ref $err, 'a client error stays a string';
  is $err, 'Lost connection, last value was ***', '... with the value taken out';
}

# --- an execute that croaks, a dispatch that dies -----------------------------

{
  my $conn = FakeConn->new(execute_die => "bad bind geheim-wert-77 at X line 1.\n");
  my $err = failure_of($executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']));
  is $err, "bad bind *** at X line 1.\n", 'an execute that croaks is masked';
}

{
  my $conn = FakeConn->new(prepare_die => "cannot prepare geheim-wert-77\n");
  my $died = !eval { $executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']); 1 };
  ok $died, 'a prepare EV::MariaDB refuses dies';
  is $@, "cannot prepare ***\n", '... masked';
}

{
  my $object = bless {}, 'Some::Error';
  my $conn = FakeConn->new;
  $conn->{prepare_die} = $object;
  my $died = !eval { $executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']); 1 };
  ok $died && ref $@ eq 'Some::Error', 'an exception object passes unchanged';
}

# --- the reset ----------------------------------------------------------------

{
  my $conn = FakeConn->new(reset_err => 'Reset refused geheim-wert-77');
  my $err = failure_of($executor->reset_connection($conn));
  is $err, 'Reset refused geheim-wert-77', 'a reset carries no bound value and is answered as it is';
}

# --- the masker is the executor's seam ---------------------------------------

{
  my @seen;
  my $x = DBIO::MySQL::EV::QueryExecutor->new(error_masker => sub {
    push @seen, [ @_ ];
    return "masked: $_[0]";
  });
  my $conn = FakeConn->new(execute_err => 'boom geheim-wert-77');
  my $err = failure_of($x->execute($conn, 'UPDATE t SET a = ?, b = ?', ['geheim-wert-77', undef, 'abc']));
  is "$err", 'masked: boom geheim-wert-77', 'the failure is what the masker answered';
  is $seen[0][0], 'boom geheim-wert-77', '... asked with the text';
  is_deeply $seen[0][1], ['geheim-wert-77'], '... the bound values of four characters or more';
  is $seen[0][2], 'UPDATE t SET a = ?, b = ?', '... and the statement';

  # No masker: the text is the server's, as before.
  my $plain = DBIO::MySQL::EV::QueryExecutor->new;
  my $c2 = FakeConn->new(execute_err => q{Duplicate entry 'x' for key 'k'});
  my $e2 = failure_of($plain->execute($c2, 'INSERT INTO t VALUES (?)', ['x']));
  is "$e2", q{Duplicate entry 'x' for key 'k'}, 'an executor without a masker leaves the text alone';
}

# --- the listen connection's runner --------------------------------------------

{
  my $conn = {
    pid   => $$,
    queue => [],
    mdb   => FakeConn->new(
      execute_err => q{Data truncated: payload geheim-nutzlast went wrong},
    ),
  };
  my $f = $storage->_mysql_listen_statement(
    $conn, 'INSERT INTO n (channel, payload) VALUES (?, ?)', ['events', 'geheim-nutzlast']);
  ok $f->is_ready && $f->is_failed, 'a failed statement of the listen connection fails its Future';
  my $msg = ($f->failure)[0];
  unlike $msg, qr/geheim-nutzlast/, '... its text holds no payload';
  like $msg, qr/payload \*\*\* went wrong/, '... the words around it stay';
}

{
  my $conn = {
    pid   => $$,
    queue => [],
    mdb   => FakeConn->new(prepare_die => "dispatch geheim-nutzlast\n"),
  };
  my $f = $storage->_mysql_listen_statement($conn, 'INSERT INTO n (payload) VALUES (?)', ['geheim-nutzlast']);
  unlike(($f->failure)[0], qr/geheim-nutzlast/, 'a listen statement that cannot be started holds no payload');
}

# --- connect statements run through the executor ---------------------------------

{
  my $conn = FakeConn->new(query_err => q{Unknown character set: 'geheim'});
  my $f = $storage->_executor->execute($conn, q{SET NAMES 'geheim'}, []);
  my $err = failure_of($f);
  is "$err", q{Unknown character set: '***'}, 'a connect action is masked like every statement';
}

done_testing;
