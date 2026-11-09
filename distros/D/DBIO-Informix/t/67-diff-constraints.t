use strict;
use warnings;
use Test::More;

# Offline (karr k25): foreign keys and unique constraints in the diff of two
# models. They are compared by what they say, not by name (karr k22): the name
# the server gives (r<tabid>_<n>, u<tabid>_<n>) differs per database. Each
# change is a statement, never a refusal, and the order is one the server can
# run (a key over a unique constraint goes before its change and comes back).

use DBIO::Informix::Diff;

sub col { +{ column_name => $_[0], data_type => 'integer', size => undef, not_null => 0, default_value => undef, is_pk => 0 } }
sub fk {
  my (%a) = @_;
  return { constraint_name => $a{name} // "$a{from}_$a{cols}[0]_fk", from_table => $a{from}, from_columns => $a{cols},
           to_table => $a{to}, to_columns => $a{to_cols} // ['id'], on_delete => $a{on_delete} };
}
sub uc_ { +{ constraint_name => $_[0], columns => $_[1] } }
sub model {
  my (%m) = @_;
  my %cols = %{ $m{columns} };
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %cols },
    columns => { map { my $t = $_; $t => [ map { col($_) } @{ $cols{$t} } ] } keys %cols },
    indexes => $m{indexes} // {}, unique_constraints => $m{uniques} // {}, foreign_keys => $m{fks} // {},
  };
}
sub diff { DBIO::Informix::Diff->new(source => $_[0], target => $_[1]) }
sub stmts { [ grep { /^(?:ALTER|CREATE|DROP)/ } split /\n/, $_[0]->as_sql ] }

{
  my $d = diff(model(columns => {}), model(
    columns => { a => [qw/id b_id/], b => [qw/id a_id code/] },
    fks     => { a => [ fk(from => 'a', cols => ['b_id'], to => 'b') ],
                 b => [ fk(from => 'b', cols => ['a_id'], to => 'a', on_delete => 'CASCADE') ] },
    uniques => { b => [ uc_('b_code', ['code']) ] },
  ));
  my @stmt = @{ stmts($d) };
  is_deeply [ map { /^(CREATE TABLE|ALTER TABLE)/ && $1 } @stmt ],
    ['CREATE TABLE', 'CREATE TABLE', 'ALTER TABLE', 'ALTER TABLE', 'ALTER TABLE'],
    'both tables first, then the constraints';
  like $stmt[2], qr/^ALTER TABLE b ADD CONSTRAINT UNIQUE \(code\) CONSTRAINT b_code;$/, 'the unique constraint comes before the keys';
  like $stmt[3], qr/^ALTER TABLE a ADD CONSTRAINT FOREIGN KEY \(b_id\) REFERENCES b\(id\) CONSTRAINT a_b_id_fk;$/, 'a -> b';
  like $stmt[4], qr/^ALTER TABLE b ADD CONSTRAINT FOREIGN KEY \(a_id\) REFERENCES a\(id\) ON DELETE CASCADE CONSTRAINT b_a_id_fk;$/,
    'b -> a closes the cycle, with its action';
  like $d->summary, qr/a_b_id_fk/, 'summary names the key';
  like $d->summary, qr/unique: \(code\) on b/, '... and the unique constraint';
}

{
  my $src = model(columns => { t => [qw/id c/], o => ['id'] },
    fks => { t => [ fk(from => 't', cols => ['c'], to => 'o', name => 'r136_5') ] },
    uniques => { t => [ uc_('u136_41', ['c']) ] });
  my $tgt = model(columns => { t => [qw/id c/], o => ['id'] },
    fks => { t => [ fk(from => 't', cols => ['c'], to => 'o', name => 't_c_fk') ] },
    uniques => { t => [ uc_('t_c', ['c']) ] });
  ok !diff($src, $tgt)->has_changes, 'the same constraints under other names: no change';
}

for my $case (
  [ 'a key the database lacks',
    { fks => {} }, { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } },
    [ 'ALTER TABLE t ADD CONSTRAINT FOREIGN KEY (c) REFERENCES o(id) CONSTRAINT t_c_fk;' ] ],
  [ 'a key the schema does not have',
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } }, { fks => {} },
    [ 'ALTER TABLE t DROP CONSTRAINT t_c_fk;' ] ],
  [ 'a key with another action',
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } },
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o', on_delete => 'CASCADE') ] } },
    [ 'ALTER TABLE t DROP CONSTRAINT t_c_fk;',
      'ALTER TABLE t ADD CONSTRAINT FOREIGN KEY (c) REFERENCES o(id) ON DELETE CASCADE CONSTRAINT t_c_fk;' ] ],
  [ 'a unique constraint the database lacks',
    { uniques => {} }, { uniques => { t => [ uc_('t_c', ['c']) ] } },
    [ 'ALTER TABLE t ADD CONSTRAINT UNIQUE (c) CONSTRAINT t_c;' ] ],
  [ 'a unique constraint the schema does not have',
    { uniques => { t => [ uc_('u', ['c']) ] } }, { uniques => {} },
    [ 'ALTER TABLE t DROP CONSTRAINT u;' ] ],
  [ 'a unique constraint over other columns',
    { uniques => { t => [ uc_('u', ['c']) ] } }, { uniques => { t => [ uc_('u', ['c', 'id']) ] } },
    [ 'ALTER TABLE t DROP CONSTRAINT u;', 'ALTER TABLE t ADD CONSTRAINT UNIQUE (c, id) CONSTRAINT u;' ] ],
  [ 'a unique constraint with its columns in another order',
    { uniques => { t => [ uc_('u', ['c', 'id']) ] } }, { uniques => { t => [ uc_('u', ['id', 'c']) ] } },
    [ 'ALTER TABLE t DROP CONSTRAINT u;', 'ALTER TABLE t ADD CONSTRAINT UNIQUE (id, c) CONSTRAINT u;' ] ],
) {
  my ($label, $s, $t, $want) = @$case;
  my $d = diff(model(columns => { t => [qw/id c/], o => ['id'] }, %$s),
               model(columns => { t => [qw/id c/], o => ['id'] }, %$t));
  ok $d->has_changes, "$label: reported";
  is_deeply stmts($d), $want, '... and written as ALTER TABLE statements, not refused';
}

{
  # a key and the unique constraint it references move together: the key goes
  # first (the server drops a referenced constraint's key with it, -623 for a
  # second drop), comes back last
  my $src = model(columns => { p => [qw/id code other/], c => [qw/id pcode/] },
    fks     => { c => [ fk(from => 'c', cols => ['pcode'], to => 'p', to_cols => ['code']) ] },
    uniques => { p => [ uc_('p_code', ['code']) ] });
  my $tgt = model(columns => { p => [qw/id code other/], c => [qw/id pcode/] },
    fks     => { c => [ fk(from => 'c', cols => ['pcode'], to => 'p', to_cols => ['other']) ] },
    uniques => { p => [ uc_('p_other', ['other']) ] });
  is_deeply stmts(diff($src, $tgt)), [
    'ALTER TABLE c DROP CONSTRAINT c_pcode_fk;',
    'ALTER TABLE p DROP CONSTRAINT p_code;',
    'ALTER TABLE p ADD CONSTRAINT UNIQUE (other) CONSTRAINT p_other;',
    'ALTER TABLE c ADD CONSTRAINT FOREIGN KEY (pcode) REFERENCES p(other) CONSTRAINT c_pcode_fk;',
  ], 'the key goes first, the new unique constraint, the key last' or diag explain stmts(diff($src, $tgt));
}

{
  my $src = model(columns => { t => [qw/id c old/], o => ['id'], gone => ['id'] },
    fks     => { t => [ fk(from => 't', cols => ['c'], to => 'o'), fk(from => 't', cols => ['old'], to => 'gone') ] },
    uniques => { t => [ uc_('u_old', ['old']) ] });
  my $tgt = model(columns => { t => [qw/id c new/], o => ['id'], fresh => ['id'] },
    fks     => { t => [ fk(from => 't', cols => ['c'], to => 'o', on_delete => 'CASCADE'), fk(from => 't', cols => ['new'], to => 'fresh') ] },
    uniques => { t => [ uc_('u_new', ['new']) ] });
  my @sql = @{ stmts(diff($src, $tgt)) };
  is_deeply [ map { s/ (?:FOREIGN KEY|UNIQUE|integer|INTEGER|\().*|;$//r } @sql ], [
    'ALTER TABLE t DROP CONSTRAINT t_c_fk',
    'ALTER TABLE t DROP CONSTRAINT t_old_fk',
    'ALTER TABLE t DROP CONSTRAINT u_old',
    'CREATE TABLE fresh',
    'DROP TABLE gone',
    'ALTER TABLE t ADD',
    'ALTER TABLE t DROP',
    'ALTER TABLE t ADD CONSTRAINT',
    'ALTER TABLE t ADD CONSTRAINT',
    'ALTER TABLE t ADD CONSTRAINT',
  ], 'keys out, tables, columns, unique constraints in, foreign keys in' or diag join "\n", @sql;
}

done_testing;
