use strict;
use warnings;
use Test::More;

# The order of the operations is the order the server can run them in
# (measured against Informix 15.0.1, karr k20): dropping a column drops the
# constraints and indexes on it, dropping a table drops its indexes -- a
# later DROP CONSTRAINT / DROP INDEX then fails with -623 / -319. So the
# drops of foreign keys and indexes come first, their creation last.

use DBIO::Informix::Diff;

sub col { +{ column_name => $_[0], data_type => 'integer' } }

my $source = {
  tables       => { child => {}, parent => {}, gone => {} },
  columns      => {
    parent => [ col('id') ],
    child  => [ col('a'), col('pid') ],
    gone   => [ col('x') ],
  },
  indexes      => {
    child => { child_a => { index_name => 'child_a', unique => 0, columns => ['a'] } },
    gone  => { gone_x  => { index_name => 'gone_x',  unique => 0, columns => ['x'] } },
  },
  foreign_keys => {
    child => [ { fk_name => 'fk1', from_columns => ['pid'], to_table => 'parent', to_columns => ['id'] } ],
  },
};
my $target = {
  tables       => { child => {}, parent => {}, fresh => {} },
  columns      => {
    parent => [ col('id') ],
    child  => [ col('a'), col('b') ],      # pid dropped, b added
    fresh  => [ col('y') ],
  },
  indexes      => {
    child => { child_b => { index_name => 'child_b', unique => 0, columns => ['b'] } },
  },
  foreign_keys => {
    child => [ { fk_name => 'fk2', from_columns => ['b'], to_table => 'parent', to_columns => ['id'] } ],
  },
};

my @sql = map { s/\s+/ /gr } grep { /\S/ } split /(?<=;)\s*\n/,
  DBIO::Informix::Diff->new(source => $source, target => $target)->as_sql;

my ($i) = sub { my $re = shift; (grep { $sql[$_] =~ $re } 0 .. $#sql)[0] };

my $fk_drop   = $i->(qr/DROP CONSTRAINT/);
my $idx_drop  = $i->(qr/DROP INDEX child_a/);
my $idx_gone  = $i->(qr/DROP INDEX gone_x/);
my $col_drop  = $i->(qr/DROP \(pid\)/);
my $tab_drop  = $i->(qr/DROP TABLE gone/);
my $col_add   = $i->(qr/ADD \(b integer\)/);
my $idx_new   = $i->(qr/CREATE INDEX child_b/);
my $fk_add    = $i->(qr/ADD CONSTRAINT FOREIGN KEY/);

ok defined $_, 'operation present' for $fk_drop, $idx_drop, $idx_gone, $col_drop, $tab_drop, $col_add, $idx_new, $fk_add;
cmp_ok $fk_drop,  '<', $col_drop, 'DROP CONSTRAINT before the DROP of its column';
cmp_ok $idx_drop, '<', $col_drop, 'DROP INDEX before column drops';
cmp_ok $idx_gone, '<', $tab_drop, 'DROP INDEX of a dropped table before DROP TABLE';
cmp_ok $col_add,  '<', $idx_new,  'index created after the column exists';
cmp_ok $idx_new,  '<', $fk_add,   'foreign keys last';

done_testing;
