use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Column;

# OFFLINE (karr k45, ADR 0012). An identity column used to be invisible to the
# diff in two ways: ADD COLUMN wrote the column without the identity (and Db2
# refused it, SQL0193N), and a difference in is_auto_increment between two
# existing columns was not compared at all, so `upgrade` ended with a diff that
# stayed empty while the table kept its old identity (or lacked it).
#
# What this file claims, all of it what Db2 12.1.5 did when measured (ADR 0012):
#
#   * ADD COLUMN with identity is three statements: the column NOT NULL DEFAULT 0,
#     DROP DEFAULT, SET GENERATED ALWAYS AS IDENTITY -- the only form the server takes;
#   * a changed is_auto_increment is SET GENERATED ALWAYS AS IDENTITY / DROP IDENTITY,
#     after the statements for type, nullability and default that it needs
#     (SET GENERATED needs NOT NULL and no default), DROP IDENTITY before them;
#   * the DROP IDENTITY of a table comes before the SET GENERATED of another column
#     of it -- Db2 allows one identity column per table (SQL0372N);
#   * neither statement leaves the table reorg-pending, so by themselves they
#     ask for no REORG;
#   * what the server refuses (an identity over a type other than SMALLINT, INTEGER,
#     BIGINT or a DECIMAL without scale, over a nullable column, a type change of a
#     column that stays identity) the diff refuses loudly, naming table and column.
#
# The models are in the catalog shape (karr k41): TYPENAME and LENGTH.

sub col {
  my ($name, $type, $size, %rest) = @_;
  return { column_name => $name, catalog_type => $type, catalog_size => $size,
           not_null => 0, %rest };
}

my $ID = col(id => 'INTEGER', 4, not_null => 1, is_pk => 1, pk_position => 1);

sub model {
  my ($columns) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, kind => 'table' } } keys %$columns },
    columns      => $columns,
    indexes      => {},
    foreign_keys => {},
  };
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::DB2::Diff->new(source => model($source), target => model($target));
}

sub sql_lines {
  my ($diff) = @_;
  return [ map { split /\n/, $_->as_sql } @{ $diff->operations } ];
}

my $T = 't1';

# ============================================================================
# 1. ADD COLUMN with identity: three statements, no REORG.
# ============================================================================
{
  my $diff = diff_of(
    { $T => [ $ID ] },
    { $T => [ $ID, col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 1) ] },
  );
  is_deeply sql_lines($diff), [
    'ALTER TABLE "t1" ADD COLUMN "n" INTEGER NOT NULL DEFAULT 0;',
    'ALTER TABLE "t1" ALTER COLUMN "n" DROP DEFAULT;',
    'ALTER TABLE "t1" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;',
  ], 'added identity column: ADD with a default, DROP DEFAULT, SET GENERATED';
  is scalar(grep { ref($_) =~ /Reorg/ } @{ $diff->operations }), 0, 'no REORG for it';

  # The default of the added column is not the model's.
  my $bigint = diff_of(
    { $T => [ $ID ] },
    { $T => [ $ID, col(n => 'BIGINT', 8, not_null => 1, is_auto_increment => 1) ] },
  );
  like sql_lines($bigint)->[0], qr/ADD COLUMN "n" BIGINT NOT NULL DEFAULT 0;/,
    'BIGINT identity';

  my $plain = diff_of(
    { $T => [ $ID ] },
    { $T => [ $ID, col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 0) ] },
  );
  is scalar(@{ sql_lines($plain) }), 1, 'a plain added column stays one statement';
  unlike $plain->as_sql, qr/IDENTITY/, '... without identity';
}

# ============================================================================
# 2. is_auto_increment 0 -> 1 on an existing column.
# ============================================================================
{
  my $plain = col(n => 'INTEGER', 4, not_null => 1);
  my $ident = col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 1);

  my $diff = diff_of({ $T => [ $ID, $plain ] }, { $T => [ $ID, $ident ] });
  is_deeply sql_lines($diff), [
    'ALTER TABLE "t1" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;',
  ], '0 -> 1 is a SET GENERATED, and the diff sees it';
  is scalar(grep { ref($_) =~ /Reorg/ } @{ $diff->operations }), 0, 'no REORG';
  ok $diff->has_changes, 'has_changes';

  # An identity column has no default: the default goes first.
  my $with_default = col(n => 'INTEGER', 4, not_null => 1, catalog_default => '0');
  is_deeply sql_lines(diff_of({ $T => [ $ID, $with_default ] }, { $T => [ $ID, $ident ] })), [
    'ALTER TABLE "t1" ALTER COLUMN "n" DROP DEFAULT;',
    'ALTER TABLE "t1" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;',
  ], 'a column with a default: DROP DEFAULT first';

  # A nullable column is made NOT NULL first, and that is a REORG.
  my $nullable = col(n => 'INTEGER', 4);
  my $diff2 = diff_of({ $T => [ $ID, $nullable ] }, { $T => [ $ID, $ident ] });
  is_deeply sql_lines($diff2), [
    'ALTER TABLE "t1" ALTER COLUMN "n" SET NOT NULL;',
    'ALTER TABLE "t1" ALTER COLUMN "n" SET GENERATED ALWAYS AS IDENTITY;',
    'CALL SYSPROC.ADMIN_CMD(\'REORG TABLE "t1"\');',
  ], 'a nullable column: SET NOT NULL, SET GENERATED, then the REORG of the NOT NULL';

  # A type change in the same breath comes before the identity.
  my $small = col(n => 'SMALLINT', 2, not_null => 1);
  is_deeply sql_lines(diff_of({ $T => [ $ID, $small ] }, { $T => [ $ID, $ident ] }))->[0],
    'ALTER TABLE "t1" ALTER COLUMN "n" SET DATA TYPE INTEGER;',
    'SET DATA TYPE before SET GENERATED';

  # Not a difference: undef and 0 are both "no identity".
  is scalar(@{ diff_of({ $T => [ $ID, $plain ] },
    { $T => [ $ID, col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 0) ] })->operations }),
    0, 'undef against 0 is no difference';
  is scalar(@{ diff_of({ $T => [ $ID, $ident ] }, { $T => [ $ID, $ident ] })->operations }),
    0, 'identity on both sides is no difference';
}

# ============================================================================
# 3. is_auto_increment 1 -> 0.
# ============================================================================
{
  my $plain = col(n => 'INTEGER', 4, not_null => 1);
  my $ident = col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 1);

  my $diff = diff_of({ $T => [ $ID, $ident ] }, { $T => [ $ID, $plain ] });
  is_deeply sql_lines($diff), [
    'ALTER TABLE "t1" ALTER COLUMN "n" DROP IDENTITY;',
  ], '1 -> 0 is a DROP IDENTITY';
  is scalar(grep { ref($_) =~ /Reorg/ } @{ $diff->operations }), 0, 'no REORG';

  my $target_default = col(n => 'INTEGER', 4, not_null => 1, catalog_default => '7');
  is_deeply sql_lines(diff_of({ $T => [ $ID, $ident ] }, { $T => [ $ID, $target_default ] })), [
    'ALTER TABLE "t1" ALTER COLUMN "n" DROP IDENTITY;',
    'ALTER TABLE "t1" ALTER COLUMN "n" SET DEFAULT 7;',
  ], 'DROP IDENTITY, then the default the target has';

  # A column that gets nullable at the same time: DROP IDENTITY first.
  my $nullable = col(n => 'INTEGER', 4);
  is_deeply sql_lines(diff_of({ $T => [ $ID, $ident ] }, { $T => [ $ID, $nullable ] }))->[0],
    'ALTER TABLE "t1" ALTER COLUMN "n" DROP IDENTITY;', 'DROP IDENTITY leads';
}

# ============================================================================
# 4. The identity moves between two columns of a table: one per table.
# ============================================================================
{
  my $ident = sub { col($_[0], 'INTEGER', 4, not_null => 1, is_auto_increment => 1) };
  my $plain = sub { col($_[0], 'INTEGER', 4, not_null => 1) };
  my $diff = diff_of(
    { $T => [ $ID, $plain->('a'), $ident->('z') ] },
    { $T => [ $ID, $ident->('a'), $plain->('z') ] },
  );
  is_deeply sql_lines($diff), [
    'ALTER TABLE "t1" ALTER COLUMN "z" DROP IDENTITY;',
    'ALTER TABLE "t1" ALTER COLUMN "a" SET GENERATED ALWAYS AS IDENTITY;',
  ], 'the DROP IDENTITY of z precedes the SET GENERATED of a';

  my $dropped = diff_of(
    { $T => [ $ID, $ident->('z') ] },
    { $T => [ $ID, $ident->('a') ] },
  );
  my $lines = sql_lines($dropped);
  like $lines->[0], qr/DROP COLUMN "z"/, 'the dropped identity column goes before the added one';
  like join("\n", @$lines), qr/ADD COLUMN "a" INTEGER NOT NULL DEFAULT 0/, '... which is added';
}

# ============================================================================
# 5. reorg_recommended: the identity statements alone ask for none.
# ============================================================================
{
  my $plain = col(n => 'INTEGER', 4, not_null => 1);
  my $ident = col(n => 'INTEGER', 4, not_null => 1, is_auto_increment => 1);
  my ($up)   = DBIO::DB2::Diff::Column->diff({ $T => [ $plain ] }, { $T => [ $ident ] },
                 { $T => {} }, { $T => {} });
  my ($down) = DBIO::DB2::Diff::Column->diff({ $T => [ $ident ] }, { $T => [ $plain ] },
                 { $T => {} }, { $T => {} });
  my ($add)  = DBIO::DB2::Diff::Column->diff({ $T => [] }, { $T => [ $ident ] },
                 { $T => {} }, { $T => {} });
  ok !$up->reorg_recommended,   'SET GENERATED: no REORG';
  ok !$down->reorg_recommended, 'DROP IDENTITY: no REORG';
  ok !$add->reorg_recommended,  'ADD identity column: no REORG';
}

# ============================================================================
# 6. Allowed types.
# ============================================================================
{
  for my $t (['SMALLINT', 2], ['INTEGER', 4], ['BIGINT', 8], ['DECIMAL', '10'], ['DECIMAL', '10,0']) {
    my $ident = col(n => $t->[0], $t->[1], not_null => 1, is_auto_increment => 1);
    my $plain = col(n => $t->[0], $t->[1], not_null => 1);
    lives_ok { diff_of({ $T => [ $plain ] }, { $T => [ $ident ] })->operations }
      "$t->[0]($t->[1]) can be an identity";
  }
}

# ============================================================================
# 7. What the server refuses, the diff refuses: table and column named.
# ============================================================================
{
  my $named = qr/\bt1\b.*\bn\b|\bn\b.*\bt1\b/s;
  for my $t (['DECIMAL', '10,2'], ['VARCHAR', 20], ['DOUBLE', 8], ['DATE', 4]) {
    my $ident = col(n => $t->[0], $t->[1], not_null => 1, is_auto_increment => 1);
    my $plain = col(n => $t->[0], $t->[1], not_null => 1);
    throws_ok { diff_of({ $T => [ $plain ] }, { $T => [ $ident ] })->operations }
      qr/identity.*(?:$t->[0])|(?:$t->[0]).*identity/si, "set: $t->[0]($t->[1]) refused";
    throws_ok { diff_of({ $T => [ $plain ] }, { $T => [ $ident ] })->operations }
      $named, '... naming table and column';
    throws_ok { diff_of({ $T => [ $ID ] }, { $T => [ $ID, $ident ] })->operations }
      $named, "add: $t->[0]($t->[1]) refused, table and column named";
  }

  my $nullable_ident = col(n => 'INTEGER', 4, is_auto_increment => 1);
  throws_ok { diff_of({ $T => [ $ID, col(n => 'INTEGER', 4) ] },
                      { $T => [ $ID, $nullable_ident ] })->operations }
    qr/NOT NULL/, 'an identity column must be NOT NULL';

  # The type of a column that stays identity: SQL0270N on the server.
  my $small = col(n => 'SMALLINT', 2, not_null => 1, is_auto_increment => 1);
  my $int   = col(n => 'INTEGER',  4, not_null => 1, is_auto_increment => 1);
  throws_ok { diff_of({ $T => [ $ID, $small ] }, { $T => [ $ID, $int ] })->operations }
    $named, 'a type change of a column that stays identity is refused, named';
  throws_ok { diff_of({ $T => [ $ID, $small ] }, { $T => [ $ID, $int ] })->operations }
    qr/identity/i, '... as an identity matter';

  # Going away from identity may change the type.
  lives_ok { diff_of({ $T => [ $ID, $small ] },
    { $T => [ $ID, col(n => 'INTEGER', 4, not_null => 1) ] })->operations }
    'DROP IDENTITY with a type change is not refused';
}

done_testing;
