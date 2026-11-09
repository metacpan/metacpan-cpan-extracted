use strict;
use warnings;
use Test::More;

# Live: the column changes the diff refuses are the ones the server refuses
# (karr k38).
#
# Diff::Column::refusal is a model of the server's rules, and a model of
# somebody else's behaviour is only worth what it was checked against. Two
# halves, both needing a server:
#
#   1. Every ordered pair of a spread of column types is tried with a plain
#      `ALTER TABLE ... ALTER ... TYPE` on an empty table, and the driver's
#      answer must be the server's: refusal() says "refuse" exactly where the
#      server errors. A refusal of something the server takes would be worse
#      than the server's error -- it would withhold a change that works -- so
#      this direction is asserted as hard as the other. (The pairs were also
#      measured on tables with rows; the answer did not differ.)
#
#   2. Columns of a real table, read back through DBIO::Firebird::Introspect
#      so the constraint information is the live model's: a PRIMARY KEY, a
#      UNIQUE constraint and a FOREIGN KEY column are refused for ANY type
#      change (the server's "Cannot update index segment used by an Integrity
#      Constraint"), an ordinary index and a UNIQUE INDEX are not. For each
#      refused one the raw ALTER is sent to the server as well to show that it
#      really refuses; the data is still there; the diff still reports the
#      difference afterwards.
#
# Skipped unless a DSN is provided (as t/15, t/17, t/19):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the tables "k38_probe", "k38_parent" and "k38_key".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live refused-column-change test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Diff;
use DBIO::Firebird::Diff::Column;
use DBIO::Firebird::Introspect;

my $dbh = DBI->connect($dsn, $user, $pass, {
  RaiseError => 0, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;

cleanup();

# Model info of a column, from the DDL spelling of its type.
sub info_of {
  my ($ddl) = @_;
  $ddl =~ s/^varchar(\(\d+\)) character set octets$/varbinary$1/;
  my ($type, $args) = $ddl =~ /^([a-z_ ]+?)\s*(?:\(([\d,]+)\))?$/ or die "cannot parse $ddl";
  my @args = defined $args ? split(/,/, $args) : ();
  return {
    column_name => 'c', data_type => $type, not_null => 0,
    size => (@args > 1 ? [@args] : @args ? $args[0] : undef),
  };
}

# --- 1. every pair of types ---------------------------------------------------
my @types = (
  'smallint', 'integer', 'bigint', 'numeric(4,2)', 'numeric(9,2)', 'decimal(8,2)',
  'decimal(10,2)', 'decimal(10,3)', 'decimal(12,2)', 'decimal(18,2)',
  'float', 'double precision', 'char(5)', 'varchar(10)', 'varchar(20)',
  'date', 'time', 'timestamp', 'boolean', 'blob sub_type text',
);

my %mismatch;
my ($pairs, $server_refused) = (0, 0);

for my $from (@types) {
  for my $to (@types, 'varchar(5)', 'varchar(9)', 'varchar(10) character set octets') {
    next if $from eq $to;
    my $verdict = probe($from, $to) or next;
    $pairs++;
    $server_refused++ if $verdict->{server};
    $mismatch{"$from -> $to"} = $verdict
      if ($verdict->{server} ? 1 : 0) != ($verdict->{driver} ? 1 : 0);
  }
}

# The text-length boundaries, where the server counts characters of the text
# of a value: one below the limit is refused, the limit is taken.
for my $pair (
  [ 'integer', 'varchar(10)' ], [ 'integer', 'varchar(11)' ],
  [ 'smallint', 'char(5)' ], [ 'smallint', 'char(6)' ],
  [ 'bigint', 'varchar(19)' ], [ 'bigint', 'varchar(20)' ],
  [ 'numeric(9,2)', 'char(11)' ], [ 'numeric(9,2)', 'char(12)' ],
  [ 'date', 'varchar(9)' ], [ 'date', 'varchar(10)' ],
  [ 'time', 'varchar(12)' ], [ 'time', 'varchar(13)' ],
  [ 'timestamp', 'varchar(24)' ], [ 'timestamp', 'varchar(25)' ],
  [ 'float', 'char(14)' ], [ 'float', 'char(15)' ],
  [ 'double precision', 'char(23)' ], [ 'double precision', 'char(24)' ],
) {
  my ($from, $to) = @$pair;
  my $verdict = probe($from, $to) or next;
  $pairs++;
  $server_refused++ if $verdict->{server};
  $mismatch{"$from -> $to"} = $verdict
    if ($verdict->{server} ? 1 : 0) != ($verdict->{driver} ? 1 : 0);
}

cmp_ok($pairs, '>', 300, "$pairs type pairs were tried on the server ($server_refused refused by it)");
cmp_ok($server_refused, '>', 0, '... and the server does refuse some of them');
is_deeply(\%mismatch, {}, 'the driver refuses a type change exactly where the server does')
  or diag join "\n", map {
    sprintf '%s: server %s, driver %s', $_,
      $mismatch{$_}{server} ? 'refused' : 'took it',
      $mismatch{$_}{driver} ? "refused ($mismatch{$_}{driver})" : 'took it';
  } sort keys %mismatch;

# One table per probe: create it with the old type, ask the server for the
# change, ask the driver, drop the table.
sub probe {
  my ($from, $to) = @_;
  $dbh->do('DROP TABLE "k38_probe"');
  $dbh->do(qq{CREATE TABLE "k38_probe" ("id" INTEGER NOT NULL, "c" $from)})
    or return diag("cannot create a $from column: " . $dbh->errstr);

  my $took = $dbh->do(qq{ALTER TABLE "k38_probe" ALTER "c" TYPE $to});
  $dbh->do('DROP TABLE "k38_probe"');

  my $op = DBIO::Firebird::Diff::Column->new(
    action => 'alter', table_name => 'k38_probe', column_name => 'c',
    old_info => info_of($from), new_info => info_of($to),
  );
  return { server => !$took, driver => scalar $op->refusal };
}

# --- 2. columns of real tables ----------------------------------------------
my $parent_ok = $dbh->do('CREATE TABLE "k38_parent" ("id" INTEGER NOT NULL PRIMARY KEY, "name" VARCHAR(10))');
ok($parent_ok, 'a parent table to reference') or diag $dbh->errstr;

$dbh->do(<<'DDL') or BAIL_OUT('cannot create the test table: ' . $dbh->errstr);
CREATE TABLE "k38_key" (
  "pk"     INTEGER NOT NULL,
  "uq"     VARCHAR(10),
  "fk"     INTEGER,
  "ix"     VARCHAR(10),
  "uix"    VARCHAR(10),
  "plain"  VARCHAR(10),
  CONSTRAINT "k38_key_pk" PRIMARY KEY ("pk"),
  CONSTRAINT "k38_key_uq" UNIQUE ("uq"),
  CONSTRAINT "k38_key_fk" FOREIGN KEY ("fk") REFERENCES "k38_parent" ("id")
)
DDL
$dbh->do('CREATE INDEX "k38_key_ix" ON "k38_key" ("ix")');
$dbh->do('CREATE UNIQUE INDEX "k38_key_uix" ON "k38_key" ("uix")');
$dbh->do(q{INSERT INTO "k38_parent" ("id", "name") VALUES (1, 'one')});
$dbh->do(q{INSERT INTO "k38_key" ("pk", "uq", "fk", "ix", "uix", "plain") VALUES (1, 'u', 1, 'i', 'x', 'p')});

my $live = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;

# The target model: the live one with one column changed.
sub target_with {
  my ($column, %change) = @_;
  my $target = { %$live, columns => { %{ $live->{columns} } } };
  $target->{columns}{k38_key} = [
    map { $_->{column_name} eq $column ? { %$_, %change } : $_ } @{ $live->{columns}{k38_key} }
  ];
  return DBIO::Firebird::Diff->new(source => $live, target => $target);
}

my %widen = (
  pk => { data_type => 'bigint',  size => undef },
  fk => { data_type => 'bigint',  size => undef },
  uq => { data_type => 'varchar', size => 20 },
);

for my $column (qw/pk uq fk/) {
  my $diff = target_with($column, %{ $widen{$column} });

  ok($diff->has_changes, "$column: a widened key column is reported");
  my $err = eval { $diff->as_sql; 1 } ? '' : $@;
  isa_ok($err, 'DBIO::Exception', "$column: as_sql dies with");
  like("$err", qr/"k38_key"\."$column"/, "$column: ... naming table and column");
  like("$err", qr/PRIMARY KEY|UNIQUE constraint|FOREIGN KEY/, "$column: ... and the constraint");

  # The raw statement, to show that the server really does refuse it.
  my $type = $widen{$column}{data_type} . ($widen{$column}{size} ? "($widen{$column}{size})" : '');
  ok(!$dbh->do(qq{ALTER TABLE "k38_key" ALTER "$column" TYPE $type}), "$column: the server refuses the same change")
    and like($dbh->errstr, qr/Integrity Constraint/i, "$column: ... as a constraint's index segment");
}

# Not a key: the server takes the change, and so does the driver.
for my $column (qw/ix uix plain/) {
  my $diff = target_with($column, size => 20);
  my $sql  = eval { $diff->as_sql };
  is($sql, qq{ALTER TABLE "k38_key" ALTER "$column" TYPE varchar(20);}, "$column: widened by a plain ALTER")
    or diag $@;
  ok($dbh->do($sql), "$column: ... that the server accepts") or diag $dbh->errstr;
}

# Nothing changed in what the refusals held back.
is_deeply(
  $dbh->selectrow_arrayref(q{SELECT "pk", "uq", "fk" FROM "k38_key"}), [ 1, 'u', 1 ],
  'the rows of the refused columns are as they were',
);

# The difference is still reported for the three that were refused.
my $after = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;
my $diff  = DBIO::Firebird::Diff->new(source => $after, target => do {
  my $target = { %$after, columns => { %{ $after->{columns} } } };
  $target->{columns}{k38_key} = [
    map { my $c = $_;
      my $w = $widen{ $c->{column_name} };
      $w ? { %$c, %$w } : $c } @{ $after->{columns}{k38_key} }
  ];
  $target;
});
my @cols = sort map { $_->column_name } grep { $_->isa('DBIO::Firebird::Diff::Column') } @{ $diff->operations };
is_deeply(\@cols, [qw/fk pk uq/], 'after the refusals the three differences are still reported');

cleanup();
$dbh->disconnect;

done_testing;

sub cleanup {
  $dbh->do($_) for 'DROP TABLE "k38_key"', 'DROP TABLE "k38_parent"', 'DROP TABLE "k38_probe"';
  return;
}
