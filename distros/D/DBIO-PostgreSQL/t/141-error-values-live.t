use strict;
use warnings;
use utf8;
use Test::More;

# LIVE test: no value a statement was run with is in the text of the error the
# server answers with, whatever form the server writes it in (ADR 0075).
#
# WHY: the server quotes the value it refused -- in the primary text
# (invalid input syntax for type integer: "..."), in DETAIL (Key (a)=(...),
# Failing row contains (...), Token "..." is invalid), in CONTEXT (the bound
# parameter, a JSON excerpt) -- and DBD::Pg hands that text to the exception
# the caller logs, shows or sends on. A message names keys, columns and types,
# never values. t/140-mask-error-values.t holds the rules of
# DBIO::PostgreSQL::Util on text taken from this server; only a live server
# tells whether the text it writes today is still one of those forms, and
# whether the storage's hook (_mask_error_values) is what it passes through.
#
# One table of cases, run three ways:
#   hook   through $storage->_dbh_execute: the storage knows the values that
#          were bound (core masks them whole, the driver masks the forms)
#   raw    through the database handle (prepare, execute): the storage knows
#          no values, so only the forms of the text can mask them
#   async  over the future_io transport: the values of the statement stand at
#          its handle while it is in flight (ADR 0044 holds: not longer), so
#          the transport masks them as the hook does, then the forms
# Each case checks that the marker (the value, or the piece the server quotes
# of it) is gone from the whole text -- not as a beginning, not as a piece --
# and that the type, column, constraint, table and the count of the bound
# values stay. A literal in the statement itself is statement text: it stays in
# the "LINE n:" excerpt and in the [for Statement ...] of the message.
#
# The parameter of CONTEXT is written $1 = '***' where the forms mask it and
# $1 = *** where core's hook did it first (it takes the quoted form whole);
# both name the parameter and show no value.
#
# How to read a failure. The diag line carries the whole text. "leaks" names the
# piece found; "lost" the form that was expected to stay. A case that fails
# "leaks" only in the raw or async way is a form of the text Util does not
# know yet; one that fails in all three is a form nobody masks.
#
# A case of the names kind is one where the value stands in the text as a NAME
# (relation "x" does not exist): which word of a text is a value and which a
# name is not in the text, so only the bound values tell. It runs the hook way
# and the async way, which both know the values of the statement, and not the
# raw way, which does not.
#
# The async way also holds that no value stays at the connection once a
# statement is over, whether it succeeded, failed at the send or failed in the
# result (the last block of the file).
#
# Works in a schema of its own, dbio_fehlerwerte_live, and drops it. The
# session sets log_parameter_max_length_on_error = -1 so that the server writes
# the bound parameters into CONTEXT whatever its configuration says.

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

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $S = 'dbio_fehlerwerte_live';

my @on_connect = (
  'SET log_parameter_max_length_on_error = -1',
  "SET search_path = $S",
);

# the first connection has no schema yet to set a search_path to
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
  q{CREATE TYPE mood AS ENUM ('sad','ok')},
  q{CREATE TYPE pt AS (a int, b text)},
  q{CREATE TABLE t (id int primary key, i int, si smallint, bi bigint, n numeric(3,1),
      d date, ts timestamp, tm time, iv interval, u uuid, b boolean, j json, jb jsonb,
      ba bytea, m mood, arr int[], r pt, ip inet, cx char(2), vc varchar(5),
      tz timestamptz, f float8, tr tsrange, ti tsvector, nn int not null default 1,
      chk int check (chk > 0), ma macaddr, mo money, bits bit(3), cidr cidr,
      pt point, o oid, ya int4range, ch1 "char", tx text)},
  q{CREATE TABLE c2 (a int, b text, primary key (a, b))},
  q{CREATE TABLE fk (x int, y text, foreign key (x, y) references c2 (a, b))},
  q{CREATE TABLE ex (r int4range, exclude using gist (r with &&))},
  q{CREATE TABLE pp (k int, v text) PARTITION BY LIST (k)},
  q{CREATE TABLE pp1 PARTITION OF pp FOR VALUES IN (1)},
  q{CREATE TABLE u2 (e text unique, f text, unique (e, f))},
  q{INSERT INTO t (id) VALUES (1)},
  q{INSERT INTO c2 VALUES (5, 'geheim42'), (6, 'other')},
  q{INSERT INTO u2 VALUES ('geheim42', 'zz'), ('ab', 'zz')},
  q{INSERT INTO ex VALUES ('[1,3)')},
);

# A value with the characters the server does not escape in a message.
my $odd = qq{ge'he"im, 4:2\nzeile};
my @odd = ('he"im', '4:2', 'zeile', q{ge'he}, q{ge''he});

# --- the cases ---------------------------------------------------------------
# name, sql, binds, and
#   gone      pieces that must not be in the text: a string, or a regex
#   keep      forms that must stay: a regex
#   names     a case the raw way cannot hold (the value is a NAME in the text)
# A bound value of four characters or more is gone as a string; the short ones
# are written out as the quoted forms the server writes them in.

sub ins { sprintf 'INSERT INTO t (id,%s) VALUES (2,?)', shift }

my $G = 'geheim42';
my @cases = (
  # --- the primary text and CONTEXT: numbers
  { name => 'integer', sql => ins('i'), bind => [$G], gone => [$G, 'geheim'],
    keep => [qr/type integer: "\*\*\*"/, qr/\$1 = '?\*\*\*'?/] },
  { name => 'integer, short value', sql => ins('i'), bind => ['x'], gone => [qr/["']x["']/],
    keep => [qr/type integer: "\*\*\*"/, qr/\$1 = '?\*\*\*'?/] },
  { name => 'integer, value with quote, double quote, comma, colon, line break',
    sql => ins('i'), bind => [$odd], gone => \@odd,
    keep => [qr/type integer: "\*\*\*"/, qr/\$1 = '?\*\*\*'?/] },
  { name => 'integer in WHERE', sql => 'SELECT 1 FROM t WHERE i = ?', bind => [$G],
    gone => [$G], keep => [qr/type integer/] },
  { name => 'integer by CAST', sql => 'SELECT CAST(? AS INTEGER)', bind => [$G],
    gone => [$G], keep => [qr/type integer/] },
  { name => 'integer out of range', sql => ins('i'), bind => ['3000000000'],
    gone => ['3000000000'], keep => [qr/value "\*\*\*" is out of range for type integer/] },
  { name => 'bigint out of range', sql => ins('bi'), bind => ['99999999999999999999'],
    gone => ['99999999999999999999'], keep => [qr/value "\*\*\*" is out of range for type bigint/] },
  { name => 'smallint out of range', sql => ins('si'), bind => ['70000'],
    gone => ['70000'], keep => [qr/value "\*\*\*" is out of range for type smallint/] },
  { name => 'numeric field overflow', sql => ins('n'), bind => ['99999'],
    gone => ['99999'], keep => [qr/numeric field overflow/, qr/precision 3, scale 1/, qr/\$1 = '?\*\*\*'?/] },
  { name => 'numeric', sql => ins('n'), bind => [$G], gone => [$G],
    keep => [qr/type numeric: "\*\*\*"/] },
  { name => 'double precision', sql => ins('f'), bind => [$G], gone => [$G],
    keep => [qr/type double precision: "\*\*\*"/] },
  { name => 'money', sql => ins('mo'), bind => [$G], gone => [$G], keep => [qr/type money: "\*\*\*"/] },
  { name => 'oid', sql => ins('o'), bind => [$G], gone => [$G], keep => [qr/type oid: "\*\*\*"/] },

  # --- dates and times
  { name => 'date', sql => ins('d'), bind => ['geheimdate'], gone => ['geheimdate', 'geheim'],
    keep => [qr/type date: "\*\*\*"/] },
  { name => 'date, short value', sql => ins('d'), bind => ['9'], gone => [qr/["']9["']/],
    keep => [qr/type date: "\*\*\*"/] },
  { name => 'date out of range', sql => ins('d'), bind => ['31337-99-99'], gone => ['31337-99-99'],
    keep => [qr/date\/time field value out of range: "\*\*\*"/, qr/HINT:  Perhaps you need a different "DateStyle" setting\./] },
  { name => 'timestamp', sql => ins('ts'), bind => ['geheimts'], gone => ['geheimts'],
    keep => [qr/type timestamp: "\*\*\*"/] },
  { name => 'timestamp out of range', sql => ins('ts'), bind => ['2024-13-45 99:99:99'],
    gone => ['2024-13-45', '99:99:99'], keep => [qr/field value out of range: "\*\*\*"/] },
  { name => 'timestamp with time zone', sql => ins('tz'), bind => ['geheimtz'], gone => ['geheimtz'],
    keep => [qr/type timestamp with time zone: "\*\*\*"/] },
  { name => 'time', sql => ins('tm'), bind => ['geheimtime'], gone => ['geheimtime'],
    keep => [qr/type time: "\*\*\*"/] },
  { name => 'time out of range', sql => ins('tm'), bind => ['25:61:61'], gone => ['25:61:61'],
    keep => [qr/field value out of range: "\*\*\*"/] },
  { name => 'interval', sql => ins('iv'), bind => ['geheimiv'], gone => ['geheimiv'],
    keep => [qr/type interval: "\*\*\*"/] },
  { name => 'to_date format', sql => 'SELECT to_date(?, ?)', bind => ['geheimdatum', 'YYYY-MM-DD'],
    gone => ['geheimdatum', 'gehe'], keep => [qr/invalid value "\*\*\*" for "YYYY"/, qr/DETAIL:  Value must be an integer\./] },
  { name => 'to_timestamp format', sql => 'SELECT to_timestamp(?, ?)', bind => ['geheimts', 'YYYY-MM-DD'],
    gone => ['geheimts', 'gehe'], keep => [qr/invalid value "\*\*\*" for "YYYY"/] },
  { name => 'time zone', sql => 'SELECT now() AT TIME ZONE ?', bind => ['geheimzone'],
    gone => ['geheimzone'], keep => [qr/time zone "\*\*\*" not recognized/] },

  # --- other scalar types
  { name => 'uuid', sql => ins('u'), bind => ['geheimuuid'], gone => ['geheimuuid'],
    keep => [qr/type uuid: "\*\*\*"/] },
  { name => 'boolean', sql => ins('b'), bind => ['geheimbool'], gone => ['geheimbool'],
    keep => [qr/type boolean: "\*\*\*"/] },
  { name => 'boolean, short value', sql => ins('b'), bind => ['x'], gone => [qr/["']x["']/],
    keep => [qr/type boolean: "\*\*\*"/] },
  { name => 'enum', sql => ins('m'), bind => [$G], gone => [$G],
    keep => [qr/invalid input value for enum mood: "\*\*\*"/] },
  { name => 'enum, short value', sql => ins('m'), bind => ['x'], gone => [qr/["']x["']/],
    keep => [qr/invalid input value for enum mood: "\*\*\*"/] },
  { name => 'inet', sql => ins('ip'), bind => [$G], gone => [$G], keep => [qr/type inet: "\*\*\*"/] },
  { name => 'cidr', sql => ins('cidr'), bind => [$G], gone => [$G], keep => [qr/type cidr: "\*\*\*"/] },
  { name => 'macaddr', sql => ins('ma'), bind => [$G], gone => [$G], keep => [qr/type macaddr: "\*\*\*"/] },
  { name => 'point', sql => ins('pt'), bind => [$G], gone => [$G], keep => [qr/type point: "\*\*\*"/] },
  { name => 'bit', sql => ins('bits'), bind => [$G], gone => [$G, qr/"g"/],
    keep => [qr/"\*\*\*" is not a valid binary digit/] },
  { name => 'bit length', sql => ins('bits'), bind => ['1010101'], gone => ['1010101'],
    keep => [qr/bit string length 7 does not match type bit\(3\)/] },
  { name => 'bytea', sql => 'INSERT INTO t (id,ba) VALUES (2,?::text::bytea)', bind => ['\\xZZgeheim'],
    gone => ['ZZgeheim', 'geheim', qr/"Z"/], keep => [qr/invalid hexadecimal digit: "\*\*\*"/] },
  { name => 'bytea by decode', sql => q{INSERT INTO t (id,ba) VALUES (2,decode(?,'hex'))}, bind => [$G],
    gone => [$G, qr/"g"/], keep => [qr/invalid hexadecimal digit: "\*\*\*"/] },
  { name => 'char too long', sql => ins('cx'), bind => [$G], gone => [$G],
    keep => [qr/value too long for type character\(2\)/] },
  { name => 'varchar too long', sql => ins('vc'), bind => [$G], gone => [$G],
    keep => [qr/value too long for type character varying\(5\)/] },
  { name => 'invalid UTF-8 by convert_from', sql => q{SELECT convert_from(decode(?,'hex'),'UTF8')},
    bind => ['c328'], gone => [qr/0x[0-9a-f]{2}/i, 'c328'],
    keep => [qr/invalid byte sequence for encoding "UTF8": \*\*\*/] },
  { name => 'invalid UTF-8 beside a value', sql => q{INSERT INTO t (id,vc) VALUES (2,convert_from(decode(?,'hex'),'UTF8'))},
    bind => ['ff41geheim'], gone => ['geheim', 'ff41'], keep => [qr/invalid hexadecimal digit: "\*\*\*"/] },
  { name => 'encoding name', sql => q{SELECT convert_to('a', ?)}, bind => ['geheimenc'],
    gone => ['geheimenc'], keep => [qr/encoding name "\*\*\*"/] },

  # --- composite values
  { name => 'array, not an array', sql => ins('arr'), bind => [$G], gone => [$G],
    keep => [qr/malformed array literal: "\*\*\*"/, qr/DETAIL:  Array value must start with "\{" or dimension information\./] },
  { name => 'array, a bad element', sql => ins('arr'), bind => ['{1,geheim42}'], gone => [$G, '{1,'],
    keep => [qr/type integer: "\*\*\*"/] },
  { name => 'array, short value', sql => ins('arr'), bind => ['{a}'], gone => ['{a}', qr/["']a["']/],
    keep => [qr/type integer: "\*\*\*"/] },
  { name => 'record', sql => ins('r'), bind => [$G], gone => [$G],
    keep => [qr/malformed record literal: "\*\*\*"/, qr/DETAIL:  Missing left parenthesis\./] },
  { name => 'record, a bad field', sql => ins('r'), bind => ['(geheim42,x)'], gone => [$G, '(geheim'],
    keep => [qr/type integer: "\*\*\*"/] },
  { name => 'record, too many columns', sql => ins('r'), bind => ['(1,x,geheim42)'], gone => [$G],
    keep => [qr/malformed record literal: "\*\*\*"/, qr/DETAIL:  Too many columns\./] },
  { name => 'range', sql => ins('tr'), bind => [$G], gone => [$G],
    keep => [qr/malformed range literal: "\*\*\*"/, qr/DETAIL:  Missing left parenthesis or bracket\./] },
  { name => 'range, bounds', sql => ins('ya'), bind => ['[5,1)'], gone => ['[5,1)'],
    keep => [qr/range lower bound must be less than or equal to range upper bound/] },
  { name => 'range, a bad bound', sql => ins('ya'), bind => ['[geheim42,1)'], gone => [$G],
    keep => [qr/type integer: "\*\*\*"/] },
  { name => 'tsvector', sql => ins('ti'), bind => ["'geheim42"], gone => [$G],
    keep => [qr/syntax error in tsvector: "\*\*\*"/] },
  { name => 'tsquery', sql => 'SELECT to_tsquery(?)', bind => ['geheim42 &'], gone => [$G],
    keep => [qr/no operand in tsquery: "\*\*\*"/] },

  # --- JSON, XML
  { name => 'json, a token', sql => ins('j'), bind => ['{"a":geheim42}'], gone => [$G, 'geheim'],
    keep => [qr/type json/, qr/DETAIL:  Token "\*\*\*" is invalid\./, qr/CONTEXT:  JSON data, line 1: \*\*\*/] },
  { name => 'json, a bare token', sql => ins('j'), bind => [$G], gone => [$G],
    keep => [qr/DETAIL:  Token "\*\*\*" is invalid\./] },
  { name => 'jsonb, an expected token', sql => ins('jb'), bind => ['{"a":"geheim42",}'], gone => [$G],
    keep => [qr/type json/, qr/DETAIL:  Expected string, but found "\*\*\*"\./] },
  { name => 'jsonb, a line break', sql => ins('jb'), bind => [qq{{"a":\n geheim42}}], gone => [$G],
    keep => [qr/DETAIL:  Token "\*\*\*" is invalid\./, qr/JSON data, line 2: \*\*\*/] },
  { name => 'json, short value', sql => ins('j'), bind => ['{x}'], gone => ['{x}', qr/["']x["']/],
    keep => [qr/DETAIL:  Token "\*\*\*" is invalid\./] },
  { name => 'json, an escape sequence', sql => ins('j'), bind => ['"geheim\\q"'], gone => [$G, '\\q'],
    keep => [qr/Escape sequence "\*\*\*" is invalid\./] },
  { name => 'jsonpath', sql => 'SELECT ?::jsonpath', bind => ['$.geheim42 ??'], gone => [$G],
    keep => [qr/syntax error at or near "\*\*\*" of jsonpath input/] },
  { name => 'jsonpath at the end', sql => q{SELECT jsonb_path_query('{}', ?::jsonpath)}, bind => [$G],
    gone => [$G], keep => [qr/syntax error at end of jsonpath input/] },
  { name => 'xml', sql => 'SELECT xmlparse(document ?)', bind => ['<a>geheim42'], gone => [$G],
    keep => [qr/invalid XML document/, qr/DETAIL:  line 1: \*\*\*/] },

  # --- constraints: DETAIL
  { name => 'unique', sql => 'INSERT INTO u2 (e,f) VALUES (?,?)', bind => [$G, 'zz'],
    gone => [$G], keep => [qr/unique constraint "u2_e_key"/, qr/DETAIL:  Key \(e\)=\(\*\*\*\) already exists\./],
    constraint => 'u2_e_key', table => 'u2' },
  { name => 'unique, short value', sql => 'INSERT INTO u2 (e,f) VALUES (?,?)', bind => ['ab', 'zz'],
    gone => [qr/\(ab\)/, qr/'ab'/], keep => [qr/DETAIL:  Key \(e\)=\(\*\*\*\) already exists\./],
    constraint => 'u2_e_key' },
  { name => 'primary key, short value', sql => 'INSERT INTO t (id) VALUES (?)', bind => [1],
    gone => [qr/=\(1\)/, qr/\$1 = '1'/], keep => [qr/unique constraint "t_pkey"/, qr/Key \(id\)=\(\*\*\*\) already exists\./],
    constraint => 't_pkey' },
  { name => 'composite primary key', sql => 'INSERT INTO c2 (a,b) VALUES (?,?)', bind => [5, $G],
    gone => [$G, qr/\(5, /], keep => [qr/unique constraint "c2_pkey"/, qr/Key \(a, b\)=\(\*\*\*\) already exists\./],
    constraint => 'c2_pkey', table => 'c2' },
  { name => 'foreign key', sql => 'INSERT INTO fk (x,y) VALUES (?,?)', bind => [9, $G],
    gone => [$G, qr/\(9, /], keep => [qr/foreign key constraint "fk_x_y_fkey"/, qr/Key \(x, y\)=\(\*\*\*\) is not present in table "c2"\./],
    constraint => 'fk_x_y_fkey', table => 'fk' },
  { name => 'check', sql => ins('chk'), bind => ['-123456'], gone => ['-123456'],
    keep => [qr/check constraint "t_chk_check"/, qr/DETAIL:  Failing row contains \(\*\*\*\)\./],
    constraint => 't_chk_check', table => 't' },
  { name => 'not null', sql => ins('nn'), bind => [undef],
    gone => [qr/Failing row contains \((?!\*\*\*\))/], keep => [qr/null value in column "nn" of relation "t" violates not-null constraint/, qr/DETAIL:  Failing row contains \(\*\*\*\)\./],
    table => 't' },
  { name => 'update of a key', sql => 'UPDATE c2 SET a = 5, b = ? WHERE a = 6', bind => [$G],
    gone => [$G], keep => [qr/unique constraint "c2_pkey"/, qr/Key \(a, b\)=\(\*\*\*\) already exists\./],
    constraint => 'c2_pkey' },
  { name => 'several rows in one statement', sql => 'INSERT INTO t (id,i) VALUES (2,?),(3,?)', bind => [1, $G],
    gone => [$G], keep => [qr/type integer: "\*\*\*"/, qr/\$2 = '?\*\*\*'?/] },
  { name => 'several parameters in the context', sql => 'INSERT INTO t (id,i,tx) VALUES (2,?,?)', bind => [$G, 'zweiter wert'],
    gone => [$G, 'zweiter wert'], keep => [qr/type integer: "\*\*\*"/, qr/\$1 = '?\*\*\*'?/] },
  { name => 'exclusion', sql => 'INSERT INTO ex (r) VALUES (?)', bind => ['[1,5)'],
    gone => ['[1,5)', '[1,3)'], keep => [qr/exclusion constraint "ex_r_excl"/, qr/Key \(r\)=\(\*\*\*\) conflicts with existing key \(r\)=\(\*\*\*\)\./],
    constraint => 'ex_r_excl' },
  { name => 'partition', sql => 'INSERT INTO pp (k,v) VALUES (?,?)', bind => [7, $G],
    gone => [$G, qr/\) = \(7\)/, qr/\$1 = '7'/], keep => [qr/no partition of relation "pp" found for row/, qr/Partition key of the failing row contains \(k\) = \(\*\*\*\)\./] },

  # --- the value is a name in the text: only the bound values say it is a value
  { name => 'regclass', sql => 'SELECT ?::regclass', bind => [$G], gone => [$G],
    keep => [qr/relation "\*\*\*" does not exist/], names => 1 },
  { name => 'regrole', sql => 'SELECT ?::regrole', bind => [$G], gone => [$G],
    keep => [qr/role "\*\*\*" does not exist/], names => 1 },
  { name => 'regtype', sql => 'SELECT ?::regtype', bind => [$G], gone => [$G],
    keep => [qr/type "\*\*\*" does not exist/], names => 1 },
  { name => 'regproc', sql => 'SELECT ?::regproc', bind => [$G], gone => [$G],
    keep => [qr/function "\*\*\*" does not exist/], names => 1 },
  { name => 'text search configuration', sql => q{SELECT to_tsvector(?, 'a')}, bind => ['geheimcfg'],
    gone => ['geheimcfg'], keep => [qr/text search configuration "\*\*\*" does not exist/], names => 1 },
  { name => 'configuration parameter', sql => q{SELECT set_config(?, 'x', false)}, bind => ['geheim.42'],
    gone => ['geheim.42'], keep => [qr/invalid configuration parameter name "\*\*\*"/], names => 1 },

  # --- texts with no value in them, and the statement's own literal
  { name => 'division by zero', sql => 'SELECT 1/?::int', bind => ['0'],
    gone => [], keep => [qr/division by zero/] },
  { name => 'regular expression', sql => 'SELECT ? ~ ?', bind => ['x', '(geheim'],
    gone => ['(geheim'], keep => [qr/invalid regular expression: parentheses \(\) not balanced/] },
  { name => 'a syntax error keeps its excerpt', sql => 'INSERT INTO t (id,i) VALUES (2,?,)', bind => [$G],
    gone => [$G], keep => [qr/syntax error at or near "\)"/, qr/LINE 1: INSERT INTO t \(id,i\) VALUES \(2,\$1,\)/] },
  { name => 'a literal of the statement', sql => q{INSERT INTO t (id,i) VALUES (2,'litwert')}, bind => [],
    gone => [], keep => [qr/type integer: "\*\*\*"/, qr/LINE 1: .*'litwert'/],
    keep_sync => [qr/\[for Statement "[^"]*'litwert'[^"]*"/] },
  { name => 'a literal of the statement beside a bound value', sql => q{INSERT INTO t (id,i,d) VALUES (2,'litwert',?)},
    bind => [$G], gone => [$G], keep => [qr/type integer: "\*\*\*"/, qr/LINE 1: .*'litwert'/],
    keep_sync => [qr/\[for Statement "[^"]*'litwert'[^"]*"/] },
  { name => 'a function the statement names', sql => 'SELECT geheim42(?)', bind => ['x'],
    gone => [], keep => [qr/function geheim42\(unknown\) does not exist/, qr/LINE 1: SELECT geheim42\(\$1\)/] },
  { name => 'a column the statement names', sql => 'SELECT geheim42 FROM t WHERE i=?', bind => ['x'],
    gone => [], keep => [qr/column "geheim42" does not exist/] },
);

# --- the checks --------------------------------------------------------------

sub is_gone {
  my ($text, $piece) = @_;
  return ref $piece ? $text =~ $piece : index($text, $piece) >= 0;
}

sub check_text {
  my ($way, $case, $text) = @_;
  my $name = "$way: $case->{name}";

  my @leaks = grep { is_gone($text, $_) } @{ $case->{gone} };
  ok !@leaks, "$name: no value in the text"
    or diag 'leaks: ' . join(', ', map { ref $_ ? "$_" : "'$_'" } @leaks) . "\nthe text:\n$text";

  # the [for Statement ...] is DBI's, on the sync way only
  my @lost = grep { $text !~ $_ }
    @{ $case->{keep} }, ($way eq 'async' ? () : @{ $case->{keep_sync} || [] });
  ok !@lost, "$name: type, column, constraint, table and the rest of the text stay"
    or diag 'lost: ' . join(', ', map "$_", @lost) . "\nthe text:\n$text";
}

# --- the storage, the way core runs a statement ------------------------------
my $schema  = DBIO::Test::Schema->connect($dsn, $user, $pass,
  { AutoCommit => 1, on_connect_do => [@on_connect] });
my $storage = $schema->storage;
my $dbh     = $storage->dbh;   # connects; driver resolved from here on
isa_ok $storage, 'DBIO::PostgreSQL::Storage', 'the storage, once connected';

sub failure_of {
  my ($code) = @_;
  my $ok = eval { $code->(); 1 };
  return $ok ? undef : $@;
}

for my $way (qw( hook raw )) {
  for my $case (@cases) {
    my @bind = @{ $case->{bind} };
    next if $way eq 'raw' and $case->{names};

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
    my $name = "$way: $case->{name}";

    ok defined $err, "$name: the server refuses" or next;
    my $text = "$err";
    check_text($way, $case, $text);

    ok Scalar::Util::blessed($err) && $err->isa('DBIO::Exception::Server'),
      "$name: a DBIO::Exception::Server" or next;

    my $detail = $err->detail // '';
    my @leaks = grep { is_gone($detail, $_) } @{ $case->{gone} };
    ok !@leaks, "$name: no value in the detail field"
      or diag "detail: $detail";
    is $err->constraint, $case->{constraint}, "$name: the constraint field" if exists $case->{constraint};
    is $err->table, $case->{table}, "$name: the table field" if exists $case->{table};

    my $n = @bind;
    like $text, qr/\[for Statement "[^\n]*" with \Q$n\E bind values?\]/,
      "$name: the count of the bound values stays";
  }
}

is $dbh->selectrow_array("SELECT count(*) FROM $S.c2"), 2, 'the connection is usable after the refusals';

# --- the future_io transport: no binds held, the forms alone -------------------
my $async_schema = DBIO::Test::Schema->connect($dsn, $user, $pass,
  { async => 'future_io', on_connect_do => [@on_connect] });
my $async = $async_schema->storage->async;

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

for my $case (@cases) {
  my $err = async_failure_of($async->_query_async($case->{sql}, [ @{ $case->{bind} } ]));
  my $name = "async: $case->{name}";
  ok defined $err && !ref $err, "$name: the server refuses, with a plain string" or next;
  check_text('async', $case, $err);
}

is_deeply [ $async->_query_async('SELECT ?::int', [ 7 ])->get ], [ [ 7 ] ],
  'after all of it the next statement runs';

# --- the pinned connection of a transaction: the same text ---------------------
for my $case (grep { $_->{names} } @cases) {
  my $err;
  my $f = $async->txn_do_async(sub {
    my ($txn) = @_;
    return $async->_query_async_pinned($txn->txn_conn, $async->_transform_sql($case->{sql}),
      [ @{ $case->{bind} } ]);
  });
  $err = async_failure_of($f);
  my $name = "async, in a transaction: $case->{name}";
  ok defined $err && !ref $err, "$name: the server refuses, with a plain string" or next;
  check_text('async', $case, $err);
}

# --- no value stays at the connection after a statement ----------------------
# The values stand at the handle for the error text; once the statement is over
# -- done, failed in the result, failed at the send -- neither the handle nor
# the connection's statement handle holds them (ADR 0044).
{
  my $conn = $async->_create_pool_connection({
    dsn => $dsn, user => $user, password => $pass, attrs => { },
  });
  my $dbh = $conn->{dbh};
  $dbh->do($_) for @on_connect;

  my $holds = sub {
    my @where;
    push @where, 'the handle' if defined $dbh->{private_dbio_binds};
    push @where, 'the statement handle' if $conn->{sth};
    return join ', ', @where;
  };
  my $run = sub {
    my ($sql, $bind) = @_;
    my $ok = eval {
      $async->_submit_query($conn, $sql, $bind);
      $async->_await_readable($conn)->then(sub { $async->_collect_result($conn) })->get;
      1;
    };
    return $ok ? undef : $@;
  };

  my $err = $run->('SELECT $1::regclass', [$G]);
  ok defined $err, 'a failing statement with a bound value: the server refuses';
  unlike $err, qr/\Q$G\E/, '... and the text has no value';
  is $holds->(), '', '... and no value stays at the connection after the failure';

  $err = $run->('SELECT $1::int, $2::int', [$G]);
  ok defined $err, 'a statement the send refuses (too few values)';
  unlike $err, qr/\Q$G\E/, '... and the text has no value';
  is $holds->(), '', '... and no value stays at the connection after the failure at the send';

  is_deeply [ $run->('SELECT $1::text', [$G]) // 'ok' ], ['ok'], 'a statement that succeeds';
  is $holds->(), '', '... and no value stays at the connection after it';

  $err = $run->('SELECT $1::regclass', [$G]);
  is $run->('SELECT 1', []), undef, 'the next statement, with no value, runs';
  # the statement without values keeps its own handle (a COMMIT's is read
  # afterwards), and that one holds no parameter
  ok !defined $dbh->{private_dbio_binds} && !keys %{ $conn->{sth}{ParamValues} || {} },
    '... and the connection holds no value';
  $async->_shutdown_pool_connection($conn);
}

$async->disconnect;
$schema->storage->disconnect;
{
  local $SIG{__WARN__} = sub { };
  $control->do("DROP SCHEMA IF EXISTS $S CASCADE");
}

done_testing;
