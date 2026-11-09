use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Diff;

# Offline (karr k33, replaced by karr k61): views in the diff.
#
# Introspect lists a view in `tables` (kind => 'view', view_source => the
# text of rdb$view_source) and its columns in `columns`. The diff:
#
#   * writes CREATE VIEW for a view the schema has and the database lacks,
#     DROP VIEW for a view only the database has, and for a view with another
#     definition (whitespace normalised) DROP VIEW before the tables and
#     CREATE VIEW after them (so a column the new definition no longer reads
#     can be dropped);
#   * drops views before it touches the tables, creates them after tables and
#     columns; a view reading another view is dropped before / created after it;
#   * never writes CREATE TABLE / DROP TABLE / ALTER TABLE for a view;
#   * does not refuse a view. It refuses one thing: a name that is a table
#     on one side and a view on the other.

sub col { my ($n, $t, $size) = @_; return { column_name => $n, data_type => $t // 'integer', size => $size, not_null => 0, default_value => undef, is_pk => 0 } }

# model(columns => { name => [cols] }, views => { name => 'SELECT ...' })
sub model {
  my (%m) = @_;
  my %views = %{ $m{views} // {} };
  return {
    tables => {
      ( map { $_ => { table_name => $_, kind => 'table' } } keys %{ $m{columns} } ),
      ( map { $_ => { table_name => $_, kind => 'view', view_source => $views{$_} } } keys %views ),
    },
    columns => { %{ $m{columns} }, map { $_ => [ col('id') ] } keys %views },
    indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}
sub diff { DBIO::Firebird::Diff->new(source => $_[0], target => $_[1]) }

my $base = [ col('id'), col('val', 'varchar', 10) ];
my $sel  = 'SELECT "id" FROM "t"';

# --- a view only the schema has -------------------------------------------------
{
  my $d = diff(model(columns => { t => $base }),
               model(columns => { t => $base }, views => { v => $sel }));
  ok $d->has_changes, 'a new view: reported';
  like $d->summary, qr/^\+ view: v$/m, '... as a view in the summary';
  my $sql = eval { $d->as_sql };
  is $sql, qq{CREATE VIEW "v" AS $sel;}, '... CREATE VIEW with its definition' or diag $@;
  unlike $sql // '', qr/CREATE TABLE/, '... and no CREATE TABLE';
}

# --- a view only the database has -----------------------------------------------
{
  my $d = diff(model(columns => { t => $base }, views => { v => $sel }),
               model(columns => { t => $base }));
  ok $d->has_changes, 'a view the schema lacks: reported';
  is eval { $d->as_sql }, 'DROP VIEW "v";', '... DROP VIEW, not DROP TABLE' or diag $@;
  like $d->summary, qr/^- view: v$/m, '... in the summary';
}

# --- the same view on both sides, spelled with other whitespace -------------------------
{
  my $d = diff(model(columns => { t => $base }, views => { v => $sel }),
               model(columns => { t => $base }, views => { v => "  SELECT \"id\"\n   FROM   \"t\" \n" }));
  ok !$d->has_changes, 'the same definition after whitespace normalisation: no difference';
  is $d->as_sql, '', '... and no statement';
}

# --- a view with another definition ------------------------------------------------------
{
  my $d = diff(model(columns => { t => $base }, views => { v => $sel }),
               model(columns => { t => $base }, views => { v => 'SELECT "id", "val" FROM "t"' }));
  ok $d->has_changes, 'a changed definition: reported';
  is eval { $d->as_sql }, qq{DROP VIEW "v";\nCREATE VIEW "v" AS SELECT "id", "val" FROM "t";}, '... DROP VIEW, then CREATE VIEW' or diag $@;
  like $d->summary, qr/^~ view: v$/m, '... a change in the summary';
  is scalar(grep { $_->isa('DBIO::Firebird::Diff::Column') } @{ $d->operations }), 0, 'no column operation for a view';
}

# --- order: drops first, creates last --------------------------------------------------------
{
  my $d = diff(
    model(columns => { t => $base, gone => [ col('id') ] }, views => { old => $sel }),
    model(columns => { t => $base, extra => [ col('id') ] }, views => { n => 'SELECT "id" FROM "extra"' }));
  my @stmts = map { $_->as_sql } @{ $d->operations };
  my @kinds = map { /^(DROP VIEW|DROP TABLE|CREATE TABLE|CREATE VIEW)/ ? $1 : '?' } @stmts;
  is_deeply \@kinds, ['DROP VIEW', 'CREATE TABLE', 'DROP TABLE', 'CREATE VIEW'],
    'drop views, then the tables, then create views' or diag join "\n", @stmts;
}

# --- a changed view: dropped before the table changes, created after them ---------------------------
{
  my $t_old = [ col('id'), col('c', 'varchar', 10) ];
  my $t_new = [ col('id') ];
  my $d = diff(model(columns => { t => $t_old }, views => { v => 'SELECT "id", "c" FROM "t"' }),
               model(columns => { t => $t_new }, views => { v => 'SELECT "id" FROM "t"' }));
  my @stmts = map { $_->as_sql } @{ $d->operations };
  my @kinds = map { /^(DROP VIEW|ALTER TABLE|CREATE VIEW)/ ? $1 : '?' } @stmts;
  is_deeply \@kinds, ['DROP VIEW', 'ALTER TABLE', 'CREATE VIEW'],
    'a changed view: DROP VIEW, the column drop, CREATE VIEW' or diag join "\n", @stmts;
  unlike join("\n", @stmts), qr/OR ALTER/, '... no CREATE OR ALTER';
  like $d->summary, qr/^~ view: v$/m, '... one change of the view in the summary';
}

# --- views reading views -----------------------------------------------------------------------
{
  my $outer = 'SELECT "id" FROM "a_inner"';
  my $d = diff(model(columns => { t => $base }),
               model(columns => { t => $base }, views => { a_inner => $sel, 'b_outer' => $outer, 'a_outer' => 'SELECT "id" FROM "z_inner"', z_inner => $sel }));
  my @names = map { $_->view_name } grep { $_->isa('DBIO::Firebird::Diff::View') } @{ $d->operations };
  my %at = map { $names[$_] => $_ } 0 .. $#names;
  ok $at{a_inner} < $at{b_outer}, 'created: a view after the view it reads';
  ok $at{z_inner} < $at{a_outer}, '... also against the alphabet';

  my $g = diff(model(columns => { t => $base }, views => { a_inner => $sel, b_outer => $outer }),
               model(columns => { t => $base }));
  my @drop = map { $_->view_name } @{ $g->operations };
  is_deeply \@drop, [ 'b_outer', 'a_inner' ], 'dropped: a view before the view it reads';
}

# --- a table that became a view, and the reverse: the one refusal ------------------------------------
{
  my $d = diff(model(columns => { v => [ col('id') ] }),
               model(columns => {}, views => { v => $sel }));
  ok $d->has_changes, 'a table in the database that is a view in the schema: reported';
  ok !eval { $d->as_sql; 1 }, '... and refused';
  isa_ok $@, 'DBIO::Exception';
  like "$@", qr/table and view/, '... as a kind change';
  like "$@", qr/"v": the database has a table and the schema a view/, '... naming the name';
  my $r = diff(model(columns => {}, views => { v => $sel }), model(columns => { v => [ col('id') ] }));
  ok !eval { $r->as_sql; 1 }, 'a view that is a table in the schema: refused';
  unlike "$@", qr/DROP VIEW|CREATE TABLE/, '... no statement (not even DROP VIEW)' ;
}

# --- no definition in the model: loud, not a broken statement --------------------------------------------
{
  my $d = diff(model(columns => { t => $base }), model(columns => { t => $base }, views => { v => undef }));
  ok !eval { $d->as_sql; 1 }, 'a view without view_source cannot be written';
  like "$@", qr/no definition/, '... and says so';
}

# --- tables are untouched --------------------------------------------------------------
{
  my $d = diff(model(columns => {}), model(columns => { t => $base }));
  like $d->as_sql, qr/CREATE TABLE "t"/, 'a new table is still CREATE TABLE';
}

done_testing;
