use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# karr k84: install_ddl writes the tables parents first.
#
# WHY IT MATTERS. It used to write them in source-name order, so a child whose
# source name sorts before its parent's stood ahead of the table it references
# and MySQL refused the CREATE TABLE ("Failed to open the referenced table").
# What this file claims:
#   1. a child source sorting before its parent comes after it;
#   2. tables free to go keep source-name order (the script is deterministic);
#   3. a table referencing itself is no dependency and stays in its place;
#   4. a cycle: tables in source-name order, the foreign keys that close it
#      out of CREATE TABLE and added by ALTER TABLE after all CREATE TABLEs.
# Whether the servers take it: t/92-ddl-foreign-key-order-live.t.

my $n = 0;
sub ddl_for {
  my (%src) = @_;     # Moniker => { table, fk => [[ column => Moniker ]] }
  my $ns = 'K84Off::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (sort keys %src) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($src{$m}{table});
    $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
      map { $_->[0] => { data_type => 'integer', is_nullable => 1 } } @{ $src{$m}{fk} // [] });
    $class->set_primary_key('id');
    for my $fk (@{ $src{$m}{fk} // [] }) {
      $class->belongs_to("rel_$fk->[0]" => "${ns}::Result::$fk->[1]", { 'foreign.id' => "self.$fk->[0]" });
    }
    $ns->register_class($m => $class);
  }
  return DBIO::MySQL::DDL->install_ddl($ns);
}
sub order_of {
  my ($ddl) = @_;
  return [ map { /^(CREATE TABLE|ALTER TABLE) `(\w+)`/ ? "$1 $2" : () } split /\n\n/, $ddl ];
}

is_deeply order_of(ddl_for(
  A_Child => { table => 'child', fk => [[ parent_id => 'Z_Parent' ]] },
  Z_Parent => { table => 'parent' },
)), [ 'CREATE TABLE parent', 'CREATE TABLE child' ], 'a child sorting before its parent comes after it';

is_deeply order_of(ddl_for(
  B => { table => 'b' }, A => { table => 'a' }, C => { table => 'c', fk => [[ a_id => 'A' ]] },
)), [ 'CREATE TABLE a', 'CREATE TABLE b', 'CREATE TABLE c' ], 'free tables keep source-name order';

is_deeply order_of(ddl_for(
  A_Tree => { table => 'tree', fk => [[ parent_id => 'A_Tree' ]] },
  B_Leaf => { table => 'leaf', fk => [[ tree_id => 'A_Tree' ]] },
)), [ 'CREATE TABLE tree', 'CREATE TABLE leaf' ], 'a self reference is no dependency';
like ddl_for(A_Tree => { table => 'tree', fk => [[ parent_id => 'A_Tree' ]] }),
  qr/FOREIGN KEY \(`parent_id`\) REFERENCES `tree`\(`id`\)\n\)/, '... and stays inside its CREATE TABLE';

my $cycle = ddl_for(
  A => { table => 'a', fk => [[ b_id => 'B' ]] },
  B => { table => 'b', fk => [[ a_id => 'A' ]] },
  C => { table => 'c' },
);
is_deeply order_of($cycle), [ 'CREATE TABLE c', 'CREATE TABLE a', 'CREATE TABLE b', 'ALTER TABLE a' ],
  'a cycle: the free table first, then the first of the cycle by source name, its foreign key added afterwards';
like $cycle, qr/ALTER TABLE `a` ADD CONSTRAINT `a_b_id_fk` FOREIGN KEY \(`b_id`\) REFERENCES `b`\(`id`\);/, '... as ALTER TABLE ADD FOREIGN KEY';
like $cycle, qr/CREATE TABLE `b` \(.*FOREIGN KEY \(`a_id`\) REFERENCES `a`\(`id`\)\n\)/s,
  '... and the other one keeps its foreign key inline';
unlike $cycle, qr/CREATE TABLE `a` \([^;]*FOREIGN KEY/, '... the first has none inline';

is ddl_for(A => { table => 'a', fk => [[ b_id => 'B' ]] }, B => { table => 'b', fk => [[ a_id => 'A' ]] }),
  ddl_for(A => { table => 'a', fk => [[ b_id => 'B' ]] }, B => { table => 'b', fk => [[ a_id => 'A' ]] }),
  'the same schema gives the same script';

# karr k106 (K10): the cycle is broken at a table that is on it, not at the
# first table that merely waits for one. The source A (table x) comes first by name
# and references B; B and C reference each other. Holding the foreign key of x
# back would be for nothing: B is the table to break at.
my $waiting = ddl_for(
  A => { table => 'x', fk => [[ a_id => 'B' ]] },
  B => { table => 'a', fk => [[ b_id => 'C' ]] },
  C => { table => 'b', fk => [[ a_id => 'B' ]] },
);
is_deeply order_of($waiting), [ 'CREATE TABLE a', 'CREATE TABLE x', 'CREATE TABLE b', 'ALTER TABLE a' ],
  'a table waiting on a cycle is not where it is broken: the cycle is, at its first table';
like $waiting, qr/CREATE TABLE `x` \(.*CONSTRAINT `x_a_id_fk` FOREIGN KEY \(`a_id`\) REFERENCES `a`\(`id`\)\n\)/s,
  '... and the foreign key of the waiting table stays inline';

# Source names and table names in different order (karr k106): A is table zz, B is
# aa, C is cc; aa references zz and cc.
my $mixed = ddl_for(
  A => { table => 'zz', fk => [[ aa_id => 'B' ]] },
  B => { table => 'aa', fk => [[ zz_id => 'A' ], [ cc_id => 'C' ]] },
  C => { table => 'cc' },
);
is_deeply order_of($mixed), [ 'CREATE TABLE cc', 'CREATE TABLE zz', 'CREATE TABLE aa', 'ALTER TABLE zz' ],
  'source names and table names in another order: the cycle is broken at the first source name (zz)';
like $mixed, qr/CREATE TABLE `aa` \(.*CONSTRAINT `aa_cc_id_fk` FOREIGN KEY.*CONSTRAINT `aa_zz_id_fk` FOREIGN KEY/s,
  '... aa has both its foreign keys inline, named by table and column';

done_testing;
