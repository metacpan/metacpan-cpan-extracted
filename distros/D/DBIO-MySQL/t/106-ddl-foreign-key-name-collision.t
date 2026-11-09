use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;

# karr k106: what happens when foreign keys meet in one name, and in which
# order the columns of a composite foreign key are written.
#
# WHY IT MATTERS. The fixed name <table>_<columns>_fk (t/102) is a function of
# table and columns only, so two different foreign keys can come out with one
# name: table a_b column c and table a column b_c both give a_b_c_fk, and one
# column that references two targets gives one name twice. A name is unique per
# database on the servers. Refusing a schema for that refuses schemas that
# install fine on main, and two belongs_to over one key to one target
# (parent / owner) are the SAME foreign key, nothing to refuse. What this file
# claims:
#   1. identical foreign keys (table, columns, target, target columns,
#      actions) become ONE constraint;
#   2. different foreign keys with one name ALL get the fixed suffix _<hash8>
#      of (table, columns, target, target columns): deterministic, no abort;
#      the comparison ignores case, as the server does; a long name is cut to
#      64 and still differs;
#   3. install_ddl and the diff (CREATE TABLE and ADD CONSTRAINT of a model
#      that carries no names) use the same helper, foreign_key_names, so they
#      agree;
#   4. the columns of a composite foreign key follow the order of the key of
#      the target (primary key, then unique constraints by name), because
#      InnoDB takes the referenced list only in the order of an index; the
#      name follows that order. Not the sorted order of the cond hash.

my $n = 0;
# %spec: table => { cols => [..], pk => [..], uniques => { name => [..] },
#                   rels => [ [ name, target table, cond, attrs ] ] }
sub schema_for {
  my (%spec) = @_;
  my $ns = 'K106Coll::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my %class = map { $_ => "${ns}::Result::" . join '', map { ucfirst } split /_/, $_ } keys %spec;
  for my $t (sort keys %spec) {
    my $class = $class{$t};
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($t);
    my %is_pk = map { $_ => 1 } @{ $spec{$t}{pk} };
    $class->add_columns(map { $_ => { data_type => q(integer), $is_pk{$_} ? () : (is_nullable => 1) } } @{ $spec{$t}{cols} });
    $class->set_primary_key(@{ $spec{$t}{pk} });
    $class->add_unique_constraint($_ => $spec{$t}{uniques}{$_}) for sort keys %{ $spec{$t}{uniques} // {} };
  }
  for my $t (sort keys %spec) {
    $class{$t}->belongs_to($_->[0] => $class{ $_->[1] }, $_->[2], $_->[3] // {}) for @{ $spec{$t}{rels} // [] };
    $ns->register_class($t => $class{$t});
  }
  return $ns;
}
sub constraints {
  my ($ddl) = @_;
  return [ $ddl =~ /CONSTRAINT `([^`]+)` FOREIGN KEY/g ];
}
my $P = { cols => ['id'], pk => ['id'] };

# 1. identical foreign keys are one
{
  my $ddl = eval { DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    c => { cols => [qw/id pid/], pk => ['id'], rels => [
      [ parent => p => { 'foreign.id' => 'self.pid' } ],
      [ owner  => p => { 'foreign.id' => 'self.pid' } ] ] })) };
  ok defined $ddl, 'two belongs_to over one key to one target: installs' or diag $@;
  is_deeply constraints($ddl // ''), ['c_pid_fk'], '... as ONE constraint, the plain name';

  my $acts = eval { DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    c => { cols => [qw/id pid/], pk => ['id'], rels => [
      [ parent => p => { 'foreign.id' => 'self.pid' }, { on_delete => 'cascade' } ],
      [ owner  => p => { 'foreign.id' => 'self.pid' }, { on_delete => 'CASCADE' } ] ] })) };
  is_deeply constraints($acts // ''), ['c_pid_fk'], 'identical in the action, written another way: still one' or diag $@;
}

# 2. different foreign keys, one name: all get the suffix
my %hash8;
{
  my $ddl = eval { DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
    a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] })) };
  ok defined $ddl, 'table a_b column c vs table a column b_c: installs, no abort' or diag $@;
  my $names = constraints($ddl // '');
  is scalar(@$names), 2, '... both constraints are there';
  like $_, qr/^a(?:_b)?_(?:b_)?c_fk_[0-9a-f]{8}\z/, "... $_ carries _<hash8>" for @$names;
  isnt $names->[0], $names->[1], '... and the two names differ';
  my $again = eval { constraints(DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
    a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] }))) };
  is_deeply [ sort @{ $again // [] } ], [ sort @$names ], '... deterministic: the same names on the next run';
diag $@ unless $again;
}
{
  my $names = constraints(DBIO::MySQL::DDL->install_ddl(schema_for(
    p1 => $P, p2 => $P,
    c => { cols => [qw/id pid/], pk => ['id'], rels => [
      [ one => p1 => { 'foreign.id' => 'self.pid' } ],
      [ two => p2 => { 'foreign.id' => 'self.pid' } ] ] })));
  is scalar(@$names), 2, 'one column to two targets: two constraints';
  like $_, qr/^c_pid_fk_[0-9a-f]{8}\z/, "... $_ carries _<hash8>" for @$names;
  isnt $names->[0], $names->[1], '... different names';
}
{
  my $names = constraints(DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    A   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
    a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] })));
  like $_, qr/_fk_[0-9a-f]{8}\z/, "case-insensitive, as the server: $_ carries _<hash8>" for @$names;
}
{
  my $long = 't' x 30;
  my $names = constraints(DBIO::MySQL::DDL->install_ddl(schema_for(
    p => $P,
    "${long}_a" => { cols => [ 'id', "b_${long}" ], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => "self.b_${long}" } ] ] },
    "${long}"   => { cols => [ 'id', "a_b_${long}" ], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => "self.a_b_${long}" } ] ] })));
  is scalar(@$names), 2, 'long names that collide: two constraints';
  ok length($_) <= 64, "... $_ is cut to 64" for @$names;
  isnt $names->[0], $names->[1], '... and stay apart';
}

# 3. the helper, and the diff on a model without names
{
  my @fk = (
    { table => 'a_b', from_columns => ['c'],   to_table => 'p', to_columns => ['id'] },
    { table => 'a',   from_columns => ['b_c'], to_table => 'p', to_columns => ['id'] },
    { table => 'x',   from_columns => ['y'],   to_table => 'p', to_columns => ['id'] },
    { table => 'x',   from_columns => ['y'],   to_table => 'p', to_columns => ['id'] },
  );
  my @names = DBIO::MySQL::DDL::foreign_key_names(@fk);
  is scalar(@names), 4, 'foreign_key_names: one name per foreign key';
  like $names[0], qr/^a_b_c_fk_[0-9a-f]{8}\z/, '... a collision gets the suffix';
  like $names[1], qr/^a_b_c_fk_[0-9a-f]{8}\z/, '... all of them';
  isnt $names[0], $names[1], '... different';
  is $names[2], 'x_y_fk', '... no collision: the plain name';
  is $names[3], 'x_y_fk', '... an identical foreign key: the same name';

  my %tables = map { $_ => { table_name => $_ } } qw/a a_b p/;
  my $col = sub { [ map { { column_name => $_, column_type => 'int', not_null => 1 } } @_ ] };
  my $model = sub { {
    tables  => { %tables },
    columns => { a => $col->(qw/id b_c/), a_b => $col->(qw/id c/), p => $col->('id') },
    indexes => {},
    foreign_keys => { a_b => [ { from_columns => ['c'], to_table => 'p', to_columns => ['id'] } ],
                      a   => [ { from_columns => ['b_c'], to_table => 'p', to_columns => ['id'] } ] },
  } };
  my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my $sql = DBIO::MySQL::Diff->new(source => $empty, target => $model->())->as_sql;
  my @in = $sql =~ /CONSTRAINT `([^`]+)` FOREIGN KEY/g;
  is scalar(@in), 2, 'the diff of a model without names: both foreign keys written';
  is_deeply [ sort @in ], [ sort @names[0, 1] ], '... under the names install_ddl gives them';

  my $existing = $model->();
  my $src = { %$existing, foreign_keys => {} };
  my $add = DBIO::MySQL::Diff->new(source => $src, target => $model->())->as_sql;
  my @added = $add =~ /ADD CONSTRAINT `([^`]+)` FOREIGN KEY/g;
  is_deeply [ sort @added ], [ sort @names[0, 1] ], 'ADD CONSTRAINT of the diff: the same names' or diag $add;
}

# 4. composite foreign key columns follow the key of the target
{
  my $ddl = eval { DBIO::MySQL::DDL->install_ddl(schema_for(
    q => { cols => [qw/a b/], pk => [qw/b a/] },
    r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
      [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] })) };
  ok defined $ddl, 'primary key (b, a): installs' or diag $@;
  like $ddl // '', qr/CONSTRAINT `r_xb_ya_fk` FOREIGN KEY \(`xb`, `ya`\) REFERENCES `q`\(`b`, `a`\)/,
    '... the columns in the order of the key, the name from that order';

  my $unique = DBIO::MySQL::DDL->install_ddl(schema_for(
    q => { cols => [qw/id a b/], pk => ['id'], uniques => { q_ba => [qw/b a/] } },
    r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
      [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] }));
  like $unique, qr/FOREIGN KEY \(`xb`, `ya`\) REFERENCES `q`\(`b`, `a`\)/, 'a unique constraint (b, a) of the target gives the order as well';

  my $sorted = DBIO::MySQL::DDL->install_ddl(schema_for(
    q => { cols => [qw/a b/], pk => [qw/a b/] },
    r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
      [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] }));
  like $sorted, qr/CONSTRAINT `r_ya_xb_fk` FOREIGN KEY \(`ya`, `xb`\) REFERENCES `q`\(`a`, `b`\)/,
    'primary key (a, b): (a, b), the pairing with the referencing columns kept';
}

done_testing;
