use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff ();
use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::ForeignKey;

# karr k106: a foreign key has a fixed name, the same in install_ddl and in
# both write paths of the diff.
#
# WHY IT MATTERS. Without a name the server names a constraint <table>_ibfk_N,
# N by the position in the CREATE TABLE. install_ddl and the upgrade put the
# foreign keys of a table in different places (an upgrade out of an empty
# database breaks a cycle at another table than install_ddl), so the same
# schema ended with differently named constraints, and the diff after an
# upgrade was not empty: drop the one, add the other, for ever. What this file
# claims:
#   1. the name is <table>_<columns of the key, in key order>_fk, and a
#      CREATE TABLE / ADD CONSTRAINT of the diff writes the very same name;
#   2. a name over 64 characters (the limit of the servers) is cut and ends in
#      a hash of the full name, so two long names that start alike stay apart;
#   3. two relationships that are one foreign key become one constraint, and
#      foreign keys that only meet in a name are told apart (t/106);
#   4. on_delete / on_update => '' is "the database's default" (core,
#      DBIO::Relationship::Base) and writes nothing, it does not throw.

my $name = \&DBIO::MySQL::DDL::foreign_key_name;
is $name->('child', 'parent_id'), 'child_parent_id_fk', 'table_column_fk';
is $name->('child', 'a', 'b'), 'child_a_b_fk', '... columns in the order given';
is $name->('child', 'b', 'a'), 'child_b_a_fk', '... so key order shows';

my $long = $name->('t' x 40, 'c' x 40);
is length($long), 64, 'over 64 characters: cut to 64';
like $long, qr/_[0-9a-f]{8}\z/, '... ending in 8 hex digits of a hash';
isnt $name->('t' x 40, 'c' x 40), $name->('t' x 40, ('c' x 39) . 'd'), '... two long names that differ only at the end stay apart';
is $name->('t' x 40, 'c' x 40), $long, '... and the name is stable';
is $name->('t' x 30, 'c' x 30), ('t' x 30) . '_' . ('c' x 30) . '_fk', 'exactly 64 characters is kept whole';

my $n = 0;
sub schema_for {
  my ($rels) = @_;       # [ [ name, cond, attrs ] ... ]
  my $ns = 'K106Name::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (qw/Child Parent/) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $m);
    $class->add_columns(id => { data_type => 'integer' },
      $m eq 'Child' ? (map { $_ => { data_type => 'integer', is_nullable => 1 } } qw/parent_id other_id/) : ());
    $class->set_primary_key('id');
    $class->belongs_to($_->[0] => "${ns}::Result::Parent", $_->[1], $_->[2] // {}) for $m eq 'Child' ? @$rels : ();
    $ns->register_class($m => $class);
  }
  return $ns;
}

my $ddl = DBIO::MySQL::DDL->install_ddl(schema_for([ [ parent => { 'foreign.id' => 'self.parent_id' } ] ]));
like $ddl, qr/CONSTRAINT `child_parent_id_fk` FOREIGN KEY \(`parent_id`\) REFERENCES `parent`\(`id`\)/,
  'install_ddl names the foreign key';
unlike $ddl, qr/ibfk/, '... no server name';

my $one = eval { DBIO::MySQL::DDL->install_ddl(schema_for([
  [ one => { 'foreign.id' => 'self.parent_id' } ], [ two => { 'foreign.id' => 'self.parent_id' } ] ])) };
ok defined $one, 'two relationships over one column set to one target: not refused' or diag $@;
is_deeply [ ($one // '') =~ /CONSTRAINT `([^`]+)` FOREIGN KEY/g ], ['child_parent_id_fk'],
  '... one constraint under the plain name';

ok eval { DBIO::MySQL::DDL->install_ddl(schema_for([
  [ one => { 'foreign.id' => 'self.parent_id' } ], [ two => { 'foreign.id' => 'self.other_id' } ] ])); 1 },
  'different columns: no clash' or diag $@;

# B3: '' is the database's default
for my $attr (qw/on_delete on_update/) {
  my $out = eval { DBIO::MySQL::DDL->install_ddl(schema_for([ [ parent => { 'foreign.id' => 'self.parent_id' }, { $attr => '' } ] ])) };
  ok defined $out, "$attr => '' is not refused" or diag $@;
  unlike $out // '', qr/ON (?:DELETE|UPDATE)/, '... and writes nothing';
}

# The diff writes the same name
{
  my %fk = (from_columns => ['parent_id'], to_table => 'parent', to_columns => ['id']);
  my $create = sub { DBIO::MySQL::Diff::Table->new(
    action => 'create', table_name => 'child', table_info => {},
    columns => [ { column_name => 'id', column_type => 'bigint', is_pk => 1 }, { column_name => 'parent_id', column_type => 'bigint' } ],
    foreign_keys => [ { %fk, @_ } ])->as_sql };
  like $create->(), qr/CONSTRAINT `child_parent_id_fk` FOREIGN KEY \(`parent_id`\)/, 'CREATE TABLE of the diff: the fixed name';
  like $create->(constraint_name => 'given_fk'), qr/CONSTRAINT `given_fk` FOREIGN KEY/, '... a name the model carries is kept';
  unlike $create->(), qr/ibfk/, '... never a server name';
  my $add = sub { DBIO::MySQL::Diff::ForeignKey->new(action => 'add', table_name => 'child', fk_info => { %fk }, @_)->as_sql };
  like $add->(), qr/ADD CONSTRAINT `child_parent_id_fk` FOREIGN KEY/, 'ADD of the diff: the fixed name';
  like $add->(constraint_name => 'given_fk'), qr/ADD CONSTRAINT `given_fk` FOREIGN KEY/, '... a name the model carries is kept';
}

done_testing;
