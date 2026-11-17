use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::QueryExecutor;

# OFFLINE. The server words its error texts in the language of its session
# (lc_messages); the sentence rules of the masker know the English ones. A
# German or French `Doppelter Eintrag 'ab' fuer Schluessel ...` with a value
# shorter than four characters has nothing the bound-value pass can find, so
# the value would stand in the message. The error NUMBER is the same in every
# language, and EV::MariaDB keeps it on the handle (`error_number`): the
# transport reads it while the handle holds the error of the statement and
# hands it to the masker, which masks by the code, not by the wording (the
# convention of dbio-mysql: DBIO::MySQL::Util::mask_error_details($text,
# $values, $sql, $code)). This file drives every way a server text reaches a
# Future against a fake handle with German and French texts and numbers, and
# pins what is NOT read: a client number, a handle that holds another error.

{
  package FakeConn;
  sub new { my $c = shift; bless { @_ }, $c }
  sub sqlstate      { $_[0]{state}  // '23000' }
  sub error_number  { $_[0]{number} }
  sub error_message { $_[0]{message} }
  sub _fail {
    my ($self, $cb, $text) = @_;
    $self->{message} = $text;
    $cb->(undef, $text);
  }
  sub prepare {
    my ($self, $sql, $cb) = @_;
    die $self->{prepare_die} if $self->{prepare_die};
    # What EV::MariaDB does (measured, 0.09 against MySQL 8.0 and MariaDB): a
    # refused prepare reaches the callback as text and the handle holds NO
    # error afterwards -- error_number 0, error_message ''.
    if ($self->{prepare_err}) {
      @$self{qw(number message)} = (0, '');
      return $cb->(undef, $self->{prepare_err});
    }
    $cb->(7);
  }
  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    die $self->{execute_die} if $self->{execute_die};
    return $self->_fail($cb, $self->{execute_err}) if $self->{execute_err};
    $cb->([[1]]);
  }
  sub close_stmt { my ($self, $stmt, $cb) = @_; $self->{number} = 0; $self->{message} = ''; $cb->(1) }
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
  EV::run(EV::RUN_NOWAIT());
  ok $f->is_ready && $f->is_failed, '... the Future failed' or return;
  return ($f->failure)[0];
}

my $storage  = DBIO::MySQL::EV::Storage->new(undef);
my $executor = $storage->_executor;

# [ language, number, text, the masked text ]
my @texts = (
  [ 'de 1062', 1062, q{Doppelter Eintrag 'ab' für Schlüssel 'fw_t.PRIMARY'},
                     q{Doppelter Eintrag '***' für Schlüssel 'fw_t.PRIMARY'} ],
  [ 'fr 1062', 1062, q{Duplicata du champ 'xy' pour la clef 'fw_t.PRIMARY'},
                     q{Duplicata du champ '***' pour la clef 'fw_t.PRIMARY'} ],
  [ 'de 1366', 1366, q{Falscher INTEGER-Wert: 'ab' für Feld 'i' in Zeile 1},
                     q{Falscher INTEGER-Wert: '***' für Feld 'i' in Zeile 1} ],
  [ 'fr 1366', 1366, q{Valeur d'entier incorrecte: 'xy' pour la colonne 'i' à la ligne 1},
                     q{Valeur d'entier incorrecte: '***' pour la colonne 'i' à la ligne 1} ],
);

for my $t (@texts) {
  my ($label, $number, $text, $masked) = @$t;
  my %handle = (number => $number, state => $number == 1062 ? '23000' : '22007');

  my $conn = FakeConn->new(%handle, execute_err => $text);
  my $err = failure_of($executor->execute($conn, 'INSERT INTO t (c) VALUES (?)', ['ab']));
  is "$err", $masked, "$label: a refused execute is masked by the code";
  isa_ok $err, 'DBIO::Exception::Server', "$label: the exception";

  $conn = FakeConn->new(%handle, query_err => $text);
  is "" . failure_of($executor->execute($conn, q{INSERT INTO t (c) VALUES ('ab')}, [])), $masked,
    "$label: a refused query is masked by the code";

  # the pinned statements of a transaction go through the same executor
  $conn = FakeConn->new(%handle, query_err => $text);
  is "" . failure_of($executor->execute($conn, 'COMMIT', [])), $masked,
    "$label: a COMMIT that fails is masked by the code";

  $conn = FakeConn->new(%handle, reset_err => $text);
  is "" . failure_of($executor->reset_connection($conn)), $masked,
    "$label: a refused reset is masked by the code";

  # the croak of an execute that carries the handle's text
  $conn = FakeConn->new(%handle, message => $text, execute_die => "$text at X line 1.\n");
  is failure_of($executor->execute($conn, 'INSERT INTO t (c) VALUES (?)', ['ab'])), "$masked at X line 1.\n",
    "$label: a croak that carries the server's text is masked by the code";

  # the listen connection's runner: query, prepare and execute paths
  for my $way (qw(query_err execute_err)) {
    my $lconn = { pid => $$, queue => [], mdb => FakeConn->new(%handle, $way => $text) };
    my $sql   = $way eq 'query_err' ? q{INSERT INTO n (c) VALUES ('ab')} : 'INSERT INTO n (c) VALUES (?)';
    my $f     = $storage->_mysql_listen_statement($lconn, $sql, $way eq 'query_err' ? [] : ['ab']);
    ok $f->is_ready && $f->is_failed, "$label: listen $way: the Future failed";
    is(($f->failure)[0], $masked, "$label: listen $way: masked by the code");
  }
}

# --- a refused prepare has no code on the handle -------------------------------

{
  my @seen;
  my $x = DBIO::MySQL::EV::QueryExecutor->new(error_masker => sub { push @seen, [ @_ ]; $_[0] });
  my $conn = FakeConn->new(number => 1146, prepare_err => q{Tabelle 'db.t' existiert nicht});
  my $err = failure_of($x->execute($conn, 'INSERT INTO t (c) VALUES (?)', ['ab']));
  is "$err", q{Tabelle 'db.t' existiert nicht}, 'a refused prepare is the text';
  ok !defined $seen[0][3], '... the handle holds no error of it, so the masker is given no code';

  # the same for the listen connection's runner
  @seen = ();
  my $lconn = { pid => $$, queue => [],
    mdb => FakeConn->new(number => 1146, prepare_err => q{Tabelle 'db.t' existiert nicht}) };
  my $f = $storage->_mysql_listen_statement($lconn, 'INSERT INTO n (c) VALUES (?)', ['ab']);
  ok $f->is_failed, 'a refused prepare on the listen connection fails its Future';
}

# --- the code is not read where it does not belong ---------------------------

{
  # a client number: masked as before, by the wording alone
  my $conn = FakeConn->new(number => 2013, execute_err => q{Lost connection, last value was geheim-wert-77});
  my $err = failure_of($executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']));
  is $err, 'Lost connection, last value was ***', 'a client number is no code: masked as before';
}
{
  # a handle that holds another error than the text: the number is not this text's
  my $conn = FakeConn->new(number => 1062, message => q{Duplicate entry 'zz' for key 'k'},
    execute_die => "Reset refused geheim-wert-77\n");
  my $err = failure_of($executor->execute($conn, 'UPDATE t SET a = ?', ['geheim-wert-77']));
  is $err, "Reset refused ***\n", 'the code of a handle that holds another error is not used';
}
{
  # a text without a code that quotes a value keeps the wording rules
  my $conn = FakeConn->new(number => 1064, state => '42000', prepare_err => q{Syntax near 'geheim-wert-77' at line 1});
  my $err = failure_of($executor->execute($conn, 'SELEC ?', ['geheim-wert-77']));
  unlike "$err", qr/geheim-wert-77/, 'a syntax error (1064) holds no bound value';
}

# --- the masker contract: text, values, statement, code -------------------------

{
  my @seen;
  my $x = DBIO::MySQL::EV::QueryExecutor->new(error_masker => sub { push @seen, [ @_ ]; "m: $_[0]" });
  my $conn = FakeConn->new(number => 1062, execute_err => q{Doppelter Eintrag 'ab' für Schlüssel 'k'});
  failure_of($x->execute($conn, 'INSERT INTO t VALUES (?)', ['ab']));
  is $seen[0][3], 1062, 'the masker is handed the error number as the fourth argument';

  @seen = ();
  $conn = FakeConn->new(number => 2013, execute_err => 'lost');
  failure_of($x->execute($conn, 'INSERT INTO t VALUES (?)', ['ab']));
  ok !defined $seen[0][3], '... undef for a client number';
}

done_testing;
