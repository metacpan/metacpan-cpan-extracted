use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Oracle::Diff;

# OFFLINE (karr k64, core k369). DBIO::Oracle::Diff compares the unique
# constraints of a table both models have, by their columns (the name does not
# count), and writes the difference: DROP CONSTRAINT by the name of the source
# model, ADD CONSTRAINT ... UNIQUE by the name of the target model. The order
# of a run: foreign keys gone, unique constraints gone, the tables and
# columns, unique constraints new, foreign keys new (a key to a new unique
# constraint needs it first). Without a database.

no warnings 'redefine';
local *DBI::connect = sub { die 'the diff must not connect' };

sub model {
  my (%o) = @_;
  return {
    tables  => { ITEM => { table_name => 'ITEM' } },
    columns => {
      ITEM => [ { column_name => 'ID',   data_type => 'numeric', not_null => 1 },
                { column_name => 'CODE', data_type => 'varchar2', size => 20 } ],
    },
    ( $o{unique} ? ( unique_constraints => $o{unique} ) : () ),
  };
}

sub sql { [ map { $_->as_sql } @{ DBIO::Oracle::Diff->new(source => $_[0], target => $_[1])->operations } ] }

sub uq { model(unique => { ITEM => [ @_ ] }) }

is_deeply sql(uq([ UQ_A => ['CODE'] ]), uq([ UQ_A => ['CODE'] ])), [],
  'the same unique constraint in both models: no operation';
is_deeply sql(uq([ UQ_A => ['CODE'] ]), uq([ UQ_B => ['CODE'] ])), [],
  'the same constraint under another name: no operation';
is_deeply sql(model(unique => { ITEM => [] }), model()), [], 'a missing section counts as empty';

is_deeply sql(model(), uq([ UQ_A => ['CODE'] ])),
  [ 'ALTER TABLE "ITEM" ADD CONSTRAINT "UQ_A" UNIQUE ("CODE");' ],
  'a constraint only the target has: ADD CONSTRAINT';

is_deeply sql(uq([ UQ_A => ['CODE'] ]), uq()),
  [ 'ALTER TABLE "ITEM" DROP CONSTRAINT "UQ_A";' ],
  'a constraint only the source has: DROP CONSTRAINT, by the name of the source model';

is_deeply sql(uq([ UQ_A => ['CODE'] ]), uq([ UQ_B => ['ID', 'CODE'] ])), [
    'ALTER TABLE "ITEM" DROP CONSTRAINT "UQ_A";',
    'ALTER TABLE "ITEM" ADD CONSTRAINT "UQ_B" UNIQUE ("ID", "CODE");',
  ], 'its columns differ: drop, then add';

# a constraint over a column the target drops goes with the column
{
  my $target = model();
  $target->{columns}{ITEM} = [ grep { $_->{column_name} ne 'CODE' } @{ $target->{columns}{ITEM} } ];
  my $ops = sql(uq([ UQ_A => ['ID', 'CODE'] ]), $target);
  is scalar @$ops, 1, 'a constraint over a column the target drops: only the column goes';
  like $ops->[0], qr/DROP COLUMN "CODE" CASCADE CONSTRAINTS/, '... with CASCADE CONSTRAINTS';
}

is_deeply sql(uq([ UQ_A => ['CODE'] ]), { tables => {}, columns => {} }), [ 'DROP TABLE "ITEM" CASCADE CONSTRAINTS;' ],
  'a table that only the source has: dropped with its constraints, nothing more';

# a schema.table key is written qualified
{
  my $m = sub { my $u = shift;
    return { tables => { 'OWNX.t' => { table_name => 't', schema => 'OWNX' } },
             columns => { 'OWNX.t' => [ { column_name => 'c', data_type => 'integer' } ] },
             unique_constraints => { 'OWNX.t' => $u } } };
  is_deeply sql($m->([]), $m->([ [ u_c => ['c'] ] ])),
    [ 'ALTER TABLE "OWNX"."t" ADD CONSTRAINT "u_c" UNIQUE ("c");' ],
    'a table of another schema: qualified';
}

# the order of a run
{
  my $fk = sub { +{ constraint_name => $_[0], from_columns => ['CODE'], to_table => 'PARENT',
                    to_columns => ['CODE'], on_delete => 'NO ACTION', is_deferrable => 0 } };
  my $m = sub {
    my ($extra_col, $uq, $fks) = @_;
    return {
      tables  => { ITEM => { table_name => 'ITEM' }, PARENT => { table_name => 'PARENT' } },
      columns => {
        ITEM   => [ { column_name => 'ID', data_type => 'numeric', not_null => 1 },
                    { column_name => 'CODE', data_type => 'varchar2', size => 20 },
                    ( $extra_col ? { column_name => 'NEWC', data_type => 'integer' } : () ) ],
        PARENT => [ { column_name => 'CODE', data_type => 'varchar2', size => 20 } ],
      },
      unique_constraints => { PARENT => $uq },
      foreign_keys       => { ITEM => $fks },
    };
  };
  my $gone = sql($m->(0, [ [ PU_OLD => ['CODE'] ] ], [ $fk->('FK_OLD') ]), $m->(1, [], []));
  is scalar @$gone, 3, 'a foreign key and a unique constraint gone, a column new: three statements';
  is_deeply [ @$gone[0, 1] ], [
    'ALTER TABLE "ITEM" DROP CONSTRAINT "FK_OLD";',
    'ALTER TABLE "PARENT" DROP CONSTRAINT "PU_OLD";',
  ], 'the foreign key goes first, then the unique constraint it needed';
  like $gone->[2], qr/ADD \("NEWC"/, '... then the columns';

  my $new = sql($m->(0, [], []), $m->(1, [ [ PU_NEW => ['CODE'] ] ], [ $fk->('FK_NEW') ]));
  is scalar @$new, 3, 'a unique constraint and a foreign key new, a column new: three statements';
  like $new->[0], qr/ADD \("NEWC"/, 'the columns first';
  is_deeply [ @$new[1, 2] ], [
    'ALTER TABLE "PARENT" ADD CONSTRAINT "PU_NEW" UNIQUE ("CODE");',
    'ALTER TABLE "ITEM" ADD CONSTRAINT "FK_NEW" FOREIGN KEY ("CODE") REFERENCES "PARENT" ("CODE");',
  ], 'the unique constraint, then the foreign key that needs it';
}

done_testing;
