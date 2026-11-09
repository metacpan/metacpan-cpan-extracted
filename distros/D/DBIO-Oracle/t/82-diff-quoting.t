use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::SQL::Util ();
use DBIO::Oracle::Diff;

# OFFLINE (karr k61). Two claims about the SQL of a diff, t/55-diff-index-live.t
# holds the same against a server.
#
# 1. The ALTER TABLEs of a column diff write the table and the column quoted,
#    as the install (DBIO::Oracle::DDL) and Diff::Table do. Bare, Oracle folds
#    the name to upper case, and a table the install made in lower case is not
#    found (ORA-00942).
# 2. DROP TABLE takes the trigger along, not the sequence the install made for
#    the table: the diff drops that one too. Not a sequence that belongs to
#    an IDENTITY column (the model has none), not one of another schema, and
#    not one another table of the target still feeds from.

no warnings 'redefine';
local *DBI::connect = sub { die 'the diff must not connect' };

sub statements { [ DBIO::SQL::Util::_split_statements($_[0]->as_sql) ] }

sub model {
  my (%section) = @_;
  return { tables => {}, columns => {}, indexes => {}, foreign_keys => {},
           primary_keys => {}, unique_constraints => {}, %section };
}

sub table { return ( $_[0] => { table_name => $_[0], kind => 'table', schema => $_[1] // 'U' } ) }

# --------------------------------------------------------------------- 1

{
  my $id  = { column_name => 'id', data_type => 'integer', not_null => 1 };
  my $src = model(
    tables  => { table('lower_t'), table('Odd "T"') },
    columns => {
      lower_t   => [ $id, { column_name => 'gone', data_type => 'integer' },
                          { column_name => 'val',  data_type => 'varchar2', size => 10 } ],
      'Odd "T"' => [ $id ],
    },
    indexes => { lower_t => {}, 'Odd "T"' => {} },
  );
  my $tgt = model(
    tables  => { table('lower_t'), table('Odd "T"') },
    columns => {
      lower_t   => [ $id, { column_name => 'val',   data_type => 'varchar2', size => 20 },
                          { column_name => 'extra', data_type => 'varchar2', size => 5 } ],
      'Odd "T"' => [ $id, { column_name => 'Mixed Col', data_type => 'integer' } ],
    },
    indexes => { lower_t => {}, 'Odd "T"' => {} },
  );

  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => $tgt)), [
    q{ALTER TABLE "Odd ""T""" ADD ("Mixed Col" INTEGER)},
    q{ALTER TABLE "lower_t" ADD ("extra" VARCHAR2(5))},
    q{ALTER TABLE "lower_t" MODIFY ("val" VARCHAR2(20))},
    q{ALTER TABLE "lower_t" DROP COLUMN "gone" CASCADE CONSTRAINTS},
  ], 'ADD, MODIFY and DROP COLUMN write table and column quoted, as the model spells them; a quote in a name is doubled';
}

# --------------------------------------------------------------------- 2

sub seq_col { return { column_name => 'id', data_type => 'numeric', not_null => 1, is_pk => 1,
  is_auto_increment => 1, sequence => $_[0] } }

{
  my $src = model(
    tables  => { table('parent'), table('keep') },
    columns => {
      parent => [ seq_col('U.parent_id_seq'), { column_name => 'n', data_type => 'integer' } ],
      keep   => [ { column_name => 'x', data_type => 'integer' } ],
    },
    indexes => { parent => {}, keep => {} },
  );
  my $tgt = model(
    tables  => { table('keep') },
    columns => { keep => [ { column_name => 'x', data_type => 'integer' } ] },
    indexes => { keep => {} },
  );

  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => $tgt)), [
    q{DROP TABLE "parent" CASCADE CONSTRAINTS},
    q{DROP SEQUENCE "parent_id_seq"},
  ], 'DROP TABLE also drops the sequence the install made for it, quoted as the model spells it';
}

{
  my $src = model(
    tables  => { table('ident'), table('foreign_seq'), table('shared'), table('user_of_shared') },
    columns => {
      ident       => [ { column_name => 'id', data_type => 'numeric', not_null => 1, is_auto_increment => 1 } ],
      foreign_seq => [ seq_col('OTHER.s_seq') ],
      shared      => [ seq_col('U.shared_seq') ],
      user_of_shared => [ seq_col('U.shared_seq') ],
    },
    indexes => { map { $_ => {} } qw(ident foreign_seq shared user_of_shared) },
  );
  my $tgt = model(
    tables  => { table('user_of_shared') },
    columns => { user_of_shared => [ seq_col('U.shared_seq') ] },
    indexes => { user_of_shared => {} },
  );

  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => $tgt)), [
    q{DROP TABLE "foreign_seq" CASCADE CONSTRAINTS},
    q{DROP TABLE "ident" CASCADE CONSTRAINTS},
    q{DROP TABLE "shared" CASCADE CONSTRAINTS},
  ], 'no sequence is dropped for an IDENTITY column, for one of another schema, '
   . 'or for one a table of the target is still fed from';
}

{
  my $src = model(
    tables  => { 'View_' => { table_name => 'View_', kind => 'view', schema => 'U' } },
    columns => { 'View_' => [ seq_col('U.v_seq') ] },
  );
  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => model())),
    [ q{DROP VIEW "View_"} ], 'a dropped view drops no sequence';
}

# A sequence with a dot in its name: the schema of the table is taken off first.
{
  my $src = model(
    tables  => { table('t', 'S') },
    columns => { t => [ seq_col('S.a.b') ] },
    indexes => { t => {} },
  );
  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => model())),
    [ q{DROP TABLE "t" CASCADE CONSTRAINTS}, q{DROP SEQUENCE "a.b"} ],
    'a sequence name with a dot is dropped whole';
}

# The spelling of the schema counts: a model that says "u" has no sequence of "U".
{
  my $src = model(
    tables  => { table('t', 'U') },
    columns => { t => [ seq_col('u.t_id_seq') ] },
    indexes => { t => {} },
  );
  is_deeply statements(DBIO::Oracle::Diff->new(source => $src, target => model())),
    [ q{DROP TABLE "t" CASCADE CONSTRAINTS} ],
    'the model gives the schema as the server spells it; another spelling is another schema';
}

done_testing;
