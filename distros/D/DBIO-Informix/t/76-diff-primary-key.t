use strict;
use warnings;
use Test::More;

# Offline (karr k28): the diff compares the primary key. The model carries it
# as is_pk / pk_position of the columns (and the name as primary_key_name of
# the table), not as a section of its own, and it was not compared: a changed
# key never reached the database. Informix has no DROP PRIMARY KEY and
# refuses a second key (-704, measured on 15.0.1), so a changed key is the old
# one dropped by name and the new one added, and a foreign key that stays over
# the dropped key goes first and comes back last (the server takes it along:
# a later DROP CONSTRAINT of it is -623, karr k27).

use DBIO::Informix::Diff;

sub col {
  my ($name, $pos) = @_;
  return +{ column_name => $name, data_type => 'integer', size => undef, not_null => 0,
            default_value => undef, is_pk => ($pos ? 1 : 0), pk_position => $pos // 0 };
}
sub fk {
  my (%a) = @_;
  return { constraint_name => $a{name}, from_table => $a{from}, from_columns => $a{cols},
           to_table => $a{to}, to_columns => $a{to_cols} };
}
# %m: columns => { table => [ [name, pk_position], ... ] }, pk_names => { table => name }
sub model {
  my (%m) = @_;
  return {
    tables  => { map { my $t = $_; $t => { table_name => $t, kind => 'table',
      (exists $m{pk_names}{$t} ? (primary_key_name => $m{pk_names}{$t}) : ()) } } keys %{ $m{columns} } },
    columns => { map { my $t = $_; $t => [ map { col(@$_) } @{ $m{columns}{$t} } ] } keys %{ $m{columns} } },
    indexes => {}, unique_constraints => $m{uniques} // {}, foreign_keys => $m{fks} // {},
  };
}
sub stmts { [ grep { /^(?:ALTER|CREATE|DROP)/ } split /\n/, DBIO::Informix::Diff->new(source => $_[0], target => $_[1])->as_sql ] }

my %names = (pk_names => { t => 'u1_2' });

is_deeply stmts(
  model(columns => { t => [ ['a', 1], ['b'] ] }, %names),
  model(columns => { t => [ ['a', 1], ['b'] ] }, %names),
), [], 'the same key: no operation';

is_deeply stmts(
  model(columns => { t => [ ['a', 1], ['b'] ] }, %names),
  model(columns => { t => [ ['a'], ['b', 1] ] }),
), [
  'ALTER TABLE t DROP CONSTRAINT u1_2;',
  'ALTER TABLE t ADD CONSTRAINT PRIMARY KEY (b);',
], 'another column: the old key dropped by its name, the new one added without one';

is_deeply stmts(
  model(columns => { t => [ ['a', 1], ['b', 2] ] }, %names),
  model(columns => { t => [ ['a', 2], ['b', 1] ] }),
), [
  'ALTER TABLE t DROP CONSTRAINT u1_2;',
  'ALTER TABLE t ADD CONSTRAINT PRIMARY KEY (b, a);',
], 'the same columns in another order is another key (it is the target a foreign key must match in order)';

is_deeply stmts(
  model(columns => { t => [ ['a'], ['b'] ] }),
  model(columns => { t => [ ['a', 1], ['b'] ] }),
), [ 'ALTER TABLE t ADD CONSTRAINT PRIMARY KEY (a);' ], 'a table that gains a key: only the add';

is_deeply stmts(
  model(columns => { t => [ ['a', 1], ['b'] ] }, %names),
  model(columns => { t => [ ['a'], ['b'] ] }),
), [ 'ALTER TABLE t DROP CONSTRAINT u1_2;' ], 'a table that loses its key: only the drop';

# a key to drop without a name in the model cannot be written
{
  my $diff = DBIO::Informix::Diff->new(
    source => model(columns => { zz_tab => [ ['a', 1] ] }),
    target => model(columns => { zz_tab => [ ['a'] ] }),
  );
  my $err = eval { $diff->as_sql; 1 } ? '' : "$@";
  like $err, qr/zz_tab/, 'a primary key to drop without primary_key_name: dies, naming the table';
}

# tables on one side only get their key in CREATE TABLE and nothing more
{
  my $sql = DBIO::Informix::Diff->new(
    source => model(columns => { t => [ ['a', 1] ] }, %names),
    target => model(columns => { t => [ ['a', 1] ], n => [ ['id', 1] ] }),
  )->as_sql;
  like $sql, qr/PRIMARY KEY \(id\)\n\);/, 'a new table: its key is in the CREATE TABLE ...';
  unlike $sql, qr/ADD CONSTRAINT PRIMARY KEY/, '... and gets no second statement for it';
  my $gone = DBIO::Informix::Diff->new(
    source => model(columns => { t => [ ['a', 1] ], g => [ ['id', 1] ] }, pk_names => { t => 'u1_2', g => 'u1_3' }),
    target => model(columns => { t => [ ['a', 1] ] }),
  )->as_sql;
  unlike $gone, qr/DROP CONSTRAINT/, 'a dropped table takes its key with it';
}

# a foreign key that stays over the dropped key: dropped first, added last
{
  my @fk = (fk(name => 'c_p_fk', from => 'c', cols => ['pa'], to => 'p', to_cols => ['a']));
  my %cols = (p => [ ['a', 1], ['b'] ], c => [ ['id', 1], ['pa'] ]);
  my %want = (p => [ ['a'], ['b', 1] ], c => [ ['id', 1], ['pa'] ]);
  is_deeply stmts(
    model(columns => \%cols, fks => { c => \@fk }, pk_names => { p => 'u1_p', c => 'u1_c' }),
    model(columns => \%want, fks => { c => \@fk }),
  ), [
    'ALTER TABLE c DROP CONSTRAINT c_p_fk;',
    'ALTER TABLE p DROP CONSTRAINT u1_p;',
    'ALTER TABLE p ADD CONSTRAINT PRIMARY KEY (b);',
    'ALTER TABLE c ADD CONSTRAINT FOREIGN KEY (pa) REFERENCES p(a) CONSTRAINT c_p_fk;',
  ], 'a key that stays over a dropped primary key: dropped before it, added after the new one';

  # the key goes as well: one ordinary drop, nothing is rebuilt
  is_deeply stmts(
    model(columns => \%cols, fks => { c => \@fk }, pk_names => { p => 'u1_p', c => 'u1_c' }),
    model(columns => \%want, pk_names => {}),
  ), [
    'ALTER TABLE c DROP CONSTRAINT c_p_fk;',
    'ALTER TABLE p DROP CONSTRAINT u1_p;',
    'ALTER TABLE p ADD CONSTRAINT PRIMARY KEY (b);',
  ], 'a key the target does not have: the normal drop, not rebuilt';
}

# the key is added before the unique constraints and keys that may rest on it
{
  my @fk = (fk(name => 'c_p_fk', from => 'c', cols => ['pa'], to => 'p', to_cols => ['a']));
  my $out = stmts(
    model(columns => { p => [ ['a'] ], c => [ ['id', 1], ['pa'] ] }, pk_names => { c => 'u1_c' }),
    model(columns => { p => [ ['a', 1] ], c => [ ['id', 1], ['pa'] ] }, fks => { c => \@fk }),
  );
  is_deeply $out, [
    'ALTER TABLE p ADD CONSTRAINT PRIMARY KEY (a);',
    'ALTER TABLE c ADD CONSTRAINT FOREIGN KEY (pa) REFERENCES p(a) CONSTRAINT c_p_fk;',
  ], 'a new key precedes the foreign key that references it';
}

done_testing;
