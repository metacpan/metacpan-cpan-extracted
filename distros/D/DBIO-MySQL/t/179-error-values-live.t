use strict;
use warnings;
use Test::More;

# LIVE: the text of an error the server raises for a statement with bound values
# holds no value (ADR 0075), on MySQL and on MariaDB, through DBD::mysql and
# DBD::MariaDB, with client side and server side prepare. The server writes the
# offending value into its message (Incorrect integer value: 'x', Duplicate entry
# 'x', near 'x'); the storage takes it out and leaves what a reader needs: the
# type of the error, the column, the key, the number of binds. Every case binds
# the marker `geheim42` (or one of the short and awkward values noted at its
# case) through real DBIO calls and checks the exception for it.
# Works in a database of its own.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;

my $DB = "fw_errv_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
my @schemas;
END {
  local ($@, $?);
  eval { $_->storage->disconnect } for @schemas;
  eval { drop_database() } if $raw;
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}

my $dbd = $dsn =~ /\Adbi:(\w+):/i ? lc $1 : 'mysql';

$raw->do(<<"SQL");
CREATE TABLE `$DB`.fw_item (
  id VARCHAR(40) NOT NULL,
  n INT NULL,
  d DATE NULL,
  dt DATETIME NULL,
  dec_col DECIMAL(5,2) NULL,
  tm TIME NULL,
  u VARCHAR(40) NULL,
  a VARCHAR(40) NULL,
  b VARCHAR(40) NULL,
  s3 VARCHAR(20) CHARACTER SET utf8mb3 NULL,
  PRIMARY KEY (id),
  UNIQUE KEY fw_item_u (u),
  UNIQUE KEY fw_item_ab (a, b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL

my $n = 0;
sub connect_schema {
  my (%attrs) = @_;
  my $class = 'FwErrv::Schema' . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $rc = "$class\::Result::Item";
  eval "package $rc; use DBIO 'Core', -mysql; 1" or die $@;
  $rc->table('fw_item');
  $rc->add_columns(
    id      => { data_type => 'varchar', size => 40 },
    n       => { data_type => 'integer', is_nullable => 1 },
    d       => { data_type => 'date', is_nullable => 1 },
    dt      => { data_type => 'datetime', is_nullable => 1 },
    dec_col => { data_type => 'decimal', size => [5, 2], is_nullable => 1 },
    tm      => { data_type => 'time', is_nullable => 1 },
    u       => { data_type => 'varchar', size => 40, is_nullable => 1 },
    a       => { data_type => 'varchar', size => 40, is_nullable => 1 },
    b       => { data_type => 'varchar', size => 40, is_nullable => 1 },
    s3      => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  $rc->set_primary_key('id');
  $class->register_class(Item => $rc);
  my $schema = $class->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
    ($dbd eq 'mysql' ? (mysql_enable_utf8mb4 => 1) : ()),
    on_connect_do => ["USE `$DB`"],
    %attrs,
  });
  push @schemas, $schema;
  return $schema;
}

sub error_of {
  my ($code) = @_;
  local $@;
  return eval { $code->(); 1 } ? undef : "$@";
}

my $MARKER = 'geheim42';

# One case: the error of $code is a refusal that names its type and what the
# marker was written into, and nothing of the values. The bulk path of populate
# words its message without a statement, so it has no count of binds.
sub refused {
  my ($label, $code, %want) = @_;
  my $err = error_of($code);
  unless (defined $err) {
    fail "$label: the statement was refused";
    return;
  }
  for my $value (@{ $want{absent} }) {
    unlike $err, qr/\Q$value\E/, "$label: no '$value' in the text";
  }
  like $err, $_, "$label: $_" for @{ $want{present} };
  like $err, qr/with \d+ bind values?/, "$label: the number of binds is named"
    unless $want{no_count};
  return $err;
}

for my $mode (qw(client_prepare server_prepare)) {
  my $schema = connect_schema(
    $mode eq 'server_prepare' ? ("${dbd}_server_prepare" => 1) : (),
  );
  my $rs = $schema->resultset('Item');
  $raw->do("DELETE FROM `$DB`.fw_item");
  $rs->create({ id => 'base', u => 'base-u', a => 'base-a', b => 'base-b', n => 1 });
  my $tag = "[$mode]";

  # INT
  refused("$tag int",
    sub { $rs->create({ id => 'i1', n => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Incorrect integer value/, qr/\bn\b/],
  );

  # DATE
  refused("$tag date",
    sub { $rs->create({ id => 'd1', d => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Incorrect date value/, qr/\bd\b/],
  );

  # DATETIME
  refused("$tag datetime",
    sub { $rs->create({ id => 'dt1', dt => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Incorrect datetime value/, qr/\bdt\b/],
  );

  # DECIMAL
  refused("$tag decimal",
    sub { $rs->create({ id => 'c1', dec_col => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Incorrect decimal value/, qr/dec_col/],
  );

  # TIME
  refused("$tag time",
    sub { $rs->create({ id => 't1', tm => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Incorrect time value/, qr/\btm\b/],
  );

  # Duplicate entry, PRIMARY
  $rs->create({ id => $MARKER });
  refused("$tag duplicate primary key",
    sub { $rs->create({ id => $MARKER }) },
    absent  => [$MARKER],
    present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?PRIMARY'/],
  );

  # Duplicate entry, composite unique key
  $rs->create({ id => 'ab1', a => "${MARKER}A", b => "${MARKER}B" });
  refused("$tag duplicate composite key",
    sub { $rs->create({ id => 'ab2', a => "${MARKER}A", b => "${MARKER}B" }) },
    absent  => [$MARKER, "${MARKER}A", "${MARKER}B"],
    present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?fw_item_ab'/],
  );

  # Duplicate entry, single unique key
  $rs->create({ id => 'u1', u => "${MARKER}-u" });
  refused("$tag duplicate unique key",
    sub { $rs->create({ id => 'u2', u => "${MARKER}-u" }) },
    absent  => [$MARKER],
    present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?fw_item_u'/],
  );

  # UPDATE onto a taken key
  my $victim = $rs->create({ id => 'u3', u => 'u3-free' });
  refused("$tag update onto a duplicate key",
    sub { $victim->update({ u => "${MARKER}-u" }) },
    absent  => [$MARKER],
    present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?fw_item_u'/],
  );

  # Syntax error after a bind; a literal of the statement itself stays in the
  # statement behind the message, and the excerpt of the server holds no value
  my $err = refused("$tag syntax error",
    sub { $rs->search(\[ q{id = ? AND BROKEN 'stmtliteral' ((}, $MARKER ])->all },
    absent  => [$MARKER],
    present => [qr/You have an error in your SQL syntax/],
  );
  like $err // '', qr/stmtliteral/, "$tag syntax error: the literal of the statement stays in its placeholder form";
  like $err // '', qr/id = \?/, "$tag syntax error: the statement is in placeholder form";

  # Several rows in one populate
  refused("$tag populate",
    sub {
      $rs->populate([
        { id => 'p1', n => 1 },
        { id => 'p2', n => $MARKER },
      ]);
    },
    absent  => [$MARKER],
    present => [qr/Incorrect integer value/, qr/\bn\b/],
    no_count => 1,
  );
  refused("$tag populate with a duplicate key",
    sub {
      $rs->populate([
        { id => 'p3', u => 'p3-u' },
        { id => 'p4', u => "${MARKER}-u" },
      ]);
    },
    absent  => [$MARKER],
    present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?fw_item_u'/],
    no_count => 1,
  );

  # A value with quotes, a comma, a colon and a line break
  my $awkward = qq{ge'h"e,im:42\nzeile};
  refused("$tag awkward value",
    sub { $rs->create({ id => 'w1', n => $awkward }) },
    absent  => ['im:42', 'zeile', q{ge'h}, 'ge\\\'h'],
    present => [qr/Incorrect integer value/, qr/\bn\b/],
  );

  # Four bytes in a three byte column; the marker is the head of the value
  refused("$tag incorrect string value",
    sub { $rs->create({ id => 's1', s3 => "${MARKER}\x{1F600}" }) },
    absent  => [$MARKER, 'F0', '1F600'],
    present => [$mode eq 'server_prepare'
      ? qr/Incorrect string value|Conversion from collation/
      : (qr/Incorrect string value/, qr/\bs3\b/)],
  );

  # Short values: below the length the base looks for, so the sentences of the
  # engine are what masks them
  $rs->create({ id => '7' });
  refused("$tag short duplicate",
    sub { $rs->create({ id => '7' }) },
    absent  => [],
    present => [qr/Duplicate entry '\*\*\*' for key/],
  );
  my $short = refused("$tag short integer",
    sub { $rs->create({ id => 's2', n => 'ab' }) },
    present => [qr/Incorrect integer value: '\*\*\*' for column/],
  );
  unlike $short // '', qr/value: 'ab'/, "$tag short integer: 'ab' is not quoted";
}

done_testing;
