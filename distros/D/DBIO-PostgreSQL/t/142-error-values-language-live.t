use strict;
use warnings;
use utf8;
use Test::More;

binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output todo_output);

# LIVE test: no value a statement was run with is in the text of the error the
# server answers with, in whatever language the server reports (ADR 0010).
#
# WHY: PostgreSQL words its messages by lc_messages. The masking of an error
# text (DBIO::PostgreSQL::Util, t/140-mask-error-values.t) hung on the English
# sentences, so on a server set to German or French a short bound value (core
# masks four characters and more by itself) and every value the server quotes
# stood in the message:
#   DETAIL:  Schlüssel »(name)=(ab)« existiert bereits.
#   FEHLER:  ungültige Eingabesyntax für Typ integer: »xy«
# What holds in every language is the SQLSTATE of the error (class 22: a value
# of a cast; class 23: the key or the row in DETAIL), the marks a language
# quotes a value in, and the fields of DBD::Pg. t/141-error-values-live.t holds
# the English forms; this file holds that the same statements, run with
# lc_messages set to de_DE.UTF-8 and fr_FR.UTF-8 in the session, name no value
# either, on the sync storage (through the hook and through the plain handle)
# and on the future_io transport.
#
# Each case also checks that the server did answer in the language asked for
# (the label of its message, FEHLER or ERREUR): a test of the masking on an
# English text would test nothing. A language the server does not know
# (its locale is not installed) is skipped, with that reason, and only that one.
# The only change to the server is the SET of the session.
#
# Works in a schema of its own, dbio_msgsprache_live, and drops it.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the future_io way';
}

use Future;
use Future::IO;
use Scalar::Util ();
use DBIO::Test;

DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $S = 'dbio_msgsprache_live';

my $control = LiveServer->control_dbh;
{
  local $control->{Warn} = 0;
  local $SIG{__WARN__} = sub { };
  $control->do("DROP SCHEMA IF EXISTS $S CASCADE");
}
$control->do("CREATE SCHEMA $S");
END {
  if ($control && $control->{Active}) {
    local $SIG{__WARN__} = sub { };
    eval { $control->do("DROP SCHEMA IF EXISTS $S CASCADE") };
  }
}

$control->do($_) for (
  "SET search_path = $S",
  q{CREATE TABLE t (id int primary key, name varchar(20) unique, n int not null default 1,
      c int check (c > 0), note text)},
  q{CREATE TABLE f (x int references t (id))},
  q{INSERT INTO t (id, name) VALUES (1, 'ab')},
);

# name, sql, binds, the SQLSTATE, the table and constraint the error names, and
#   gone   pieces that must not be in the text: a regex
#   keep   forms that must stay: a regex
# The values are short (core's net masks four characters and more by itself).
my @cases = (
  { name => 'unique key, short value', sql => "INSERT INTO t (id, name) VALUES (?, ?)", bind => [2, 'ab'],
    state => '23505', table => 't', constraint => 't_name_key',
    gone => [qr/(?<!\w)ab(?!\w)/], keep => [qr/t_name_key/, qr/\(name\)=\(\*\*\*\)/] },
  { name => 'integer syntax', sql => "INSERT INTO t (id, n) VALUES (?, ?)", bind => [3, 'xy'],
    state => '22P02',
    gone => [qr/(?<!\w)xy(?!\w)/], keep => [qr/integer/] },
  { name => 'not null, failing row', sql => "INSERT INTO t (id, n, note) VALUES (?, ?, ?)", bind => [4, undef, 'qrs'],
    state => '23502', table => 't',
    gone => [qr/qrs/], keep => [qr/\(\*\*\*\)/] },
  { name => 'check, failing row', sql => "INSERT INTO t (id, c, note) VALUES (?, ?, ?)", bind => [5, -7, 'qrs'],
    state => '23514', table => 't', constraint => 't_c_check',
    gone => [qr/-7/, qr/qrs/], keep => [qr/t_c_check/, qr/\(\*\*\*\)/] },
  { name => 'foreign key, key not present', sql => "INSERT INTO f (x) VALUES (?)", bind => [99],
    state => '23503', table => 'f', constraint => 'f_x_fkey',
    gone => [qr/\b99\b/], keep => [qr/f_x_fkey/, qr/\(x\)=\(\*\*\*\)/] },
);

my @languages = (
  [ 'de_DE.UTF-8', qr/FEHLER/, 'German' ],
  [ 'fr_FR.UTF-8', qr/ERREUR/, 'French' ],
);

sub check_text {
  my ($way, $lang, $case, $text, $label) = @_;
  my $name = "$lang $way: $case->{name}";

  like $text, $label, "$name: the server answered in the language asked for";

  my @leaks = grep { $text =~ $_ } @{ $case->{gone} };
  ok !@leaks, "$name: no value in the text"
    or diag 'leaks: ' . join(', ', map "$_", @leaks) . "\nthe text:\n$text";

  my @lost = grep { $text !~ $_ } @{ $case->{keep} };
  ok !@lost, "$name: the constraint, the columns and the rest of the text stay"
    or diag 'lost: ' . join(', ', map "$_", @lost) . "\nthe text:\n$text";
}

sub failure_of {
  my ($code) = @_;
  my $ok = eval { $code->(); 1 };
  return $ok ? undef : $@;
}

my $LIMIT = 15;
sub async_failure_of {
  my ($f) = @_;
  my $ok = eval {
    Future->wait_any(
      $f->without_cancel,
      Future::IO->sleep($LIMIT)->then(sub { Future->fail("not finished after $LIMIT seconds\n") }),
    )->get;
    1;
  };
  return $ok ? undef : $@;
}

for my $language (@languages) {
  my ($locale, $label, $what) = @$language;

  my $known = do {
    local $control->{PrintError} = 0;
    local $control->{RaiseError} = 0;
    my $ok = $control->do("SET lc_messages = '$locale'");
    $control->do('RESET lc_messages');
    $ok;
  };
  unless ($known) {
    SKIP: { skip "the server has no locale $locale installed ($what messages cannot be produced here)", 1 }
    next;
  }

  my @on_connect = ("SET lc_messages = '$locale'", "SET search_path = $S");

  # --- the sync storage: through the hook and through the plain handle -------
  my $schema  = DBIO::Test::Schema->connect($dsn, $user, $pass,
    { AutoCommit => 1, on_connect_do => [@on_connect] });
  my $storage = $schema->storage;
  my $dbh     = $storage->dbh;
  isa_ok $storage, 'DBIO::PostgreSQL::Storage', "$locale: the storage, once connected";

  for my $way (qw( hook raw )) {
    for my $case (@cases) {
      my @bind = @{ $case->{bind} };
      my $err = failure_of($way eq 'hook'
        ? sub {
            $storage->dbh_do(sub {
              my ($s, $h) = @_;
              $s->_dbh_execute($h, $case->{sql}, [ map { [ {}, $_ ] } @bind ], []);
            });
          }
        : sub {
            my $sth = $dbh->prepare($case->{sql});
            $sth->execute(@bind);
          });
      my $name = "$locale $way: $case->{name}";

      ok defined $err, "$name: the server refuses" or next;
      check_text($way, $locale, $case, "$err", $label);

      ok Scalar::Util::blessed($err) && $err->isa('DBIO::Exception::Server'),
        "$name: a DBIO::Exception::Server" or next;
      is $err->sqlstate, $case->{state}, "$name: the SQLSTATE stays";
      is $err->table, $case->{table}, "$name: the table field stays" if exists $case->{table};
      is $err->constraint, $case->{constraint}, "$name: the constraint field stays" if exists $case->{constraint};

      my $detail = $err->detail // '';
      my @leaks = grep { $detail =~ $_ } @{ $case->{gone} };
      ok !@leaks, "$name: no value in the detail field" or diag "detail: $detail";
    }
  }
  $schema->storage->disconnect;

  # --- the future_io transport ------------------------------------------------
  my $async_schema = DBIO::Test::Schema->connect($dsn, $user, $pass,
    { async => 'future_io', on_connect_do => [@on_connect] });
  my $async = $async_schema->storage->async;

  for my $case (@cases) {
    my $err = async_failure_of($async->_query_async($case->{sql}, [ @{ $case->{bind} } ]));
    my $name = "$locale async: $case->{name}";
    ok defined $err && !ref $err, "$name: the server refuses, with a plain string" or next;
    check_text('async', $locale, $case, $err, $label);
  }
  $async->disconnect;
}

{
  local $SIG{__WARN__} = sub { };
  eval { $control->do("DROP SCHEMA IF EXISTS $S CASCADE") };
}

done_testing;
