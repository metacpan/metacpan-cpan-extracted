use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Diff;

# karr k71. ALTER COLUMN on a column that a unique constraint or an index
# covers: measured live (t/101, t/93), the server refuses NULL -> NOT NULL and
# a type change there ("The object 'UQ_t' is dependent on column"), and
# accepts NOT NULL -> NULL, a width change of nvarchar, and a foreign key
# column's nullability. The diff drops the constraint/index before the column
# phase and creates it again after it, unless the diff drops/creates it anyway.

sub tbl { +{ map { $_ => { table_name => $_, kind => 'table' } } @_ } }
sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
}
sub idx {
  return { t => {
    UQ_t_code => { index_name => 'UQ_t_code', columns => ['code'], is_unique => 1, is_unique_constraint => 1 },
    ix_code   => { index_name => 'ix_code',   columns => ['code'], is_unique => 0 },
    ux_other  => { index_name => 'ux_other',  columns => ['other'], is_unique => 1 },
  } };
}
sub model {
  my (%c) = @_;
  return {
    tables => tbl('t'),
    columns => { t => [
      { column_name => 'id',    data_type => 'int', not_null => 1 },
      { column_name => 'other', data_type => 'int' },
      { column_name => 'code',  data_type => $c{type} // 'int', size => $c{size}, not_null => $c{nn} },
    ] },
    indexes => idx(), foreign_keys => {},
  };
}
sub pos_of { my ($re, @s) = @_; for (0 .. $#s) { return $_ if $s[$_] =~ $re } -1 }

{
  my @s = stmts(model(nn => 0), model(nn => 1));
  my ($alter) = grep { /ALTER COLUMN code int NOT NULL/ } @s;
  ok $alter, 'NULL -> NOT NULL: ALTER COLUMN is written' or diag join "\n", @s;
  is scalar(grep { /DROP CONSTRAINT UQ_t_code/ } @s), 1, '... the unique constraint is dropped';
  is scalar(grep { /DROP INDEX ix_code ON t/ } @s), 1, '... the nonclustered index is dropped';
  is scalar(grep { /ux_other/ } @s), 0, '... an index on another column is left alone';
  my $pa = pos_of(qr/ALTER COLUMN code/, @s);
  ok pos_of(qr/DROP CONSTRAINT UQ_t_code/, @s) < $pa && pos_of(qr/DROP INDEX ix_code/, @s) < $pa,
    '... both before the ALTER COLUMN';
  ok pos_of(qr/ADD CONSTRAINT UQ_t_code UNIQUE \(code\)/, @s) > $pa
    && pos_of(qr/CREATE INDEX ix_code ON t \(code\)/, @s) > $pa,
    '... and created again after it';
}
{
  my @s = stmts(model(nn => 1), model(nn => 0));
  is scalar(grep { /UQ_t_code|ix_code/ } @s), 0, 'NOT NULL -> NULL: the server accepts it, nothing is dropped';
  ok scalar(grep { /ALTER COLUMN code int NULL/ } @s), '... ALTER COLUMN written';
}
{
  my @s = stmts(model(type => 'int', nn => 1), model(type => 'bigint', nn => 1));
  is scalar(grep { /DROP CONSTRAINT UQ_t_code/ } @s), 1, 'type change: unique constraint dropped';
  is scalar(grep { /ADD CONSTRAINT UQ_t_code/ } @s), 1, '... and added again';
}
{
  my @s = stmts(model(type => 'nvarchar', size => 10), model(type => 'nvarchar', size => 20));
  is scalar(grep { /UQ_t_code|ix_code/ } @s), 0, 'nvarchar width change: accepted by the server, nothing dropped';
  ok scalar(grep { /ALTER COLUMN code nvarchar\(20\)/ } @s), '... ALTER COLUMN written';
}
{
  # the index changes as well: the diff's own drop/create pair is not doubled
  my $tgt = model(nn => 1);
  $tgt->{indexes}{t}{ix_code} = { %{ $tgt->{indexes}{t}{ix_code} }, columns => ['code', 'other'] };
  my @s = stmts(model(nn => 0), $tgt);
  is scalar(grep { /DROP INDEX ix_code/ } @s), 1, 'changed index: dropped once';
  is scalar(grep { /CREATE INDEX ix_code/ } @s), 1, '... created once';
}
{
  # the index is gone in the target: dropped once, not created
  my $tgt = model(nn => 1);
  delete $tgt->{indexes}{t}{ix_code};
  my @s = stmts(model(nn => 0), $tgt);
  is scalar(grep { /DROP INDEX ix_code/ } @s), 1, 'removed index: dropped once';
  is scalar(grep { /CREATE INDEX ix_code/ } @s), 0, '... not created';
}

done_testing;
