use strict;
use warnings;
use Test::More;

use DBIO::DB2::Diff;

# OFFLINE (karr k57, conformance case diff-indexed-column-dropped, core karr
# dbio k370). Db2 drops an index together with a column it covers, so a
# DROP INDEX behind the DROP COLUMN found nothing (SQL0204N) and the upgrade
# stopped. The diff writes no DROP INDEX for an index that covers a column the
# same diff drops; an index on a column that stays is dropped as before.

sub col { { column_name => $_[0], catalog_type => 'INTEGER', catalog_size => 4, not_null => 0, @_[1 .. $#_] } }
sub model {
  my ($cols, $indexes) = @_;
  return {
    tables => { wide => { table_name => 'wide', kind => 'table' } },
    columns => { wide => [ map { col($_) } @$cols ] },
    indexes => { wide => $indexes }, foreign_keys => {}, unique_constraints => {},
  };
}
sub sql {
  my ($from, $to) = @_;
  return DBIO::DB2::Diff->new(source => $from, target => $to)->as_sql;
}

my %idx = (
  by_a  => { columns => ['a'],      is_unique => 0 },
  by_ab => { columns => ['a', 'b'], is_unique => 0 },
  by_c  => { columns => ['c'],      is_unique => 0 },
);

my $sql = sql(model([qw(id a b c)], { %idx }), model([qw(id c)], { by_c => $idx{by_c} }));
like $sql, qr/DROP COLUMN "a"/, 'the column is dropped';
unlike $sql, qr/DROP INDEX/, '... and no DROP INDEX is written for the indexes that covered it, one column or several';

$sql = sql(model([qw(id a b c)], { %idx }), model([qw(id a b c)], { by_a => $idx{by_a} }));
like $sql, qr/DROP INDEX "by_ab";/, 'an index on columns that stay is dropped as before';
like $sql, qr/DROP INDEX "by_c";/, '... each of them';

$sql = sql(model([qw(id a c)], { %idx{qw(by_a by_c)} }), model([qw(id a)], { by_a => $idx{by_a} }));
like $sql, qr/DROP COLUMN "c"/, 'a dropped column';
unlike $sql, qr/DROP INDEX "by_c"/, '... takes its index with it';
unlike $sql, qr/DROP INDEX "by_a"/, '... and leaves the other one';

# the same for a UNIQUE constraint over a dropped column
sub uc_model {
  my ($cols, $ucs) = @_;
  my $m = model($cols, {});
  $m->{unique_constraints} = { wide => $ucs };
  return $m;
}
$sql = sql(uc_model([qw(id a b)], [ [ uq_ab => [qw(a b)] ] ]), uc_model([qw(id b)], []));
like $sql, qr/DROP COLUMN "a"/, 'a column in a UNIQUE constraint is dropped';
unlike $sql, qr/DROP UNIQUE/, '... and the constraint, which goes with it, is not dropped';
$sql = sql(uc_model([qw(id a b)], [ [ uq_ab => [qw(a b)] ] ]), uc_model([qw(id a b)], []));
like $sql, qr/DROP UNIQUE "uq_ab"/, 'a constraint over columns that stay is dropped as before';

done_testing;
