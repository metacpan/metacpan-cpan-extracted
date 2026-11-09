use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Oracle::Diff;

# OFFLINE (karr k64, after k60). DBIO::Oracle::Diff compares the foreign keys
# of a table both models have and writes the difference: ALTER TABLE ... DROP
# CONSTRAINT for a key that is gone, ADD CONSTRAINT ... FOREIGN KEY for a new
# one, both for a key that changed (an action, the columns, the target).
# Without a database (DBI->connect dies here).
#
# Compared per table by what a key is, not what it is called: from_columns,
# to_table, to_columns, on_delete, is_deferrable. The same keys under other
# constraint names are no difference. A drop uses the name of the source
# model; an add the name of the target model.

no warnings 'redefine';
local *DBI::connect = sub { die 'the diff must not connect' };

sub fk {
  my (%o) = @_;
  return {
    constraint_name => 'FK_X', from_table => 'ITEM', from_columns => ['PARENT_ID'],
    to_table => 'PARENT', to_columns => ['ID'],
    on_update => 'NO ACTION', on_delete => 'NO ACTION', is_deferrable => 0,
    %o,
  };
}

sub model {
  my (%fks) = @_;
  return {
    tables  => { ITEM => { table_name => 'ITEM' }, PARENT => { table_name => 'PARENT' } },
    columns => {
      ITEM   => [ { column_name => 'ID', data_type => 'numeric', not_null => 1 },
                  { column_name => 'PARENT_ID', data_type => 'numeric' } ],
      PARENT => [ { column_name => 'ID', data_type => 'numeric', not_null => 1 } ],
    },
    %fks ? ( foreign_keys => \%fks ) : (),
  };
}

sub sql { [ map { $_->as_sql } @{ DBIO::Oracle::Diff->new(source => $_[0], target => $_[1])->operations } ] }

my $drop = 'ALTER TABLE "ITEM" DROP CONSTRAINT "FK_X";';
my $add  = 'ALTER TABLE "ITEM" ADD CONSTRAINT "FK_X" FOREIGN KEY ("PARENT_ID") REFERENCES "PARENT" ("ID");';

is_deeply sql(model(ITEM => [ fk() ]), model(ITEM => [ fk() ])), [],
  'the same key in both models: no operation';

is_deeply sql(model(ITEM => [ fk(constraint_name => 'FK_A') ]),
              model(ITEM => [ fk(constraint_name => 'FK_B') ])), [],
  'the same key under another constraint name: no operation';

is_deeply sql(model(), model()), [], 'no foreign_keys section in either model: no operation';
is_deeply sql(model(ITEM => []), model()), [], 'a missing section counts as empty';

is_deeply sql(model(ITEM => []), model(ITEM => [ fk() ])), [ $add ],
  'a key only the target has: ADD CONSTRAINT';

is_deeply sql(model(ITEM => [ fk() ]), model()), [ $drop ],
  'a key only the source has: DROP CONSTRAINT, by the name of the source model';

is_deeply sql(model(ITEM => [ fk(constraint_name => 'FK_OLD') ]), model(ITEM => [])),
  [ 'ALTER TABLE "ITEM" DROP CONSTRAINT "FK_OLD";' ],
  'the drop names the constraint as the introspected model has it';

is_deeply sql(model(ITEM => [ fk() ]), model(ITEM => [ fk(on_delete => 'CASCADE') ])),
  [ $drop, substr($add, 0, -1) . ' ON DELETE CASCADE;' ],
  'a changed action is DROP plus ADD, the drop first';

is_deeply sql(model(ITEM => [ fk() ]), model(ITEM => [ fk(on_delete => 'SET NULL', is_deferrable => 1) ])),
  [ $drop, substr($add, 0, -1) . ' ON DELETE SET NULL DEFERRABLE;' ],
  'SET NULL and DEFERRABLE are written';

for my $change (
  [ from_columns  => ['ID']       ],
  [ to_table      => 'ELSEWHERE'  ],
  [ to_columns    => ['ID2']      ],
  [ is_deferrable => 1            ],
) {
  my ($field, $value) = @$change;
  my $ops = sql(model(ITEM => [ fk() ]), model(ITEM => [ fk($field => $value) ]));
  is scalar @$ops, 2, "$field differs: drop and add";
  is $ops->[0], $drop, '... the drop first';
  like $ops->[1], qr/\AALTER TABLE "ITEM" ADD CONSTRAINT "FK_X" FOREIGN KEY/, '... then the add';
}

# what Oracle does not have is refused, with table and column
throws_ok { sql(model(ITEM => []), model(ITEM => [ fk(on_delete => 'SET DEFAULT') ])) }
  qr/foreign key 'FK_X' of table 'ITEM' \(column PARENT_ID\).*SET DEFAULT/s,
  'SET DEFAULT is refused, naming table and column';

throws_ok { sql(model(ITEM => []), model(ITEM => [ fk(on_update => 'CASCADE') ])) }
  qr/foreign key 'FK_X' of table 'ITEM' \(column PARENT_ID\).*ON UPDATE/s,
  'an ON UPDATE action is refused, naming table and column';

throws_ok { sql(model(ITEM => [ fk() ]), model(ITEM => [ fk(on_update => 'SET NULL') ])) }
  'DBIO::Exception', 'a changed ON UPDATE action is refused (a DBIO::Exception), not ignored';

lives_ok { sql(model(ITEM => []), model(ITEM => [ fk(on_update => 'RESTRICT') ])) }
  'RESTRICT is Oracle\'s NO ACTION: written without a clause';

# on_delete RESTRICT is written as the DDL writes it: as NO ACTION, no clause
# (hub decision on karr k64; Oracle has no RESTRICT, NO ACTION is its rule)
is_deeply sql(model(ITEM => []), model(ITEM => [ fk(on_delete => 'RESTRICT') ])), [ $add ],
  'on_delete RESTRICT is written as NO ACTION: no ON DELETE clause, not refused';
is_deeply sql(model(ITEM => [ fk(on_delete => 'RESTRICT') ]), model(ITEM => [ fk() ])), [],
  'RESTRICT and NO ACTION are the same rule: no difference';
is_deeply sql(model(ITEM => [ fk(on_delete => 'restrict') ]), model(ITEM => [ fk(on_delete => 'CASCADE') ])),
  [ $drop, substr($add, 0, -1) . ' ON DELETE CASCADE;' ],
  'RESTRICT (any case) to CASCADE: drop and add';

# a key over a column the target drops goes with the column
{
  my $target = model();
  $target->{columns}{ITEM} = [ grep { $_->{column_name} ne 'PARENT_ID' } @{ $target->{columns}{ITEM} } ];
  my $ops = sql(model(ITEM => [ fk() ]), $target);
  is scalar @$ops, 1, 'a key over a column the target drops: only the column goes';
  like $ops->[0], qr/DROP COLUMN "PARENT_ID" CASCADE CONSTRAINTS/, '... with CASCADE CONSTRAINTS';
}

is_deeply sql(model(ITEM => [ fk() ]),
              { %{ model() }, tables => { PARENT => { table_name => 'PARENT' } } }),
  [ 'DROP TABLE "ITEM" CASCADE CONSTRAINTS;' ],
  'a table that only the source has is dropped with its keys: no constraint operation';

like( sql({ %{ model() }, tables => { PARENT => { table_name => 'PARENT' } } },
          model(ITEM => [ fk() ]))->[-1], qr/ADD CONSTRAINT "FK_X" FOREIGN KEY/,
  'a table that only the target has: its key is created (karr k37)');

# the key of a table both have that points to a table the target drops goes
# before that table
{
  my $tgt = model();
  delete $tgt->{tables}{PARENT};
  delete $tgt->{columns}{PARENT};
  is_deeply sql(model(ITEM => [ fk() ]), $tgt), [ $drop, 'DROP TABLE "PARENT" CASCADE CONSTRAINTS;' ],
    'a key is dropped before the table it points to';
}

# A key that stays, over a unique constraint the target drops or changes
# (hub decision on karr k64, ORA-02273): Oracle refuses to drop a unique
# constraint a foreign key points to. The key goes first and is created
# again, unchanged, after the constraint; if the target has nothing the key
# could point to, the diff refuses before it writes a statement.
{
  my $ufk = sub { fk(from_columns => ['CODE'], to_columns => ['CODE']) };
  my $m = sub {
    my ($unique, $pk, $fks) = @_;
    my $model = model(ITEM => $fks // [ $ufk->() ]);
    $model->{columns}{PARENT} = [ { column_name => 'ID', data_type => 'numeric', not_null => 1 },
                                  { column_name => 'CODE', data_type => 'varchar2', size => 20 },
                                  { column_name => 'CODE2', data_type => 'varchar2', size => 20 } ];
    $model->{columns}{ITEM} = [ @{ $model->{columns}{ITEM} },
      { column_name => 'CODE', data_type => 'varchar2', size => 20 },
      { column_name => 'A', data_type => 'varchar2', size => 20 },
      { column_name => 'B', data_type => 'varchar2', size => 20 } ];
    $model->{unique_constraints} = { PARENT => $unique };
    $model->{primary_keys} = { PARENT => $pk // ['ID'] };
    return $model;
  };
  my $fk_drop = 'ALTER TABLE "ITEM" DROP CONSTRAINT "FK_X";';
  my $fk_add  = 'ALTER TABLE "ITEM" ADD CONSTRAINT "FK_X" FOREIGN KEY ("CODE") REFERENCES "PARENT" ("CODE");';

  # the target keeps a key over the same columns (in another order, so the
  # constraint is not the same one): drop key, drop constraint, add, add key
  my $two = sub { fk(from_columns => ['A', 'B'], to_columns => ['CODE', 'CODE2']) };
  my $ops = sql($m->([ [ UQ_P => ['CODE', 'CODE2'] ] ], undef, [ $two->() ]),
                $m->([ [ UQ_P => ['CODE2', 'CODE'] ] ], undef, [ $two->() ]));
  is_deeply $ops, [
    $drop,
    'ALTER TABLE "PARENT" DROP CONSTRAINT "UQ_P";',
    'ALTER TABLE "PARENT" ADD CONSTRAINT "UQ_P" UNIQUE ("CODE2", "CODE");',
    'ALTER TABLE "ITEM" ADD CONSTRAINT "FK_X" FOREIGN KEY ("A", "B") REFERENCES "PARENT" ("CODE", "CODE2");',
  ], 'a key that stays over a unique constraint the target changes: key gone, constraint, key again, unchanged';

  # a constraint the target keeps as it is: no key operation
  is_deeply sql($m->([ [ UQ_P => ['CODE'] ] ]), $m->([ [ UQ_P => ['CODE'] ] ])), [],
    'a unique constraint that stays: the key is left alone';

  # a key that goes too is dropped once, and is not created again
  is_deeply sql($m->([ [ UQ_P => ['CODE'] ] ]), $m->([ [ UQ_P => ['CODE'] ] ], undef, [])),
    [ $fk_drop ], 'a key the target drops: dropped, once';

  # the primary key of the target is something to point to
  $ops = sql($m->([ [ UQ_P => ['CODE'] ] ]), $m->([], ['CODE']));
  is_deeply $ops, [ $fk_drop, 'ALTER TABLE "PARENT" DROP CONSTRAINT "UQ_P";', $fk_add ],
    'the target replaces the constraint by a primary key over the columns: key gone, constraint gone, key again';

  # nothing to point to: refused, naming table and columns
  throws_ok { sql($m->([ [ UQ_P => ['CODE'] ] ]), $m->([])) }
    qr/foreign key 'FK_X' of table 'ITEM' \(column CODE\).*column CODE of table 'PARENT'/s,
    'a constraint removed without replacement under a key that stays: refused, naming table and columns';
  throws_ok { sql($m->([ [ UQ_P => ['CODE'] ] ]), $m->([ [ UQ_P => ['CODE', 'CODE2'] ] ])) }
    'DBIO::Exception', 'a constraint changed to other columns under a key on the old ones: refused';

  # the key of the target is on other columns than the constraint dropped: untouched
  is_deeply sql($m->([ [ UQ_P => ['CODE2'] ] ]), $m->([])),
    [ 'ALTER TABLE "PARENT" DROP CONSTRAINT "UQ_P";' ],
    'a constraint nothing points to: dropped, no key operation';
}

done_testing;
