use strict;
use warnings;
use utf8;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use LibpqCLocale;
use Scalar::Util ();

binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output todo_output);

# LIVE: no value a statement was run with is in the text of the error the
# server answers with, in whatever language the server reports (as
# t/142-error-values-language-live.t of dbio-postgresql, on the EV paths).
#
# WHY: PostgreSQL words its messages by lc_messages. The masking of an error
# text hung on the English sentences, so on a server set to German or French a
# short bound value (core masks four characters and more by itself) and every
# value the server quotes stood in the message:
#   DETAIL:  Schlüssel »(name)=(ab)« existiert bereits.
#   FEHLER:  ungültige Eingabesyntax für Typ integer: »xy«
# What holds in every language is the SQLSTATE of the error (class 22: a value
# of a cast; class 23: the key or the row in DETAIL) and the marks a language
# quotes a value in; the rules are DBIO::PostgreSQL::Util's, this transport
# hands them the SQLSTATE of the error.
#
# Each case also checks that the server did answer in the language asked for
# (the label of its message, FEHLER or ERREUR): a test of the masking on an
# English text would test nothing. A language the server does not know (its
# locale is not installed) is skipped, with that reason, and only that one.
# The only change to the server is the SET of the session (on_connect_do).
#
# Works in a schema of its own, dbio_msgsprache_ev, and drops it.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use LiveServer;
LiveServer->require_server;

use EV;

alarm 300;

my $S = 'dbio_msgsprache_ev';

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

sub failure_of {
  my ($h, $f) = @_;
  return eval { $h->await($f); 1 } ? undef : $@;
}

sub check_error {
  my ($name, $case, $err, $label) = @_;

  ok defined $err, "$name: the server refuses" or return;
  my $text = "$err";
  like $text, $label, "$name: the server answered in the language asked for";

  my @leaks = grep { $text =~ $_ } @{ $case->{gone} };
  ok !@leaks, "$name: no value in the text"
    or diag 'leaks: ' . join(', ', map "$_", @leaks) . "\nthe text:\n$text";

  my @lost = grep { $text !~ $_ } @{ $case->{keep} };
  ok !@lost, "$name: the constraint, the columns and the rest of the text stay"
    or diag 'lost: ' . join(', ', map "$_", @lost) . "\nthe text:\n$text";

  return unless Scalar::Util::blessed($err);
  ok $err->isa('DBIO::Exception::Server'), "$name: a DBIO::Exception::Server" or return;
  is $err->sqlstate, $case->{state}, "$name: the SQLSTATE stays";
  is $err->table, $case->{table}, "$name: the table field stays" if exists $case->{table};
  is $err->constraint, $case->{constraint}, "$name: the constraint field stays" if exists $case->{constraint};
  my $detail = $err->detail // '';
  my @dleaks = grep { $detail =~ $_ } @{ $case->{gone} };
  ok !@dleaks, "$name: no value in the detail field" or diag "detail: $detail";
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

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
    connect_attrs => {
      pool_size     => 2,
      on_connect_do => [ "SET lc_messages = '$locale'", "SET search_path = $S" ],
    },
  );
  my $async = $h->async;

  my %path = (
    pooled => sub {
      my ($sql, $bind) = @_;
      return failure_of($h, $async->_query_async($sql, $bind));
    },
    pinned => sub {
      my ($sql, $bind) = @_;
      my $pg = $h->await($h->pool->acquire);
      my $err = failure_of($h, $h->query_on($pg, $sql, $bind));
      $h->pool->release($pg);
      return $err;
    },
    txn_do_async => sub {
      my ($sql, $bind) = @_;
      return failure_of($h, $async->txn_do_async(sub { $_[0]->_query_async($sql, $bind) }));
    },
    pipeline => sub {
      my ($sql, $bind) = @_;
      return failure_of($h, $async->pipeline(sub { $_[0]->_query_async($sql, $bind) }));
    },
  );

  for my $path (qw( pooled pinned txn_do_async pipeline )) {
    for my $case (@cases) {
      check_error("$locale ev $path: $case->{name}", $case,
        $path{$path}->($case->{sql}, [ @{ $case->{bind} } ]), $label);
    }
  }

  is_deeply [ $h->await($async->_query_async('SELECT 7::int')) ], [ [7] ],
    "$locale: the pool answers after the failures";
  $h->disconnect;
}

done_testing;
