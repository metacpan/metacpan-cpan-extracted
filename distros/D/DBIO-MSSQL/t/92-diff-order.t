use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Diff;

# karr k71, review blockers B1, B2 and S4. The target model of a diff carries
# foreign keys now (install_ddl writes them), and the core walk is
# alphabetical, so the statements of an upgrade have to be put in an order the
# server accepts: foreign key drops, index and unique drops, DROP TABLE,
# column operations, CREATE TABLE (without foreign keys), index and unique
# creation, foreign key adds. The server's answer to each order is in
# t/93-diff-order-live.t; this file pins the statements and their order.

sub fk {
  my ($name, $from, $to) = @_;
  return { constraint_name => $name, from_columns => ['ref_id'],
           to_table => $to, to_columns => ['id'],
           on_delete => 'NO ACTION', on_update => 'NO ACTION' };
}
sub tbl { +{ map { $_ => { table_name => $_, kind => 'table' } } @_ } }
sub col { [ map { +{ column_name => $_, data_type => 'int' } } @_ ] }

# statements of a diff, in order, one per entry
sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
}
sub pos_of {
  my ($re, @s) = @_;
  for my $i (0 .. $#s) { return $i if $s[$i] =~ $re }
  return -1;
}
sub before_ok {
  my ($a, $b, $s, $name) = @_;
  my ($pa, $pb) = (pos_of($a, @$s), pos_of($b, @$s));
  ok($pa >= 0 && $pb >= 0 && $pa < $pb, $name)
    or diag join "\n", map { "  $_" } @$s;
}

my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };

# B1 (a): a new child sorts before its new parent; a mutual pair
{
  my $tgt = {
    tables  => tbl(qw(a_child z_parent m_a m_b)),
    columns => { a_child => col(qw(id ref_id)), z_parent => col('id'),
                 m_a => col(qw(id ref_id)), m_b => col(qw(id ref_id)) },
    indexes => {},
    foreign_keys => {
      a_child => [ fk('FK_a_child_ref_id', 'a_child', 'z_parent') ],
      m_a     => [ fk('FK_m_a_ref_id', 'm_a', 'm_b') ],
      m_b     => [ fk('FK_m_b_ref_id', 'm_b', 'm_a') ],
    },
  };
  my @s = stmts($empty, $tgt);
  is scalar(grep { /^CREATE TABLE/ } @s), 4, 'B1a: four tables created';
  is scalar(grep { /^CREATE TABLE.*FOREIGN KEY/s } @s), 0,
    'B1a: no table is created with an inline foreign key';
  is scalar(grep { /^ALTER TABLE \S+ ADD CONSTRAINT .* FOREIGN KEY/ } @s), 3,
    'B1a: every foreign key is an ALTER TABLE ADD CONSTRAINT';
  like((grep { /^CREATE TABLE a_child/ } @s)[0], qr/ref_id int/,
    'B1a: ... and still carries its columns');
  my $last_create = (grep { $s[$_] =~ /^CREATE TABLE/ } 0 .. $#s)[-1];
  my $first_fk    = (grep { $s[$_] =~ /FOREIGN KEY/ } 0 .. $#s)[0];
  cmp_ok $first_fk, '>', $last_create, 'B1a: all foreign keys come after the last CREATE TABLE';
}

# B1 (b): a referenced table is dropped; two dropped tables reference each other
{
  my $src = {
    tables  => tbl(qw(cd artist x y)),
    columns => { cd => col(qw(id ref_id)), artist => col('id'),
                 x => col(qw(id ref_id)), y => col(qw(id ref_id)) },
    indexes => {},
    foreign_keys => {
      cd => [ fk('FK_cd_ref_id', 'cd', 'artist') ],
      x  => [ fk('FK_x_ref_id', 'x', 'y') ],
      y  => [ fk('FK_y_ref_id', 'y', 'x') ],
    },
  };
  my $tgt = {
    tables  => tbl('cd'),
    columns => { cd => col(qw(id ref_id)) },
    indexes => {}, foreign_keys => {},
  };
  my @s = stmts($src, $tgt);
  before_ok(qr/DROP CONSTRAINT FK_cd_ref_id/, qr/^DROP TABLE artist/, \@s,
    'B1b: the foreign key to a dropped table goes before DROP TABLE');
  before_ok(qr/DROP CONSTRAINT FK_x_ref_id/, qr/^DROP TABLE y/, \@s,
    'B1b: dropped tables that reference each other: x key before DROP TABLE y');
  before_ok(qr/DROP CONSTRAINT FK_y_ref_id/, qr/^DROP TABLE x/, \@s,
    'B1b: ... and y key before DROP TABLE x');
}

# B1 (c): the column of a foreign key is dropped / altered
{
  my $src = {
    tables  => tbl(qw(cd artist)),
    columns => { cd => col(qw(id ref_id)), artist => col('id') },
    indexes => {},
    foreign_keys => { cd => [ fk('FK_cd_ref_id', 'cd', 'artist') ] },
  };
  my $tgt = {
    tables  => tbl(qw(cd artist)),
    columns => { cd => col('id'), artist => col('id') },
    indexes => {}, foreign_keys => { cd => [] },
  };
  my @s = stmts($src, $tgt);
  before_ok(qr/DROP CONSTRAINT FK_cd_ref_id/, qr/DROP COLUMN ref_id/, \@s,
    'B1c: the foreign key goes before the drop of its column');
}

# B2: the last foreign key of a table is removed; the target has no entry
for my $tgt_fk ({}, { cd => [] }) {
  my $src = {
    tables  => tbl(qw(cd artist)),
    columns => { cd => col(qw(id ref_id)), artist => col('id') },
    indexes => {},
    foreign_keys => { cd => [ fk('FK_cd_ref_id', 'cd', 'artist') ] },
  };
  my $tgt = { %$src, foreign_keys => $tgt_fk };
  my @s = stmts($src, $tgt);
  is_deeply \@s, ['ALTER TABLE cd DROP CONSTRAINT FK_cd_ref_id;'],
    'B2: the last foreign key is dropped (target entry '
    . (exists $tgt_fk->{cd} ? 'empty' : 'absent') . ')';
}

# S4: unique constraint versus unique index
{
  my $uq = { is_unique => 1, is_unique_constraint => 1, kind => 'nonclustered', columns => ['a', 'b'] };
  my $ui = { is_unique => 1, is_unique_constraint => 0, kind => 'nonclustered', columns => ['a', 'b'] };
  my $base = { tables => tbl('t'), columns => { t => col(qw(id a b)) }, foreign_keys => {} };

  is_deeply [ stmts({ %$base, indexes => {} }, { %$base, indexes => { t => { uq_ab => $uq } } }) ],
    ['ALTER TABLE t ADD CONSTRAINT uq_ab UNIQUE (a, b);'],
    'S4: a unique constraint is added as a constraint';
  is_deeply [ stmts({ %$base, indexes => { t => { uq_ab => $uq } } }, { %$base, indexes => {} }) ],
    ['ALTER TABLE t DROP CONSTRAINT uq_ab;'],
    'S4: a unique constraint is dropped as a constraint (DROP INDEX is Msg 3723)';
  is_deeply [ stmts({ %$base, indexes => {} }, { %$base, indexes => { t => { ux => $ui } } }) ],
    ['CREATE UNIQUE NONCLUSTERED INDEX ux ON t (a, b);'],
    'S4: a unique index stays an index';
  is_deeply [ stmts({ %$base, indexes => { t => { ux => $ui } } }, { %$base, indexes => {} }) ],
    ['DROP INDEX ux ON t;'],
    'S4: ... and is dropped as one';
  is_deeply [ stmts({ %$base, indexes => { t => { n => $ui } } }, { %$base, indexes => { t => { n => $uq } } }) ],
    ['DROP INDEX n ON t;', 'ALTER TABLE t ADD CONSTRAINT n UNIQUE (a, b);'],
    'S4: index to constraint under one name: each side with its own statement';
  is_deeply [ stmts({ %$base, indexes => { t => { n => $uq } } },
                    { %$base, indexes => { t => { n => { %$uq, columns => ['a'] } } } }) ],
    ['ALTER TABLE t DROP CONSTRAINT n;', 'ALTER TABLE t ADD CONSTRAINT n UNIQUE (a);'],
    'S4: changed columns of a constraint: drop, then add';

  # the constraint exists before a foreign key that references it, and a
  # constraint on a new table is created after the table
  my $tgt = {
    tables  => tbl(qw(child parent)),
    columns => { child => col(qw(id ref_id)), parent => col(qw(id code)) },
    indexes => { parent => { uq_code => { %$uq, columns => ['code'] } } },
    foreign_keys => { child => [ { %{ fk('FK_child_ref_id', 'child', 'parent') }, to_columns => ['code'] } ] },
  };
  my @s = stmts($empty, $tgt);
  before_ok(qr/^CREATE TABLE parent/, qr/ADD CONSTRAINT uq_code UNIQUE/, \@s,
    'S4: the unique constraint of a new table comes after its CREATE TABLE');
  before_ok(qr/ADD CONSTRAINT uq_code UNIQUE/, qr/ADD CONSTRAINT FK_child_ref_id FOREIGN KEY/, \@s,
    'S4: ... and before the foreign key that references it');

  # an index goes before the column it covers is dropped
  my $s2 = [ stmts({ tables => tbl('t'), columns => { t => col(qw(id a)) },
                     indexes => { t => { uq_a => { %$uq, columns => ['a'] } } }, foreign_keys => {} },
                   { tables => tbl('t'), columns => { t => col('id') }, indexes => {}, foreign_keys => {} }) ];
  before_ok(qr/DROP CONSTRAINT uq_a/, qr/DROP COLUMN a/, $s2,
    'S4: the constraint goes before the drop of its column');
}

done_testing;
