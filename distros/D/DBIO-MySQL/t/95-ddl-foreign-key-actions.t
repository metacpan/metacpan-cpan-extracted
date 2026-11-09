use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# karr k106: install_ddl writes ON UPDATE / ON DELETE of a belongs_to.
#
# WHY IT MATTERS. It wrote a bare FOREIGN KEY, so a freshly installed database
# had other foreign key semantics than one the upgrade path (Diff::ForeignKey,
# which writes the actions) had made. What this file claims:
#   1. cascade / set null / restrict of on_delete and on_update
#      reach the DDL, in any case, ON UPDATE before ON DELETE;
#   2. NO ACTION and an unset attribute write nothing (the server's default);
#   3. a word that is no action throws a DBIO exception naming the
#      relationship, instead of a syntax error from the server;
#   4. the same holds for a foreign key closing a cycle (ALTER TABLE);
#   5. SET DEFAULT is refused loudly, in the install and in both write paths of
#      the diff: the servers take the DDL but never run the action (MySQL acts
#      as RESTRICT, MariaDB stores RESTRICT), so a schema that asks for it
#      would get a behaviour it did not ask for.
# What the servers make of them: t/96-ddl-foreign-key-actions-live.t.

my $n = 0;
sub ddl_for {
  my (%attrs) = @_;
  my $ns = 'K106Off::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (qw/Child Parent/) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $m);
    $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
      $m eq 'Child' ? (parent_id => { data_type => 'integer', is_nullable => 1 }) : ());
    $class->set_primary_key('id');
    $class->belongs_to(parent => "${ns}::Result::Parent", { 'foreign.id' => 'self.parent_id' }, \%attrs)
      if $m eq 'Child';
    $ns->register_class($m => $class);
  }
  return DBIO::MySQL::DDL->install_ddl($ns);
}
my $fk = qr/FOREIGN KEY \(`parent_id`\) REFERENCES `parent`\(`id`\)/;

like ddl_for(on_delete => 'cascade'), qr/$fk ON DELETE CASCADE\n/, 'on_delete cascade';
like ddl_for(on_delete => 'SET NULL'), qr/$fk ON DELETE SET NULL\n/, 'on_delete SET NULL';
like ddl_for(on_delete => 'Restrict'), qr/$fk ON DELETE RESTRICT\n/, 'on_delete restrict, any case';
like ddl_for(on_update => 'cascade'), qr/$fk ON UPDATE CASCADE\n/, 'on_update cascade';
like ddl_for(on_delete => 'cascade', on_update => 'set null'),
  qr/$fk ON UPDATE SET NULL ON DELETE CASCADE\n/, 'both: ON UPDATE before ON DELETE, as the diff path';

unlike ddl_for(on_delete => 'NO ACTION', on_update => 'no action'), qr/ON (?:DELETE|UPDATE)/, 'NO ACTION writes nothing';
unlike ddl_for(), qr/ON (?:DELETE|UPDATE)/, 'unset writes nothing';
unlike ddl_for(on_delete => undef), qr/ON (?:DELETE|UPDATE)/, 'undef writes nothing';

for my $attr (qw/on_delete on_update/) {
  eval { ddl_for($attr => 'explode') };
  like "$@", qr/relationship 'parent' of Child declares \Q$attr\E => 'explode', which is no foreign key action/,
    "an unknown $attr is refused by the driver";
}

for my $attr (qw/on_delete on_update/) {
  for my $word ('set default', 'SET DEFAULT', 'Set_Default') {
    eval { ddl_for($attr => $word) };
    like "$@", qr/relationship 'parent' of Child declares \Q$attr\E => '\Q$word\E'.*SET DEFAULT/,
      "install refuses $attr => '$word', naming the relationship";
  }
}

# A cycle: the closing foreign key is an ALTER TABLE and carries the action too.
{
  my $ns = 'K106Off::Cycle';
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (qw/A B/) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    my $o = $m eq 'A' ? 'B' : 'A';
    $class->table(lc $m);
    $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
      lc($o).'_id' => { data_type => 'integer', is_nullable => 1 });
    $class->set_primary_key('id');
    $class->belongs_to(other => "${ns}::Result::$o", { 'foreign.id' => 'self.'.lc($o).'_id' }, { on_delete => 'cascade' });
    $ns->register_class($m => $class);
  }
  my $ddl = DBIO::MySQL::DDL->install_ddl($ns);
  is scalar(() = $ddl =~ /ON DELETE CASCADE/g), 2, 'a cycle: both foreign keys carry the action';
  like $ddl, qr/ALTER TABLE .*FOREIGN KEY .* ON DELETE CASCADE;/, '... the closing one in its ALTER TABLE';
}

# The CREATE TABLE of a table the upgrade creates writes the actions of its
# inline foreign keys too (Diff::Table), as ADD FOREIGN KEY does.
{
  require DBIO::MySQL::Diff::Table;
  my $sql = sub {
    my (%fk) = @_;
    DBIO::MySQL::Diff::Table->new(
      action => 'create', table_name => 'child', table_info => {},
      columns => [ { column_name => 'id', column_type => 'bigint', is_pk => 1 },
                   { column_name => 'parent_id', column_type => 'bigint' } ],
      foreign_keys => [ { from_columns => ['parent_id'], to_table => 'parent', to_columns => ['id'], %fk } ],
    )->as_sql;
  };
  like $sql->(on_delete => 'CASCADE', on_update => 'SET NULL'),
    qr/$fk ON UPDATE SET NULL ON DELETE CASCADE\n\)/, 'Diff::Table: inline foreign key carries both actions';
  like $sql->(on_delete => 'RESTRICT', on_update => 'NO ACTION'),
    qr/$fk ON DELETE RESTRICT\n\)/, '... NO ACTION is not written';
  unlike $sql->(on_delete => 'NO ACTION', on_update => ''), qr/ON (?:DELETE|UPDATE)/, '... nor is NO ACTION / empty';
  unlike $sql->(), qr/ON (?:DELETE|UPDATE)/, '... nor an unset action';
}

# SET DEFAULT is refused by both write paths of the diff, naming table,
# constraint and value; nothing else is checked there (the values are the
# introspected ones).
{
  require DBIO::MySQL::Diff::ForeignKey;
  my %info = (from_columns => ['parent_id'], to_table => 'parent', to_columns => ['id']);
  for my $attr (qw/on_delete on_update/) {
    my $create = sub { DBIO::MySQL::Diff::Table->new(
      action => 'create', table_name => 'child', table_info => {},
      columns => [ { column_name => 'id', column_type => 'bigint', is_pk => 1 } ],
      foreign_keys => [ { %info, constraint_name => 'child_ibfk_1', $attr => $_[0] } ])->as_sql };
    my $add = sub { DBIO::MySQL::Diff::ForeignKey->new(action => 'add', table_name => 'child',
      constraint_name => 'child_ibfk_1', fk_info => { %info, $attr => $_[0] })->as_sql };
    for my $word ('SET DEFAULT', 'set default') {
      eval { $create->($word) };
      like "$@", qr/child.*child_ibfk_1.*\Q$attr\E.*SET DEFAULT/s, "Diff::Table refuses $attr $word";
      eval { $add->($word) };
      like "$@", qr/child.*child_ibfk_1.*\Q$attr\E.*SET DEFAULT/s, "Diff::ForeignKey add refuses $attr $word";
    }
    ok eval { $create->('SET NULL'); $add->('SET NULL'); $create->('weird'); $add->('weird'); 1 },
      '... any other word is written through as ever, no wordlist check in the diff';
  }
}

done_testing;
