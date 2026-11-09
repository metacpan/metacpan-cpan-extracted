use strict;
use warnings;
use Test::More;
use Scalar::Util ();

# LIVE, ADR 0075 (core): the values a statement bound do not reach an
# exception. The text the server writes into an error quotes the value that
# failed -- 'invalid input syntax for type integer: "geheim42"', 'relation
# "geheim42" does not exist', the line of a COPY -- and an exception is logged,
# mailed and shown. Every way the server's text reaches an exception of this
# transport takes the values out first.
#
# The claims, for each case of the table below, on every path that carries a
# statement's error:
#   1. the pooled statement, the statement on a pinned connection, inside
#      txn_do_async and in a pipeline fail, and
#   2. neither the message nor the detail of the exception nor the string it
#      stringifies to holds the value (or the piece of it the server quoted).
# A COPY whose data line the server refuses (copy_in) is held to the same, and
# so are the same statements over the future_io transport of dbio-postgresql
# when that transport is installed.
#
# The cases are the forms of the main message the server writes with a value in
# it -- integer, smallint range, enum, date, date/time range, array literal,
# hexadecimal digit, byte sequence, time zone, the TimeZone parameter, json, uuid,
# numeric, boolean -- with a value of four characters or more and with a short
# one, and the forms only a value bound to the statement can be found in
# (regclass, regtype, regrole: 'relation "..." does not exist'), and the
# constraints of a table (unique key, NOT NULL and CHECK rows).
#
# Objects of its own (one enum type, two tables), dropped at the end; nothing
# server-wide is touched.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;

alarm 300;

my $MOOD = 'dbio_t119_mood';
my $TAB  = 'dbio_t119_tab';
my $COPY = 'dbio_t119_copy';

my $control = LiveServer->control_dbh;
sub drop_objects {
  $control->do("DROP TABLE IF EXISTS $_") for $TAB, $COPY;
  $control->do("DROP TYPE IF EXISTS $MOOD");
}
{
  local $SIG{__WARN__} = sub { };    # NOTICE: ... does not exist, skipping
  drop_objects();
}
END { eval { drop_objects() } }

$control->do("CREATE TYPE $MOOD AS ENUM ('ok', 'sad')");
$control->do("CREATE TABLE $TAB (id int PRIMARY KEY, tag text UNIQUE, n int NOT NULL CHECK (n > 0))");
$control->do("CREATE TABLE $COPY (a integer, m $MOOD, b text)");
$control->do("INSERT INTO $TAB VALUES (1, 'taken-geheim', 5)");

# name => [ sql, \@bind, qr/what must not be in the error/ ]
my @CASES = (
  # the forms of the main message, a long value
  [ 'integer',            'SELECT ?::integer',          ['geheim42'],           qr/geheim42/ ],
  [ 'smallint range',     'SELECT ?::smallint',         ['7774242'],            qr/7774242/ ],
  [ 'enum',               "SELECT ?::$MOOD",            ['geheim42'],           qr/geheim42/ ],
  [ 'date syntax',        'SELECT ?::date',             ['geheim42'],           qr/geheim42/ ],
  [ 'date range',         'SELECT ?::date',             ['2020-13-45'],         qr/2020-13-45/ ],
  [ 'timestamp range',    'SELECT ?::timestamp',        ['2020-13-45 geheim42'], qr/geheim42/ ],
  [ 'array literal',      'SELECT ?::int[]',            ['geheim42'],           qr/geheim42/ ],
  [ 'array element',      'SELECT ?::int[]',            ['{geheim42}'],         qr/geheim42/ ],
  [ 'hex digit',          q{SELECT decode(?, 'hex')},   ['qgeheim42'],          qr/"q"/ ],
  [ 'byte sequence',      q{SELECT convert_from(decode(?, 'hex'), 'UTF8')}, ['c328'], qr/0xc3|0x28/ ],
  [ 'time zone',          'SELECT now() AT TIME ZONE ?', ['Xy/Zgeheim'], qr/Zgeheim/ ],
  [ 'TimeZone parameter', q{SELECT set_config('TimeZone', ?, false)}, ['Xy/Zgeheim'], qr/Zgeheim/ ],
  [ 'json token',         'SELECT ?::jsonb',            ['geheim42'],           qr/geheim42/ ],
  [ 'uuid',               'SELECT ?::uuid',             ['geheim42'],           qr/geheim42/ ],
  [ 'numeric',            'SELECT ?::numeric',          ['geheim42'],           qr/geheim42/ ],
  [ 'boolean',            'SELECT ?::boolean',          ['geheim42'],           qr/geheim42/ ],
  [ 'portal parameter',   'SELECT 1 WHERE 1 = ?',       ['geheim42'],           qr/geheim42/ ],
  # a value shorter than four characters, in the forms mask_error_details knows
  [ 'short integer',      'SELECT ?::integer',          ['xyz'],                qr/xyz/ ],
  [ 'short enum',         "SELECT ?::$MOOD",            ['xyz'],                qr/xyz/ ],
  [ 'short date',         'SELECT ?::date',             ['xyz'],                qr/xyz/ ],
  [ 'short uuid',         'SELECT ?::uuid',             ['xyz'],                qr/xyz/ ],
  [ 'short numeric',      'SELECT ?::numeric',          ['xyz'],                qr/xyz/ ],
  [ 'short boolean',      'SELECT ?::boolean',          ['xyz'],                qr/xyz/ ],
  [ 'short array',        'SELECT ?::int[]',            ['xyz'],                qr/xyz/ ],
  # a form only the bound value can be found by
  [ 'regclass',           'SELECT ?::regclass',         ['geheim42'],           qr/geheim42/ ],
  [ 'regtype',            'SELECT ?::regtype',          ['geheim42'],           qr/geheim42/ ],
  [ 'regrole',            'SELECT ?::regrole',          ['geheim42'],           qr/geheim42/ ],
  # the constraints of a table
  [ 'unique key',         "INSERT INTO $TAB (id, tag, n) VALUES (?, ?, ?)", [2, 'taken-geheim', 5], qr/taken-geheim/ ],
  [ 'not null row',       "INSERT INTO $TAB (id, tag, n) VALUES (?, ?, ?)", [3, 'row-geheim42', undef], qr/row-geheim42/ ],
  [ 'check row',          "INSERT INTO $TAB (id, tag, n) VALUES (?, ?, ?)", [4, 'row-geheim43', -1], qr/row-geheim43/ ],
  [ 'short check row',    "INSERT INTO $TAB (id, tag, n) VALUES (?, ?, ?)", [5, 'ab', -1], qr/\bab\b/ ],
);

# What an error is made of: every text a caller can read from it.
sub texts_of {
  my ($err) = @_;
  my @texts = ("$err");
  if (Scalar::Util::blessed($err)) {
    for my $method (qw( detail )) {
      push @texts, scalar $err->$method if $err->can($method) && defined $err->$method;
    }
  }
  return @texts;
}

sub failure_of {
  my ($h, $f) = @_;
  return eval { $h->await($f); 1 } ? undef : $@;
}

sub holds_no_value {
  my ($label, $err, $leak) = @_;
  unless (defined $err) {
    fail "$label: the statement fails";
    return;
  }
  my @found = grep { /$leak/ } texts_of($err);
  ok !@found, "$label: no value in the exception"
    or diag "the exception says: ", join ' | ', @found;
  return;
}

# --- the EV transport ---------------------------------------------------------

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  connect_attrs => { pool_size => 2 },
);
my $async = $h->async;

my %EV_PATH = (
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
  for my $case (@CASES) {
    my ($name, $sql, $bind, $leak) = @$case;
    holds_no_value("ev $path, $name", $EV_PATH{$path}->($sql, [@$bind]), $leak);
  }
}

# --- copy_in: the data line the server refuses -------------------------------

for my $case (
  [ 'copy integer',       [ 'geheim42', 'ok', 'x' ],      qr/geheim42/ ],
  [ 'copy enum',          [ 1, 'geheim42', 'x' ],         qr/geheim42/ ],
  [ 'copy short integer', [ 'xyz', 'ok', 'x' ],           qr/xyz/ ],
  [ 'copy short enum',    [ 1, 'xyz', 'x' ],              qr/xyz/ ],
) {
  my ($name, $row, $leak) = @$case;
  my $f = $async->copy_in($COPY, [qw( a m b )], sub { $_[0]->($row) });
  holds_no_value("ev $name", failure_of($h, $f), $leak);
}

# --- notify: a payload the server refuses ---------------------------------------

{
  my $f = $async->notify('dbio_t119', 'geheim42' x 1100);
  holds_no_value('ev notify, payload too long', failure_of($h, $f), qr/geheim42/);
}

# The pool still works after all of it.
is_deeply [ $h->await($async->_query_async('SELECT 7::int')) ], [ [7] ],
  'the pool answers after the failures';

$h->disconnect;

# --- the future_io transport of dbio-postgresql ------------------------------

SKIP: {
  my $have = eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  };
  skip 'future_io transport not installed (IO::Async, Future::IO::Impl::IOAsync, DBIO::Async)', 1
    unless $have;

  {
    package T119::FutureIo;
    use base 'DBIO::Test::AsyncHarness';
    __PACKAGE__->harness_env_prefix('DBIO_TEST_PG');
    __PACKAGE__->harness_async_mode('future_io');
    __PACKAGE__->harness_required_modules([qw(
      DBIO::PostgreSQL::Storage::Async IO::Async::Loop Future::IO::Impl::IOAsync
    )]);
    __PACKAGE__->harness_schema_class('T119::FutureIo::Schema');
    sub _tick_loop { IO::Async::Loop->new->loop_once(1); return }

    package T119::FutureIo::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
  }

  my $fh = T119::FutureIo->new(connect_attrs => { pool_size => 2 });
  my $fio = $fh->async;
  for my $case (@CASES) {
    my ($name, $sql, $bind, $leak) = @$case;
    holds_no_value("future_io pooled, $name", failure_of($fh, $fio->_query_async($sql, [@$bind])), $leak);
  }
  $fh->disconnect;
  pass 'the future_io transport was run';
}

done_testing;
