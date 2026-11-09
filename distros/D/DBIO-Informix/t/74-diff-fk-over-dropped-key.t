use strict;
use warnings;
use Test::More;

# Offline (karr k27): a foreign key that stays but points at a unique
# constraint the diff drops. Informix takes the key along when the constraint
# goes (measured: a later DROP CONSTRAINT of the key is -623), so the key is
# dropped BEFORE the constraint and added again after it -- when the target
# model still has it. A key the target model no longer has stays an ordinary
# drop. (The same for a primary key dropped: t/76, karr k28.)

use DBIO::Informix::Diff;

sub col { +{ column_name => $_[0], data_type => 'integer', size => undef, not_null => 0, default_value => undef, is_pk => 0 } }
sub fk {
  my (%a) = @_;
  return { constraint_name => $a{name} // "$a{from}_$a{cols}[0]_fk", from_table => $a{from}, from_columns => $a{cols},
           to_table => $a{to}, to_columns => $a{to_cols}, on_delete => $a{on_delete} };
}
sub uc_ { +{ constraint_name => $_[0], columns => $_[1] } }
sub model {
  my (%m) = @_;
  my %cols = %{ $m{columns} };
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %cols },
    columns => { map { my $t = $_; $t => [ map { col($_) } @{ $cols{$t} } ] } keys %cols },
    indexes => {}, unique_constraints => $m{uniques} // {}, foreign_keys => $m{fks} // {},
  };
}
sub stmts { [ grep { /^(?:ALTER|CREATE|DROP)/ } split /\n/, DBIO::Informix::Diff->new(source => $_[0], target => $_[1])->as_sql ] }

my %cols = (p => [qw/id code/], c => [qw/id pcode/]);
my @fk = (fk(from => 'c', cols => ['pcode'], to => 'p', to_cols => ['code']));

# the constraint goes, the key stays
is_deeply stmts(
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', ['code']) ] }),
  model(columns => \%cols, fks => { c => \@fk }),
), [
  'ALTER TABLE c DROP CONSTRAINT c_pcode_fk;',
  'ALTER TABLE p DROP CONSTRAINT p_code;',
  'ALTER TABLE c ADD CONSTRAINT FOREIGN KEY (pcode) REFERENCES p(code) CONSTRAINT c_pcode_fk;',
], 'a surviving key over a dropped unique constraint: dropped first, added again last';

# the constraint changes (other columns), the key stays on the old columns
is_deeply stmts(
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', ['code']) ] }),
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', [qw/code id/]) ] }),
), [
  'ALTER TABLE c DROP CONSTRAINT c_pcode_fk;',
  'ALTER TABLE p DROP CONSTRAINT p_code;',
  'ALTER TABLE p ADD CONSTRAINT UNIQUE (code, id) CONSTRAINT p_code;',
  'ALTER TABLE c ADD CONSTRAINT FOREIGN KEY (pcode) REFERENCES p(code) CONSTRAINT c_pcode_fk;',
], 'a changed constraint: the same, the new constraint between';

# the key goes as well: one ordinary drop, no add
is_deeply stmts(
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', ['code']) ] }),
  model(columns => \%cols),
), [
  'ALTER TABLE c DROP CONSTRAINT c_pcode_fk;',
  'ALTER TABLE p DROP CONSTRAINT p_code;',
], 'a key the target does not have: the normal drop, once';

# a key over another constraint is left alone
is_deeply stmts(
  model(columns => { p => [qw/id code other/], c => \@{ $cols{c} } }, fks => { c => \@fk },
    uniques => { p => [ uc_('p_code', ['code']), uc_('p_other', ['other']) ] }),
  model(columns => { p => [qw/id code other/], c => \@{ $cols{c} } }, fks => { c => \@fk },
    uniques => { p => [ uc_('p_code', ['code']) ] }),
), [ 'ALTER TABLE p DROP CONSTRAINT p_other;' ], 'a key over a constraint that stays is not touched';

# no change, no operation
is_deeply stmts(
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', ['code']) ] }),
  model(columns => \%cols, fks => { c => \@fk }, uniques => { p => [ uc_('p_code', ['code']) ] }),
), [], 'nothing dropped: nothing rebuilt';

done_testing;
