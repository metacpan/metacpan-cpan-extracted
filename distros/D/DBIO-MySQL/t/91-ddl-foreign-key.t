use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::ForeignKey;

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
subtest 'ddl-foreign-key-order' => sub {
  my $n = 0;
  my $ddl_for = sub {
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
  };
  my $order_of = sub {
    my ($ddl) = @_;
    return [ map { /^(CREATE TABLE|ALTER TABLE) `(\w+)`/ ? "$1 $2" : () } split /\n\n/, $ddl ];
  };

  is_deeply $order_of->($ddl_for->(
    A_Child => { table => 'child', fk => [[ parent_id => 'Z_Parent' ]] },
    Z_Parent => { table => 'parent' },
  )), [ 'CREATE TABLE parent', 'CREATE TABLE child' ], 'a child sorting before its parent comes after it';

  is_deeply $order_of->($ddl_for->(
    B => { table => 'b' }, A => { table => 'a' }, C => { table => 'c', fk => [[ a_id => 'A' ]] },
  )), [ 'CREATE TABLE a', 'CREATE TABLE b', 'CREATE TABLE c' ], 'free tables keep source-name order';

  is_deeply $order_of->($ddl_for->(
    A_Tree => { table => 'tree', fk => [[ parent_id => 'A_Tree' ]] },
    B_Leaf => { table => 'leaf', fk => [[ tree_id => 'A_Tree' ]] },
  )), [ 'CREATE TABLE tree', 'CREATE TABLE leaf' ], 'a self reference is no dependency';
  like $ddl_for->(A_Tree => { table => 'tree', fk => [[ parent_id => 'A_Tree' ]] }),
    qr/FOREIGN KEY \(`parent_id`\) REFERENCES `tree`\(`id`\)\n\)/, '... and stays inside its CREATE TABLE';

  my $cycle = $ddl_for->(
    A => { table => 'a', fk => [[ b_id => 'B' ]] },
    B => { table => 'b', fk => [[ a_id => 'A' ]] },
    C => { table => 'c' },
  );
  is_deeply $order_of->($cycle), [ 'CREATE TABLE c', 'CREATE TABLE a', 'CREATE TABLE b', 'ALTER TABLE a' ],
    'a cycle: the free table first, then the first of the cycle by source name, its foreign key added afterwards';
  like $cycle, qr/ALTER TABLE `a` ADD CONSTRAINT `a_b_id_fk` FOREIGN KEY \(`b_id`\) REFERENCES `b`\(`id`\);/, '... as ALTER TABLE ADD FOREIGN KEY';
  like $cycle, qr/CREATE TABLE `b` \(.*FOREIGN KEY \(`a_id`\) REFERENCES `a`\(`id`\)\n\)/s,
    '... and the other one keeps its foreign key inline';
  unlike $cycle, qr/CREATE TABLE `a` \([^;]*FOREIGN KEY/, '... the first has none inline';

  is $ddl_for->(A => { table => 'a', fk => [[ b_id => 'B' ]] }, B => { table => 'b', fk => [[ a_id => 'A' ]] }),
    $ddl_for->(A => { table => 'a', fk => [[ b_id => 'B' ]] }, B => { table => 'b', fk => [[ a_id => 'A' ]] }),
    'the same schema gives the same script';

  # karr k106 (K10): the cycle is broken at a table that is on it, not at the
  # first table that merely waits for one. The source A (table x) comes first by name
  # and references B; B and C reference each other. Holding the foreign key of x
  # back would be for nothing: B is the table to break at.
  my $waiting = $ddl_for->(
    A => { table => 'x', fk => [[ a_id => 'B' ]] },
    B => { table => 'a', fk => [[ b_id => 'C' ]] },
    C => { table => 'b', fk => [[ a_id => 'B' ]] },
  );
  is_deeply $order_of->($waiting), [ 'CREATE TABLE a', 'CREATE TABLE x', 'CREATE TABLE b', 'ALTER TABLE a' ],
    'a table waiting on a cycle is not where it is broken: the cycle is, at its first table';
  like $waiting, qr/CREATE TABLE `x` \(.*CONSTRAINT `x_a_id_fk` FOREIGN KEY \(`a_id`\) REFERENCES `a`\(`id`\)\n\)/s,
    '... and the foreign key of the waiting table stays inline';

  # Source names and table names in different order (karr k106): A is table zz, B is
  # aa, C is cc; aa references zz and cc.
  my $mixed = $ddl_for->(
    A => { table => 'zz', fk => [[ aa_id => 'B' ]] },
    B => { table => 'aa', fk => [[ zz_id => 'A' ], [ cc_id => 'C' ]] },
    C => { table => 'cc' },
  );
  is_deeply $order_of->($mixed), [ 'CREATE TABLE cc', 'CREATE TABLE zz', 'CREATE TABLE aa', 'ALTER TABLE zz' ],
    'source names and table names in another order: the cycle is broken at the first source name (zz)';
  like $mixed, qr/CREATE TABLE `aa` \(.*CONSTRAINT `aa_cc_id_fk` FOREIGN KEY.*CONSTRAINT `aa_zz_id_fk` FOREIGN KEY/s,
    '... aa has both its foreign keys inline, named by table and column';
};

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
# What the servers make of them: subtest ddl-foreign-key-actions of t/96-ddl-foreign-key-live.t.
subtest 'ddl-foreign-key-actions' => sub {
  my $n = 0;
  my $ddl_for = sub {
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
  };
  my $fk = qr/FOREIGN KEY \(`parent_id`\) REFERENCES `parent`\(`id`\)/;

  like $ddl_for->(on_delete => 'cascade'), qr/$fk ON DELETE CASCADE\n/, 'on_delete cascade';
  like $ddl_for->(on_delete => 'SET NULL'), qr/$fk ON DELETE SET NULL\n/, 'on_delete SET NULL';
  like $ddl_for->(on_delete => 'Restrict'), qr/$fk ON DELETE RESTRICT\n/, 'on_delete restrict, any case';
  like $ddl_for->(on_update => 'cascade'), qr/$fk ON UPDATE CASCADE\n/, 'on_update cascade';
  like $ddl_for->(on_delete => 'cascade', on_update => 'set null'),
    qr/$fk ON UPDATE SET NULL ON DELETE CASCADE\n/, 'both: ON UPDATE before ON DELETE, as the diff path';

  unlike $ddl_for->(on_delete => 'NO ACTION', on_update => 'no action'), qr/ON (?:DELETE|UPDATE)/, 'NO ACTION writes nothing';
  unlike $ddl_for->(), qr/ON (?:DELETE|UPDATE)/, 'unset writes nothing';
  unlike $ddl_for->(on_delete => undef), qr/ON (?:DELETE|UPDATE)/, 'undef writes nothing';

  for my $attr (qw/on_delete on_update/) {
    eval { $ddl_for->($attr => 'explode') };
    like "$@", qr/relationship 'parent' of Child declares \Q$attr\E => 'explode', which is no foreign key action/,
      "an unknown $attr is refused by the driver";
  }

  for my $attr (qw/on_delete on_update/) {
    for my $word ('set default', 'SET DEFAULT', 'Set_Default') {
      eval { $ddl_for->($attr => $word) };
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
};

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
#      foreign keys that only meet in a name are told apart (subtest ddl-foreign-key-name-collision);
#   4. on_delete / on_update => '' is "the database's default" (core,
#      DBIO::Relationship::Base) and writes nothing, it does not throw.
subtest 'ddl-foreign-key-name' => sub {
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
  my $schema_for = sub {
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
  };

  my $ddl = DBIO::MySQL::DDL->install_ddl($schema_for->([ [ parent => { 'foreign.id' => 'self.parent_id' } ] ]));
  like $ddl, qr/CONSTRAINT `child_parent_id_fk` FOREIGN KEY \(`parent_id`\) REFERENCES `parent`\(`id`\)/,
    'install_ddl names the foreign key';
  unlike $ddl, qr/ibfk/, '... no server name';

  my $one = eval { DBIO::MySQL::DDL->install_ddl($schema_for->([
    [ one => { 'foreign.id' => 'self.parent_id' } ], [ two => { 'foreign.id' => 'self.parent_id' } ] ])) };
  ok defined $one, 'two relationships over one column set to one target: not refused' or diag $@;
  is_deeply [ ($one // '') =~ /CONSTRAINT `([^`]+)` FOREIGN KEY/g ], ['child_parent_id_fk'],
    '... one constraint under the plain name';

  ok eval { DBIO::MySQL::DDL->install_ddl($schema_for->([
    [ one => { 'foreign.id' => 'self.parent_id' } ], [ two => { 'foreign.id' => 'self.other_id' } ] ])); 1 },
    'different columns: no clash' or diag $@;

  # B3: '' is the database's default
  for my $attr (qw/on_delete on_update/) {
    my $out = eval { DBIO::MySQL::DDL->install_ddl($schema_for->([ [ parent => { 'foreign.id' => 'self.parent_id' }, { $attr => '' } ] ])) };
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
};

# karr k106: what happens when foreign keys meet in one name, and in which
# order the columns of a composite foreign key are written.
#
# WHY IT MATTERS. The fixed name <table>_<columns>_fk (subtest ddl-foreign-key-name) is a function of
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
subtest 'ddl-foreign-key-name-collision' => sub {
  my $n = 0;
  # %spec: table => { cols => [..], pk => [..], uniques => { name => [..] },
  #                   rels => [ [ name, target table, cond, attrs ] ] }
  my $schema_for = sub {
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
  };
  my $constraints = sub {
    my ($ddl) = @_;
    return [ $ddl =~ /CONSTRAINT `([^`]+)` FOREIGN KEY/g ];
  };
  my $P = { cols => ['id'], pk => ['id'] };

  # 1. identical foreign keys are one
  {
    my $ddl = eval { DBIO::MySQL::DDL->install_ddl($schema_for->(
      p => $P,
      c => { cols => [qw/id pid/], pk => ['id'], rels => [
        [ parent => p => { 'foreign.id' => 'self.pid' } ],
        [ owner  => p => { 'foreign.id' => 'self.pid' } ] ] })) };
    ok defined $ddl, 'two belongs_to over one key to one target: installs' or diag $@;
    is_deeply $constraints->($ddl // ''), ['c_pid_fk'], '... as ONE constraint, the plain name';

    my $acts = eval { DBIO::MySQL::DDL->install_ddl($schema_for->(
      p => $P,
      c => { cols => [qw/id pid/], pk => ['id'], rels => [
        [ parent => p => { 'foreign.id' => 'self.pid' }, { on_delete => 'cascade' } ],
        [ owner  => p => { 'foreign.id' => 'self.pid' }, { on_delete => 'CASCADE' } ] ] })) };
    is_deeply $constraints->($acts // ''), ['c_pid_fk'], 'identical in the action, written another way: still one' or diag $@;
  }

  # 2. different foreign keys, one name: all get the suffix
  my %hash8;
  {
    my $ddl = eval { DBIO::MySQL::DDL->install_ddl($schema_for->(
      p => $P,
      a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
      a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] })) };
    ok defined $ddl, 'table a_b column c vs table a column b_c: installs, no abort' or diag $@;
    my $names = $constraints->($ddl // '');
    is scalar(@$names), 2, '... both constraints are there';
    like $_, qr/^a(?:_b)?_(?:b_)?c_fk_[0-9a-f]{8}\z/, "... $_ carries _<hash8>" for @$names;
    isnt $names->[0], $names->[1], '... and the two names differ';
    my $again = eval { $constraints->(DBIO::MySQL::DDL->install_ddl($schema_for->(
      p => $P,
      a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
      a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] }))) };
    is_deeply [ sort @{ $again // [] } ], [ sort @$names ], '... deterministic: the same names on the next run';
  diag $@ unless $again;
  }
  {
    my $names = $constraints->(DBIO::MySQL::DDL->install_ddl($schema_for->(
      p1 => $P, p2 => $P,
      c => { cols => [qw/id pid/], pk => ['id'], rels => [
        [ one => p1 => { 'foreign.id' => 'self.pid' } ],
        [ two => p2 => { 'foreign.id' => 'self.pid' } ] ] })));
    is scalar(@$names), 2, 'one column to two targets: two constraints';
    like $_, qr/^c_pid_fk_[0-9a-f]{8}\z/, "... $_ carries _<hash8>" for @$names;
    isnt $names->[0], $names->[1], '... different names';
  }
  {
    my $names = $constraints->(DBIO::MySQL::DDL->install_ddl($schema_for->(
      p => $P,
      A   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
      a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] })));
    like $_, qr/_fk_[0-9a-f]{8}\z/, "case-insensitive, as the server: $_ carries _<hash8>" for @$names;
  }
  {
    my $long = 't' x 30;
    my $names = $constraints->(DBIO::MySQL::DDL->install_ddl($schema_for->(
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
    my $ddl = eval { DBIO::MySQL::DDL->install_ddl($schema_for->(
      q => { cols => [qw/a b/], pk => [qw/b a/] },
      r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
        [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] })) };
    ok defined $ddl, 'primary key (b, a): installs' or diag $@;
    like $ddl // '', qr/CONSTRAINT `r_xb_ya_fk` FOREIGN KEY \(`xb`, `ya`\) REFERENCES `q`\(`b`, `a`\)/,
      '... the columns in the order of the key, the name from that order';

    my $unique = DBIO::MySQL::DDL->install_ddl($schema_for->(
      q => { cols => [qw/id a b/], pk => ['id'], uniques => { q_ba => [qw/b a/] } },
      r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
        [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] }));
    like $unique, qr/FOREIGN KEY \(`xb`, `ya`\) REFERENCES `q`\(`b`, `a`\)/, 'a unique constraint (b, a) of the target gives the order as well';

    my $sorted = DBIO::MySQL::DDL->install_ddl($schema_for->(
      q => { cols => [qw/a b/], pk => [qw/a b/] },
      r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
        [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] }));
    like $sorted, qr/CONSTRAINT `r_ya_xb_fk` FOREIGN KEY \(`ya`, `xb`\) REFERENCES `q`\(`a`, `b`\)/,
      'primary key (a, b): (a, b), the pairing with the referencing columns kept';
  }
};

done_testing;
