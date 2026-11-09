use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Test::Conformance ();
use DBIO::Oracle::Test::Conformance ();

# LIVE. The text Oracle 23ai writes into an error holds the value of the
# statement, also when it was a bind: ORA-03302 (invalid string value), ORA-03301
# (the key of the row of ORA-00001), ORA-01438, ORA-61800, ORA-01428, and the
# first character of a string in ORA-01722. The family's rule is that an error
# names keys, columns and options, never values. Every form the server has is
# provoked here through the DBIO API (a ResultSet, populate, insert_bulk; never
# raw DBI) with a marker value, and with a short one where the form quotes it
# whatever its length.
#
# Per case the exception must not hold the value, and must still hold what
# finds the cause: the ORA code, the column, the table, the constraint, the
# count of bind values; a literal written into the statement itself stays.
#
# The tables are FW_*, made here and dropped at the end, also after a failure.

plan skip_all => 'DBIO_TEST_ORA_DSN not set (no Oracle to run against)'
  unless length($ENV{DBIO_TEST_ORA_DSN} // '');

my @connect = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
my $dbh = DBI->connect(@connect, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my ($version) = $dbh->selectrow_array(q{SELECT version FROM product_component_version WHERE product LIKE 'Oracle%' FETCH FIRST 1 ROW ONLY});
my ($major) = ($version // '') =~ /^(\d+)/;
$major //= 0;

my @TABLES = qw(FW_P FW_K FW_D FW_B);
my $drop = sub {
  for my $t (@TABLES) { eval { $dbh->do(qq{DROP TABLE "$t" PURGE}) } }
};
$drop->();
END { local $@; eval { $drop->() } if $dbh }

my $ver = $major >= 23;
$dbh->do($_) for (
  q{CREATE TABLE "FW_P" ("id" NUMBER(10) NOT NULL, "email" VARCHAR2(100), "ch" VARCHAR2(10),
      CONSTRAINT "FW_P_PK" PRIMARY KEY ("id"), CONSTRAINT "FW_P_UQ" UNIQUE ("email"))},
  q{CREATE TABLE "FW_K" ("a" NUMBER(10) NOT NULL, "b" VARCHAR2(50) NOT NULL,
      CONSTRAINT "FW_K_PK" PRIMARY KEY ("a", "b"))},
  q{CREATE TABLE "FW_D" ("big" NUMBER(4,1), "tiny" NUMBER(1,0))},
  ( $ver ? q{CREATE TABLE "FW_B" ("b" BOOLEAN)} : () ),
);

my $col = sub { +{ data_type => 'varchar2', size => 100, is_nullable => 1 } };
my $num = sub { +{ data_type => 'integer', is_nullable => 0 } };
my $class = DBIO::Test::Conformance->_build_schema_class({ name => 'fw101', input => { sources => [
  { name => 'P', table => 'FW_P', columns => [ id => $num->(), email => $col->(), ch => $col->() ],
    primary_key => ['id'], unique => [ [ FW_P_UQ => ['email'] ] ] },
  { name => 'K', table => 'FW_K', columns => [ a => $num->(), b => { data_type => 'varchar2', size => 100, is_nullable => 0 } ], primary_key => [qw(a b)] },
  { name => 'D', table => 'FW_D', columns => [
      big  => { data_type => 'numeric', size => [4, 1], is_nullable => 1 },
      tiny => { data_type => 'numeric', size => [1, 0], is_nullable => 1 } ] },
  ( $ver ? { name => 'B', table => 'FW_B', columns => [ b => { data_type => 'boolean', is_nullable => 1 } ] } : () ),
] } });
my $schema = DBIO::Oracle::Test::Conformance->conformance_connect($class);

my $M    = 'geheim42';
my $ODD  = qq{a'b"c, d:e\nf\@x.y};
my $TRIK = 'x, b:y';

$schema->resultset('P')->populate([
  [qw(id email ch)],
  [ 1,         "$M\@x.y", 'c' ],
  [ 2,         'ab',      'c' ],
  [ 7,         $ODD,      'c' ],
  [ 4242,      'k@x.y',   'c' ],
  [ 987654321, 'z@x.y',   'c' ],
]);
$schema->resultset('K')->populate([ [qw(a b)], [ 4242, $M ], [ 7, 'ab' ], [ 1, $TRIK ] ]);

my $err = sub { my $c = shift; return eval { $c->(); 1 } ? '' : "$@" };

# [ name, code, \@must_not_hold, \@must_hold ]
my $BINDS = qr/with \d+ bind values?\]/;
my @case = (
  [ 'ORA-01722 WHERE, marker',
    sub { $schema->resultset('P')->search({ -and => [ { id => $M }, \q{"ch" = 'lit_keep'} ] })->all },
    [ $M, qr/containing 'g'/ ],
    [ qr/ORA-01722/, qr/ORA-03302/, qr/invalid string value: \*\*\*/, qr/containing '\*\*\*'/, qr/"ch" = 'lit_keep'/, qr/with 1 bind value\]/ ] ],
  [ 'ORA-01722 WHERE, short',
    sub { $schema->resultset('P')->search({ id => 'ab' })->all },
    [ qr/containing 'a'/, qr/string value: ab/ ],
    [ qr/ORA-01722/, qr/invalid string value: \*\*\*/, $BINDS ] ],
  [ 'ORA-01722 INSERT, marker',
    sub { $schema->resultset('P')->create({ id => $M }) },
    [ $M, qr/containing 'g'/ ],
    [ qr/ORA-01722/, qr/invalid string value: \*\*\*/, qr/INSERT INTO "FW_P"/, $BINDS ] ],
  [ 'ORA-01722 INSERT, short',
    sub { $schema->resultset('P')->create({ id => 'ab' }) },
    [ qr/containing 'a'/, qr/string value: ab/ ],
    [ qr/ORA-01722/, qr/invalid string value: \*\*\*/, $BINDS ] ],
  [ 'ORA-01722 with quote, double quote, comma, colon, newline',
    sub { $schema->resultset('P')->create({ id => $ODD }) },
    [ qr/a'b/, qr/d:e/, qr/f\@x\.y/, qr/containing 'a'/ ],
    [ qr/ORA-01722/, qr/invalid string value: \*\*\*/, $BINDS ] ],

  [ 'ORA-00001 primary key (number), long',
    sub { $schema->resultset('P')->create({ id => 987654321 }) },
    [ qr/987654321/ ],
    [ qr/ORA-00001/, qr/unique constraint \(\S*\) violated on table \S*FW_P columns \(id\)/, qr/\(id:\*\*\*\) already exists/, $BINDS ] ],
  [ 'ORA-00001 primary key (number), short',
    sub { $schema->resultset('P')->create({ id => 7 }) },
    [ qr/id:7\b/ ],
    [ qr/ORA-00001/, qr/columns \(id\)/, qr/\(id:\*\*\*\) already exists/, $BINDS ] ],
  [ 'ORA-00001 unique (string), marker',
    sub { $schema->resultset('P')->create({ id => 100, email => "$M\@x.y" }) },
    [ $M ],
    [ qr/ORA-00001/, qr/FW_P_UQ/, qr/columns \(email\)/, qr/\(email:\*\*\*\) already exists/, $BINDS ] ],
  [ 'ORA-00001 unique (string), short',
    sub { $schema->resultset('P')->create({ id => 101, email => 'ab' }) },
    [ qr/email:'ab'/, qr/email:ab/ ],
    [ qr/ORA-00001/, qr/FW_P_UQ/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'ORA-00001 unique (string) with quote, double quote, comma, colon, newline',
    sub { $schema->resultset('P')->create({ id => 102, email => $ODD }) },
    [ qr/a'b/, qr/d:e/, qr/f\@x\.y/ ],
    [ qr/ORA-00001/, qr/FW_P_UQ/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'ORA-00001 composite key, marker',
    sub { $schema->resultset('K')->create({ a => 4242, b => $M }) },
    [ $M, qr/4242/ ],
    [ qr/ORA-00001/, qr/FW_K_PK/, qr/FW_K columns \(a, b\)/, qr/\(a:\*\*\*, b:\*\*\*\) already exists/ ],
  ],
  [ 'ORA-00001 composite key, short',
    sub { $schema->resultset('K')->create({ a => 7, b => 'ab' }) },
    [ qr/a:7\b/, qr/b:'ab'/ ],
    [ qr/ORA-00001/, qr/FW_K_PK/, qr/\(a:\*\*\*, b:\*\*\*\) already exists/ ],
  ],
  [ 'ORA-00001 composite key whose value holds ", b:"',
    sub { $schema->resultset('K')->create({ a => 1, b => $TRIK }) },
    [ qr/x, b:y/, qr/b:'x/ ],
    [ qr/ORA-00001/, qr/FW_K_PK/, qr/already exists/ ],
  ],
  [ 'ORA-00001 UPDATE of a key, long',
    sub { $schema->resultset('P')->search({ id => 1 })->update({ id => 4242 }) },
    [ qr/4242/ ],
    [ qr/ORA-00001/, qr/FW_P_PK|SYS_C/, qr/\(id:\*\*\*\) already exists/, qr/UPDATE "FW_P"/, $BINDS ] ],
  [ 'ORA-00001 UPDATE of a key, short',
    sub { $schema->resultset('P')->search({ id => 2 })->update({ id => 7 }) },
    [ qr/id:7\b/ ],
    [ qr/ORA-00001/, qr/\(id:\*\*\*\) already exists/, qr/UPDATE "FW_P"/ ],
  ],

  [ 'ORA-01438, long value',
    sub { $schema->resultset('D')->create({ big => 99999.9 }) },
    [ qr/99999\.9/ ],
    [ qr/ORA-01438/, qr/value \*\*\* greater than specified precision \(4, 1\) for column/, qr/"big"/, qr/FW_D/ ],
  ],
  [ 'ORA-01438, short value',
    sub { $schema->resultset('D')->create({ tiny => 77 }) },
    [ qr/value 77\b/ ],
    [ qr/ORA-01438/, qr/value \*\*\* greater than specified precision \(1, 0\) for column/, qr/"tiny"/ ],
  ],

  ( $ver ? (
  [ 'ORA-61800 BOOLEAN, marker',
    sub { $schema->resultset('B')->create({ b => $M }) },
    [ $M ],
    [ qr/ORA-61800/, qr/invalid boolean literal: \*\*\*/, $BINDS ] ],
  [ 'ORA-61800 BOOLEAN, short',
    sub { $schema->resultset('B')->create({ b => 'ab' }) },
    [ qr/literal: ab/ ],
    [ qr/ORA-61800/, qr/invalid boolean literal: \*\*\*/ ] ],
  ) : () ),

  [ 'ORA-01428, short argument',
    sub { $schema->resultset('P')->search(\[ 'ASIN(?) > 0', [ {} => 3 ] ])->all },
    [ qr/Argument 3\b/ ],
    [ qr/ORA-01428/, qr/Argument \*\*\* is out of range/, qr/ASIN\(\?\)/ ],
  ],
  [ 'ORA-01428, long argument',
    sub { $schema->resultset('P')->search(\[ 'ASIN(?) > 0', [ {} => -4000.5 ] ])->all },
    [ qr/4000\.5/ ],
    [ qr/ORA-01428/, qr/Argument \*\*\* is out of range/ ],
  ],

  [ 'populate, several rows, marker (void: one array execution)',
    sub { $schema->resultset('P')->populate([ { id => 200, email => 'f1@x.y' }, { id => 201, email => "$M\@x.y" } ]); return },
    [ $M ],
    [ qr/ORA-00001/, qr/FW_P_UQ/, qr/\(email:\*\*\*\) already exists/, qr/row 2 of the populate data/ ],
  ],
  [ 'populate, several rows, short (void)',
    sub { $schema->resultset('P')->populate([ { id => 202, email => 'f2@x.y' }, { id => 203, email => 'ab' } ]); return },
    [ qr/email:'?ab/ ],
    [ qr/ORA-00001/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'populate, several rows, numeric key (void)',
    sub { $schema->resultset('P')->populate([ { id => 204, email => 'f3@x.y' }, { id => 4242, email => 'f4@x.y' } ]); return },
    [ qr/4242/ ],
    [ qr/ORA-00001/, qr/\(id:\*\*\*\) already exists/ ],
  ],
  [ 'populate, several rows, value with quote, comma, colon, newline (void)',
    sub { $schema->resultset('P')->populate([ { id => 205, email => 'f5@x.y' }, { id => 206, email => $ODD } ]); return },
    [ qr/a'b/, qr/d:e/, qr/f\@x\.y\b(?<!f5\@x\.y)/ ],
    [ qr/ORA-00001/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'populate, several rows with a wrong type, marker (void)',
    sub { $schema->resultset('P')->populate([ { id => 207, email => 'f6@x.y' }, { id => $M, email => 'f7@x.y' } ]); return },
    [ $M, qr/containing 'g'/ ],
    [ qr/ORA-01722/, qr/invalid string value: \*\*\*/ ],
  ],
  [ 'populate in list context (row by row)',
    sub { my @rows = $schema->resultset('P')->populate([ { id => 208, email => 'f8@x.y' }, { id => 209, email => "$M\@x.y" } ]) },
    [ $M ],
    [ qr/ORA-00001/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'insert_bulk, marker',
    sub {
      my $source = $schema->source('P');
      $schema->storage->insert_bulk($source, [qw(id email)], [ [ 210, 'f9@x.y' ], [ 211, "$M\@x.y" ] ]);
    },
    [ $M ],
    [ qr/ORA-00001/, qr/\(email:\*\*\*\) already exists/ ],
  ],
  [ 'insert_bulk, short',
    sub {
      my $source = $schema->source('P');
      $schema->storage->insert_bulk($source, [qw(id email)], [ [ 212, 'fa@x.y' ], [ 213, 'ab' ] ]);
    },
    [ qr/email:'?ab/ ],
    [ qr/ORA-00001/, qr/\(email:\*\*\*\) already exists/ ],
  ],
);

for my $c (@case) {
  my ($name, $code, $absent, $present) = @$c;
  my $e = $err->($code);
  ok length $e, "$name: refused" or next;
  for my $re (@$absent) {
    my $label = ref $re ? "$re" : "'$re'";
    unlike $e, ref $re ? $re : qr/\Q$re\E/, "$name: does not hold $label";
  }
  for my $re (@$present) {
    like $e, ref $re ? $re : qr/\Q$re\E/, "$name: still holds " . (ref $re ? "$re" : "'$re'");
  }
  if ($ENV{FW_SHOW}) { (my $l = $e) =~ s/\n/ ⏎ /g; $l =~ s/^.*?(ORA-)/$1/; $l =~ s/ \[for Statement.*//s; $l =~ s/Help: \S+ //; diag "FORM $name => $l" }
}

$schema->storage->disconnect;
$drop->();
my ($left) = $dbh->selectrow_array(q{SELECT COUNT(*) FROM user_tables WHERE table_name LIKE 'FW\_%' ESCAPE '\'});
is $left, 0, 'the FW_ tables are dropped again';

done_testing;
