use strict;
use warnings;
use Test::More;

# LIVE (ADR 0075 of the core): an error message names keys, columns and
# options, never a value. The server writes the offending value into its text
# (`Duplicate entry '...' for key`, `Incorrect integer value: '...' for column`,
# `Truncated incorrect DOUBLE value: '...'`, a syntax error's `near '...'`);
# the transport takes it out before the exception exists, and what finds the
# cause stays: the type, the column, the key, the SQLSTATE.
#
# One marker as a bind value per form, and for the forms that quote the value
# a short one too (one to three characters), which a text search cannot tell
# from the words around it. Run against MySQL and MariaDB; the shapes of the
# server's own texts differ (MariaDB names `db`.`t`.`c`, MySQL `t.PRIMARY`),
# the assertions do not.
#
# Where the bound value lands: EV::MariaDB prepares the statement on the
# server (prepare -> execute), so a bind never becomes part of the statement
# text -- a syntax error shows the statement with its `?`. Only a literal the
# statement itself holds can be in a `near '...'` excerpt, and the masker takes
# those out as well (cases s1, s2). A refused prepare reaches the Future as the
# server's text alone, without a SQLSTATE (the handle holds no error after a
# failed prepare), so s1 checks the text only.
#
# The table is fw_ev_t in the test database, created here and dropped at the
# end. Gated like the other live tests: DBIO_TEST_MYSQL_DSN, _USER, _PASS.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

$SIG{ALRM} = sub { BAIL_OUT('t/64-error-values-live.t: alarm, a wait did not end') };
alarm 120;

{
  package T64L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

my $T = 'fw_ev_t';

my $h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'T64L::Schema',
  connect_attrs => {
    pool_size     => 1,
    on_connect_do => ['SET NAMES utf8mb4'],
  },
);
my $async = $h->async;

# Runs one statement on the pool, answers the failure ('' when it succeeded).
sub run {
  my ($sql, $bind) = @_;
  my $f = $async->_query_async($sql, $bind || []);
  my @r = eval { $h->await($f) };
  return $@ ? $@ : '';
}

sub ok_run {
  my ($sql, $bind) = @_;
  my $e = run($sql, $bind);
  die "setup failed: $sql: $e" if $e;
}

END { eval { run("DROP TABLE IF EXISTS $T") } if $async }

run("DROP TABLE IF EXISTS $T");
ok_run(<<"SQL");
CREATE TABLE $T (
  id INT NOT NULL PRIMARY KEY,
  i  INT NULL,
  u  VARCHAR(20) NULL,
  v  VARCHAR(3) NULL,
  s  VARCHAR(20) CHARACTER SET ascii NULL,
  w  VARCHAR(20) CHARACTER SET utf8mb4 NULL,
  UNIQUE KEY fw_ev_u (u)
) ENGINE=InnoDB
SQL
ok_run("INSERT INTO $T (id, i, u) VALUES (1, 1, 'taken-one'), (7, 7, 'x'), (987654321, 2, 'y')");

# [ label, sql, binds, [ markers that must be gone ], qr of what must stay ]
my @cases = (
  [ 'duplicate primary key, long value',
    "INSERT INTO $T (id) VALUES (?)", [987654321], ['987654321'],
    qr/Duplicate entry '\*\*\*' for key '(?:\Q$T\E\.)?PRIMARY'/ ],
  [ 'duplicate primary key, short value',
    "INSERT INTO $T (id) VALUES (?)", [7], [q{'7'}],
    qr/Duplicate entry '\*\*\*' for key '(?:\Q$T\E\.)?PRIMARY'/ ],
  [ 'duplicate unique key, string value',
    "INSERT INTO $T (id, u) VALUES (?, ?)", [11, 'taken-one'], ['taken-one'],
    qr/Duplicate entry '\*\*\*' for key '(?:\Q$T\E\.)?fw_ev_u'/ ],
  [ 'duplicate unique key, short string',
    "INSERT INTO $T (id, u) VALUES (?, ?)", [12, 'x'], [q{'x'}],
    qr/Duplicate entry '\*\*\*' for key '(?:\Q$T\E\.)?fw_ev_u'/ ],
  [ 'duplicate entry, literal in the statement',
    "INSERT INTO $T (id) VALUES (987654322), (987654322)", [], ['987654322'],
    qr/Duplicate entry '\*\*\*' for key/ ],
  [ 'incorrect integer value, long',
    "INSERT INTO $T (id, i) VALUES (?, ?)", [21, 'geheim42'], ['geheim42'],
    qr/Incorrect integer value: '\*\*\*' for column .*\bi\b/ ],
  [ 'incorrect integer value, short',
    "INSERT INTO $T (id, i) VALUES (?, ?)", [22, 'ab'], [q{'ab'}],
    qr/Incorrect integer value: '\*\*\*' for column .*\bi\b/ ],
  [ 'incorrect string value',
    "INSERT INTO $T (id, w) VALUES (?, ?)", [23, "ab\xFF\xFEcd"], ["\xFF", '\xFF'],
    qr/(?:Incorrect string value|Invalid utf8mb4 character string): '\*\*\*'/ ],
  [ 'conversion between character sets',
    "INSERT INTO $T (id, s) VALUES (?, ?)", [25, "caf\xC3\xA9"], ["\xC3\xA9", '\xC3'],
    qr/Conversion from collation|Incorrect string value: '\*\*\*'/ ],
  [ 'data too long',
    "INSERT INTO $T (id, v) VALUES (?, ?)", [24, 'geheim42'], ['geheim42'],
    qr/Data too long for column 'v'/ ],
  [ 'truncated incorrect value',
    "UPDATE $T SET i = 1 WHERE i = ?", ['geheim42'], ['geheim42'],
    qr/Truncated incorrect [A-Z]+ value: '\*\*\*'/ ],
  [ 's1: syntax error, bound value',
    "SELEC ? FROM $T", ['geheim42'], ['geheim42'],
    qr/error in your SQL syntax/, 'string' ],
  [ 's2: syntax error, literal behind the failing word',
    "SELECT * FROM $T WHERE u = 'lit-geheim' GARBAGE 'lit-geheim2'", [], ['lit-geheim'],
    qr/error in your SQL syntax/ ],
);

for my $case (@cases) {
  my ($label, $sql, $bind, $markers, $keep, $string_only) = @$case;
  my $err = run($sql, $bind);

  diag "$label: $err" if $ENV{DBIO_TEST_VERBOSE};
  ok length "$err", "$label: the statement fails" or next;
  for my $m (@$markers) {
    my $shown = $m; $shown =~ s/[^\x20-\x7e]/?/g;
    ok index("$err", $m) < 0, "$label: no '$shown' in the message";
  }
  like "$err", $keep, "$label: the type, column or key stays";
  if ($string_only) {
    # A refused prepare reaches the Future as the server's text alone.
    next;
  }
  isa_ok $err, 'DBIO::Exception::Server', "$label: the exception";
  like $err->sqlstate // '', qr/\A[0-9A-Z]{5}\z/, "$label: the SQLSTATE stays";
}

# The same through a transaction: core puts its own words in front, the
# server's text arrives masked.
{
  my $f = $async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async("INSERT INTO $T (id, u) VALUES (?, ?)", [31, 'taken-one']);
  });
  my $err = eval { $h->await($f); 1 } ? '' : $@;
  ok length "$err", 'a transaction with a duplicate fails';
  ok index("$err", 'taken-one') < 0, '... no value in the message';
  like "$err", qr/Duplicate entry '\*\*\*' for key/, '... the key stays';
}

# The pool is healthy after all of them.
{
  my $f = $async->_query_async("SELECT COUNT(*) FROM $T", []);
  my @rows = $h->await($f);
  is $rows[0][0], 3, 'the rows of the table are the ones set up: no failed statement wrote';
}

$h->disconnect;
done_testing;
