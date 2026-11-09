use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;

# karr k77. Names follow the collation of the database. Measured live
# (t/110-diff-collation-live.t, 2026-10-25, MSSQL 2022): in a database whose
# collation is case-insensitive (SQL_Latin1_General_CP1_CI_AS, also the server
# default and tempdb) CREATE TABLE foo next to Foo, a second column id next to
# Id, a second index ixa on one table and a constraint pk_foo next to PK_Foo
# are all refused as duplicates; in a _CS_ database every one of them is
# accepted. The introspect reads the collation of the live database into the
# model; the diff then compares the names of the live side's spelling:
# a change of spelling alone is no change when the collation ignores case, and
# stays a change (drop and create, as before) when it does not.
#
# This file pins the diff and the model field offline.

sub col {
  my ($n, %x) = @_;
  return +{ column_name => $n, data_type => 'int', not_null => 0, is_pk => 0, pk_position => 0, %x };
}
sub model {
  my (%m) = @_;
  my $collation = delete $m{collation};
  return { tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %{ $m{columns} } },
           indexes => {}, foreign_keys => {}, %m,
           (defined $collation ? (collation => $collation) : ()) };
}
my $CI = { name => 'SQL_Latin1_General_CP1_CI_AS', case_sensitive => 0 };
my $CS = { name => 'SQL_Latin1_General_CP1_CS_AS', case_sensitive => 1 };

sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
}

# the same schema, spelled differently
sub live   {
  my ($coll) = @_;
  return model(collation => $coll,
    columns => { foo => [ col('id', is_pk => 1, pk_position => 1, not_null => 1,
                              pk_constraint_name => 'PK_foo'), col('name') ],
                 bar => [ col('id', is_pk => 1, pk_position => 1, not_null => 1,
                              pk_constraint_name => 'PK_bar'), col('foo_id') ] },
    indexes => { foo => { ixa => { index_name => 'ixa', columns => ['name'], is_unique => 0 } } },
    foreign_keys => { bar => [ { constraint_name => 'fk_bar_foo', from_columns => ['foo_id'],
                                 to_table => 'foo', to_columns => ['id'] } ] });
}
sub wanted {
  return model(
    columns => { Foo => [ col('Id', is_pk => 1, pk_position => 1, not_null => 1), col('NAME') ],
                 BAR => [ col('ID', is_pk => 1, pk_position => 1, not_null => 1), col('Foo_Id') ] },
    indexes => { Foo => { IxA => { index_name => 'IxA', columns => ['NAME'], is_unique => 0 } } },
    foreign_keys => { BAR => [ { constraint_name => 'FK_Bar_Foo', from_columns => ['Foo_Id'],
                                 to_table => 'Foo', to_columns => ['Id'] } ] });
}

# 1. case-insensitive: every name in another spelling is no change
{
  my @s = stmts(live($CI), wanted());
  is_deeply \@s, [], '1: table, column, index and foreign key names in another case: no operation'
    or diag join "\n", @s;
  my $d = DBIO::MSSQL::Diff->new(source => live($CI), target => wanted());
  ok !$d->has_changes, '1: has_changes is false';
}

# 2. case-sensitive: the same two models differ, as they always did
{
  my @s = stmts(live($CS), wanted());
  ok scalar(@s) > 0, '2: a case-sensitive database sees the other spelling as other objects';
  ok((grep { /DROP TABLE foo;/ } @s) && (grep { /CREATE TABLE Foo/ } @s),
    '2: foo is dropped, Foo is created');
}

# 3. a model without a collation compares exactly (hand-built models, older callers)
{
  my @s = stmts(live(undef), wanted());
  ok scalar(@s) > 0, '3: no collation in the model: exact comparison, as before';
}

# 4. case-insensitive, and a real change beside the spelling: only the real one
{
  my $t = wanted();
  push @{ $t->{columns}{Foo} }, col('Extra');
  $t->{indexes}{Foo}{IxA}{columns} = [ 'NAME', 'Extra' ];
  my @s = stmts(live($CI), $t);
  is_deeply [ grep { /ADD Extra|ADD \[?Extra/ } @s ], [ 'ALTER TABLE foo ADD Extra int;' ]
    , '4: the new column is added with its own spelling, on the live table name'
    or diag join "\n", @s;
  ok((grep { /DROP INDEX ixa ON foo;/ } @s) && (grep { /CREATE INDEX ixa ON foo \(name, Extra\)/ } @s),
    '4: a changed index is the live object: live table, column and index spelling')
    or diag join "\n", @s;
  is scalar(grep { /DROP TABLE|CREATE TABLE|CONSTRAINT/ } @s), 0,
    '4: no table, no constraint operation for a spelling';
}

# 5. the models handed in are not changed
{
  my ($src, $tgt) = (live($CI), wanted());
  my $before = join ',', sort keys %{ $tgt->{columns} };
  stmts($src, $tgt);
  is join(',', sort keys %{ $tgt->{columns} }), $before, '5: the target model is left as it was';
  is $tgt->{columns}{Foo}[0]{column_name}, 'Id', '5: ... also its columns';
  is $tgt->{foreign_keys}{BAR}[0]{to_table}, 'Foo', '5: ... and its foreign keys';
}

# 6. a table that exists in the target only is not renamed to anything
{
  my $t = wanted();
  $t->{columns}{Baz} = [ col('Id') ];
  $t->{tables}{Baz} = { table_name => 'Baz', kind => 'table' };
  my @s = stmts(live($CI), $t);
  is scalar(grep { /CREATE TABLE Baz/ } @s), 1, '6: a new table keeps its spelling';
}

# 7. the introspect reads the collation of the database into the model
{
  package T::Dbh;
  sub new { bless { rows => $_[1] }, $_[0] }
  sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{sql} }, $sql; @{ $s->{rows} } }
}
for my $case (
  [ 'SQL_Latin1_General_CP1_CI_AS' => 196609, 0 ],
  [ 'SQL_Latin1_General_CP1_CS_AS' => 196608, 1 ],
  [ 'Latin1_General_100_BIN2'      => 0,      1 ],
  [ 'Latin1_General_CI_AI'         => 196617, 0 ],
) {
  my ($name, $style, $cs) = @$case;
  my $c = DBIO::MSSQL::Introspect->_fetch_collation(T::Dbh->new([ $name, $style ]));
  is_deeply $c, { name => $name, case_sensitive => $cs },
    "7: $name (ComparisonStyle $style) is " . ($cs ? 'case-sensitive' : 'case-insensitive');
}

done_testing;
