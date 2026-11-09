use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Diff;
use DBIO::Firebird::Diff::Column;

# Offline (mock models): a column change the Firebird server always refuses is
# refused by the diff, not sent (karr k38).
#
# Until k38 Diff::Column rendered the plain `ALTER ... TYPE` for every
# difference, upgrade died on the statement with the server's own text, and the
# same diff came back on the next run. The rules here were MEASURED against a
# Firebird 5.0.4 server (t/28-diff-column-refused-live.t walks the same
# predicate against the server pair by pair); a change the server accepts
# stays a plain ALTER and is sampled below as hard as the refusals are --
# a refusal of something the server takes would be worse than the error.
#
# What is asserted, per case:
#
#   * the diff still reports the difference (has_changes, summary, operations)
#   * the column op's as_sql dies with a DBIO::Exception naming table, column,
#     old and new type and the reason
#   * Diff->as_sql dies the same way for the whole diff, and lists EVERY
#     refused column at once; it renders no statement of the unrefused ones

sub col {
  my ($name, $type, $size, %more) = @_;
  return { column_name => $name, data_type => $type, size => $size, not_null => 0, %more };
}

sub model {
  my (%m) = @_;
  return {
    tables             => { map { $_ => { table_name => $_, kind => 'table' } } keys %{ $m{columns} } },
    columns            => $m{columns},
    indexes            => $m{indexes} || {},
    unique_constraints => $m{uniques} || {},
    foreign_keys       => $m{fks}     || {},
  };
}

# The one-column diff between two column definitions of table "t".
sub one {
  my ($old, $new, %src) = @_;
  # the primary key stays too (karr k58: a key only one side has is a
  # constraint difference of its own)
  $new = { is_pk => $old->{is_pk}, (exists $old->{pk_position} ? (pk_position => $old->{pk_position}) : ()), %$new }
    if $old->{is_pk} && !$new->{is_pk};
  my $diff = DBIO::Firebird::Diff->new(
    source => model(columns => { t => [ { column_name => 'id', data_type => 'integer', is_pk => 0 }, $old ] }, %src),
    # the indexes and constraints stay: only the column differs (a constraint
    # missing from the target would be a difference of its own, karr k34)
    target => model(columns => { t => [ { column_name => 'id', data_type => 'integer', is_pk => 0 }, $new ] },
      indexes => $src{indexes}, uniques => $src{uniques}, fks => $src{fks}),
  );
  return $diff;
}

sub sql_or_error {
  my ($diff) = @_;
  my $sql = eval { $diff->as_sql };
  return defined $sql ? ($sql, undef) : (undef, $@);
}

# A change that is refused: the diff reports it, SQL generation dies naming it.
sub refused {
  my ($label, $old, $new, $reason_re, %src) = @_;
  my $diff = one($old, $new, %src);

  ok($diff->has_changes, "$label: the difference is reported");
  like($diff->summary, qr/column: t\.c/, "$label: summary lists it");

  my ($sql, $err) = sql_or_error($diff);
  ok(!defined $sql, "$label: as_sql dies") or diag "rendered: $sql";
  isa_ok($err, 'DBIO::Exception', "$label: the error");
  like("$err", qr/"t"\."c"/, "$label: names table and column");
  like("$err", $reason_re, "$label: names the reason");

  my ($op) = grep { $_->column_name eq 'c' } @{ $diff->operations };
  ok(!eval { $op->as_sql; 1 }, "$label: the op refuses on its own, too");
  return "$err";
}

# A change the server accepts: one plain ALTER ... TYPE.
sub accepted {
  my ($label, $old, $new, $expect, %src) = @_;
  my ($sql, $err) = sql_or_error(one($old, $new, %src));
  is($sql, $expect, "$label: stays a plain ALTER") or diag $err;
}

# --- narrowing a character column ---------------------------------------------
{
  my $err = refused('narrow varchar',
    col(c => 'varchar', 150), col(c => 'varchar', 100), qr/narrow/i);
  like($err, qr/varchar\(150\)/, '... old type with its size');
  like($err, qr/varchar\(100\)/, '... new type with its size');

  refused('narrow char',          col(c => 'char', 10),    col(c => 'char', 5),      qr/narrow/i);
  refused('varchar to shorter char', col(c => 'varchar', 20), col(c => 'char', 10),  qr/narrow/i);
  refused('binary to shorter',    col(c => 'varbinary', 20), col(c => 'varchar', 10), qr/narrow/i);

  accepted('widen varchar', col(c => 'varchar', 50), col(c => 'varchar', 100),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(100);');
  accepted('same length, char to varchar', col(c => 'char', 10), col(c => 'varchar', 10),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(10);');
  accepted('widen char', col(c => 'char', 5), col(c => 'char', 20),
    'ALTER TABLE "t" ALTER "c" TYPE char(20);');
}

# --- character to non-character, and conversions the server has none of ------
{
  refused('varchar to integer',  col(c => 'varchar', 10), col(c => 'integer'),            qr/character.*non-character/i);
  refused('char to date',        col(c => 'char', 10),    col(c => 'date'),               qr/character.*non-character/i);
  refused('varchar to numeric',  col(c => 'varchar', 10), col(c => 'numeric', [9, 2]),    qr/character.*non-character/i);
  refused('char to boolean',     col(c => 'char', 5),     col(c => 'boolean'),            qr/boolean/i);
  refused('integer to boolean',  col(c => 'integer'),     col(c => 'boolean'),            qr/boolean/i);
  refused('text blob to varchar', col(c => 'blob sub_type text'), col(c => 'varchar', 100), qr/blob/i);
  refused('varchar to blob',     col(c => 'varchar', 100), col(c => 'blob sub_type text'), qr/blob|character/i);
  refused('blob to text blob',   col(c => 'blob'),        col(c => 'blob sub_type text'), qr/blob/i);

  refused('bigint to integer',   col(c => 'bigint'),   col(c => 'integer'),   qr/BIGINT.*INTEGER|no conversion/i);
  refused('integer to smallint', col(c => 'integer'),  col(c => 'smallint'),  qr/INTEGER.*SMALLINT|no conversion/i);
  refused('date to time',        col(c => 'date'),     col(c => 'time'),      qr/DATE.*TIME|no conversion/i);
  refused('double to float',     col(c => 'double precision'), col(c => 'float'), qr/DOUBLE.*FLOAT|no conversion/i);
  refused('bigint to double',    col(c => 'bigint'),   col(c => 'double precision'), qr/BIGINT.*DOUBLE|no conversion/i);
  refused('integer to float',    col(c => 'integer'),  col(c => 'float'),     qr/INTEGER.*FLOAT|no conversion/i);
  refused('boolean to integer',  col(c => 'boolean'),  col(c => 'integer'),   qr/BOOLEAN.*INTEGER|no conversion/i);
  refused('time to timestamp',   col(c => 'time'),     col(c => 'timestamp'), qr/TIME.*TIMESTAMP|no conversion/i);

  accepted('integer to bigint',  col(c => 'integer'),  col(c => 'bigint'),
    'ALTER TABLE "t" ALTER "c" TYPE bigint;');
  accepted('smallint to double', col(c => 'smallint'), col(c => 'double precision'),
    'ALTER TABLE "t" ALTER "c" TYPE double precision;');
  accepted('float to double',    col(c => 'float'),    col(c => 'double precision'),
    'ALTER TABLE "t" ALTER "c" TYPE double precision;');
  accepted('date to timestamp',  col(c => 'date'),     col(c => 'timestamp'),
    'ALTER TABLE "t" ALTER "c" TYPE timestamp;');
  accepted('timestamp to date',  col(c => 'timestamp'), col(c => 'date'),
    'ALTER TABLE "t" ALTER "c" TYPE date;');
}

# --- a non-character type into a character type that cannot hold its text ----
{
  my $err = refused('integer to varchar(5)', col(c => 'integer'), col(c => 'varchar', 5), qr/at least 11/);
  like($err, qr/integer.*varchar\(5\)/, '... old and new type');

  refused('smallint to char(5)',     col(c => 'smallint'),  col(c => 'char', 5),       qr/at least 6/);
  refused('bigint to varchar(19)',   col(c => 'bigint'),    col(c => 'varchar', 19),   qr/at least 20/);
  refused('date to varchar(9)',      col(c => 'date'),      col(c => 'varchar', 9),    qr/at least 10/);
  refused('timestamp to varchar(24)', col(c => 'timestamp'), col(c => 'varchar', 24),  qr/at least 25/);
  refused('numeric(9,2) to char(11)', col(c => 'numeric', [9, 2]), col(c => 'char', 11), qr/at least 12/);
  refused('decimal(10,2) to char(20)', col(c => 'decimal', [10, 2]), col(c => 'char', 20), qr/at least 21/);
  refused('double to varchar(23)',   col(c => 'double precision'), col(c => 'varchar', 23), qr/at least 24/);

  accepted('integer to varchar(11)', col(c => 'integer'), col(c => 'varchar', 11),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(11);');
  accepted('bigint to varchar(20)',  col(c => 'bigint'),  col(c => 'varchar', 20),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(20);');
  accepted('decimal(10,2) to varchar(21)', col(c => 'decimal', [10, 2]), col(c => 'varchar', 21),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(21);');
}

# --- numeric / decimal -----------------------------------------------------
# The server's rule, measured: the digits before the decimal point
# (precision - scale) must not shrink, and the storage (SMALLINT, INTEGER,
# BIGINT, INT128) must not shrink. Lowering the scale alone is accepted.
{
  my $err = refused('scale up, digits shrink',
    col(c => 'decimal', [10, 2]), col(c => 'decimal', [10, 3]), qr/digits before the decimal point/i);
  like($err, qr/decimal\(10,2\)/, '... old type with its size');
  like($err, qr/decimal\(10,3\)/, '... new type with its size');

  refused('precision down, same scale', col(c => 'decimal', [8, 2]),  col(c => 'decimal', [5, 0]),
    qr/digits before the decimal point/i);
  refused('precision down by one', col(c => 'numeric', [9, 2]), col(c => 'decimal', [8, 2]),
    qr/digits before the decimal point/i);
  refused('storage shrinks, bigint to integer storage', col(c => 'decimal', [10, 2]), col(c => 'decimal', [8, 2]),
    qr/BIGINT.*INTEGER|no conversion/i);
  refused('decimal to integer storage', col(c => 'decimal', [12, 2]), col(c => 'integer'),
    qr/BIGINT.*INTEGER|no conversion/i);

  accepted('scale down', col(c => 'decimal', [10, 2]), col(c => 'decimal', [10, 1]),
    'ALTER TABLE "t" ALTER "c" TYPE decimal(10,1);');
  accepted('precision up', col(c => 'decimal', [10, 2]), col(c => 'decimal', [12, 2]),
    'ALTER TABLE "t" ALTER "c" TYPE decimal(12,2);');
  accepted('scale up with room for the digits', col(c => 'decimal', [8, 2]), col(c => 'decimal', [10, 3]),
    'ALTER TABLE "t" ALTER "c" TYPE decimal(10,3);');
  accepted('numeric to bigint', col(c => 'numeric', [9, 2]), col(c => 'bigint'),
    'ALTER TABLE "t" ALTER "c" TYPE bigint;');
  accepted('integer to decimal(18,2)', col(c => 'integer'), col(c => 'decimal', [18, 2]),
    'ALTER TABLE "t" ALTER "c" TYPE decimal(18,2);');
  accepted('numeric(4,2) to smallint', col(c => 'numeric', [4, 2]), col(c => 'smallint'),
    'ALTER TABLE "t" ALTER "c" TYPE smallint;');
}

# --- a column a constraint uses: no type change at all ---------------------
{
  # Primary key, from the model's is_pk
  my $err = refused('primary key, widening',
    col(c => 'integer', undef, is_pk => 1), col(c => 'bigint'), qr/PRIMARY KEY/);
  like($err, qr/Integrity Constraint|constraint/i, '... says what the server answers');
  refused('primary key, varchar widened',
    col(c => 'varchar', 10, is_pk => 1), col(c => 'varchar', 20), qr/PRIMARY KEY/);

  # UNIQUE constraint of the source model
  refused('unique constraint',
    col(c => 'varchar', 10), col(c => 'varchar', 20), qr/UNIQUE constraint "t_c_uq"/,
    uniques => { t => [ [ t_c_uq => ['c'] ] ] });
  refused('unique constraint, composite',
    col(c => 'integer'), col(c => 'bigint'), qr/UNIQUE constraint "t_cd_uq"/,
    uniques => { t => [ [ t_cd_uq => [qw/d c/] ] ] });

  # foreign key (the referencing column)
  refused('foreign key column',
    col(c => 'integer'), col(c => 'bigint'), qr/FOREIGN KEY/,
    fks => { t => [ { constraint_name => 't_c_fk', from_table => 't', from_columns => ['c'], to_table => 'o', to_columns => ['id'] } ] });

  # Other things about a keyed column are plain: no type change, no refusal
  my ($sql) = sql_or_error(one(
    col(c => 'integer', undef, is_pk => 1, not_null => 1), col(c => 'integer', undef, is_pk => 1, not_null => 1, default_value => '7')));
  is($sql, 'ALTER TABLE "t" ALTER "c" SET DEFAULT 7;', 'a default on a primary-key column is no type change');

  # An ordinary index does not hold the type: the server takes the change
  accepted('plain index column widened', col(c => 'varchar', 10), col(c => 'varchar', 20),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(20);',
    indexes => { t => { t_c_idx => { index_name => 't_c_idx', is_unique => 0, columns => ['c'] } } });
  # A key in ANOTHER table's column of the same name does not count
  accepted('a unique constraint of another table', col(c => 'varchar', 10), col(c => 'varchar', 20),
    'ALTER TABLE "t" ALTER "c" TYPE varchar(20);',
    uniques => { other => [ [ o_c_uq => ['c'] ] ] });
}

# --- the target does not prescribe a size: no opinion ---------------------
{
  my ($sql, $err) = sql_or_error(one(col(c => 'varchar', 50), { column_name => 'c', data_type => 'varchar', not_null => 0 }));
  is($sql, '', 'no size in the target: nothing to change, nothing refused') or diag $err;
  ($sql, $err) = sql_or_error(one(col(c => 'varchar', 50), { column_name => 'c', data_type => 'integer', not_null => 0 }));
  ok(!defined $sql, 'no size in the target, but a character type to integer: refused all the same');
}

# --- not a type change: never refused --------------------------------------
{
  my ($sql) = sql_or_error(one(col(c => 'varchar', 50), col(c => 'varchar', 50, not_null => 1)));
  is($sql, 'ALTER TABLE "t" ALTER "c" SET NOT NULL;', 'nullability is not a type change');
}

# --- a whole diff: everything is listed, nothing is rendered ------------------
{
  my $source = model(columns => {
    t => [ col(a => 'varchar', 150), col(b => 'integer', undef, is_pk => 1), col(c => 'varchar', 10) ],
    u => [ col(x => 'date') ],
  });
  my $target = model(columns => {
    t => [ col(a => 'varchar', 100), col(b => 'bigint', undef, is_pk => 1), col(c => 'varchar', 20), col(d => 'integer') ],
    u => [ col(x => 'time') ],
  });
  my $diff = DBIO::Firebird::Diff->new(source => $source, target => $target);

  ok($diff->has_changes, 'whole diff: the differences are reported');
  is(scalar @{ $diff->operations }, 5, '... all five operations, refused ones included');
  like($diff->summary, qr/column: t\.a.*column: t\.b.*column: t\.c.*column: t\.d.*column: u\.x/s, '... summary lists them all');

  my ($sql, $err) = sql_or_error($diff);
  ok(!defined $sql, 'whole diff: as_sql dies') or diag "rendered: $sql";
  isa_ok($err, 'DBIO::Exception', '... the error');
  like("$err", qr/"t"\."a"/, '... names t.a');
  like("$err", qr/"t"\."b"/, '... names t.b');
  like("$err", qr/"u"\."x"/, '... names u.x');
  unlike("$err", qr/"t"\."c"/, '... and not the column the server takes (t.c widened)');
  unlike("$err", qr/ADD|ALTER TABLE/, '... no statement of the others is rendered');
  like("$err", qr/No statement was (sent|generated)/i, '... says that nothing ran');
}

done_testing;
