use strict;
use warnings;
use Test::More;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

# Every subtest works in a database of its own and registers its drop here, so
# that a subtest which dies still leaves nothing behind.
my @CLEANUP;
END {
  local ($@, $?);
  eval { $_->() } for @CLEANUP;
}

# LIVE half of karr k106: the foreign key actions of install_ddl on the real
# server.
#
# WHY IT MATTERS. install_ddl wrote a bare FOREIGN KEY, so an installed database
# and one the upgrade path (Diff::ForeignKey) had made differed in what a
# DELETE of a parent does. What this file claims, on MySQL and on MariaDB:
#   1. the action of on_delete / on_update (cascade, set null, restrict) is
#      what information_schema.referential_constraints reports AND what the
#      server does when the parent row is deleted;
#   2. NO ACTION / unset gives the server's default: the parent stays;
#   3. install and upgrade end in the same actions;
#   4. a table the upgrade creates itself (Diff::Table CREATE TABLE with the
#      foreign key inline) ends in the same actions as the install;
#   5. SET DEFAULT is refused loudly, before anything lands in the database:
#      the server takes the DDL but InnoDB never runs the action (measured:
#      MySQL acts as RESTRICT, MariaDB stores RESTRICT);
#   7. the foreign key has the fixed name <table>_<columns>_fk after the install,
#      after an upgrade that adds it and after an upgrade that creates the table
#      (a server name <table>_ibfk_N differs between those ways), and the diff after
#      each of them is empty, also after an action changed;
#   8. a cycle whose source names are in another order than its table names ends
#      in the same constraints, install and upgrade out of an empty database.
#   6. an upgrade out of an EMPTY database creates parent and child in one go,
#      the child named first, and two tables that reference each other, the
#      closing foreign key added after both; the next diff is empty.
#
# Gated like the other live tests; works in a database of its own (t/86).
subtest 'ddl-foreign-key-actions' => sub {
  my $DB = "dbio_k106_$$";
  my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

  my $drop_database = sub { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") };
  push @CLEANUP, sub { if ($raw) { eval { $drop_database->() } } };

  unless (eval { $drop_database->(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
    my $why = "$@";
    undef $raw;
    plan skip_all => "this account may not create a database of its own: $why";
  }
  note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

  my $n = 0;
  # $fk = 0 builds the same tables without the foreign key (the "before" of an upgrade).
  my $schema_for = sub {
    my ($attrs, $fk) = @_;
    my $ns = 'K106Live::V' . ++$n;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    for my $m (qw/Child Parent/) {
      my $class = "${ns}::Result::$m";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table(lc $m);
      $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
        $m eq 'Child' ? (parent_id => { data_type => 'integer', is_nullable => 1 }) : ());
      $class->set_primary_key('id');
      $class->belongs_to(parent => "${ns}::Result::Parent", { 'foreign.id' => 'self.parent_id' },
        { %$attrs, ($fk ? () : (is_foreign_key_constraint => 0)) }) if $m eq 'Child';
      $ns->register_class($m => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };
  my $fresh = sub { $drop_database->(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") };
  my $rules_of = sub {
    my $row = $raw->selectrow_arrayref(
      'SELECT UPDATE_RULE, DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS '
    . "WHERE CONSTRAINT_SCHEMA = ? AND TABLE_NAME = 'child'", undef, $DB);
    return $row ? join('/', @$row) : '(none)';
  };
  # What a DELETE of the parent does: "refused", "cascaded" (child gone) or "nulled" (child kept, parent_id NULL)
  my $fk_names = sub {
    return join ',', @{ $raw->selectcol_arrayref(
      "SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = ? ORDER BY 1", undef, $DB) };
  };
  my $diff_is_empty = sub {
    my ($schema, $what) = @_;
    my $d = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $d && !$d->has_changes, "$what: the next diff is empty" or diag $@ // join "\n", map { $_->as_sql } @{ $d->operations };
  };
  my $delete_outcome = sub {
    $raw->do('DELETE FROM `child`'); $raw->do('DELETE FROM `parent`');
    $raw->do('INSERT INTO `parent` (`id`) VALUES (1)'); $raw->do('INSERT INTO `child` (`parent_id`) VALUES (1)');
    return 'refused' unless eval { $raw->do('DELETE FROM `parent` WHERE `id` = 1'); 1 };
    my ($rows, $null) = $raw->selectrow_array('SELECT COUNT(*), COALESCE(SUM(`parent_id` IS NULL), 0) FROM `child`');
    return !$rows ? 'cascaded' : $null ? 'nulled' : 'kept';
  };

  my %case = (
    'on_delete cascade'  => [{ on_delete => 'cascade' },  'NO ACTION/CASCADE',   'cascaded'],
    'on_delete set null' => [{ on_delete => 'SET NULL' }, 'NO ACTION/SET NULL',  'nulled'],
    'on_delete restrict' => [{ on_delete => 'restrict' }, 'NO ACTION/RESTRICT',  'refused'],
    'on_update cascade'  => [{ on_update => 'cascade' },  'CASCADE/NO ACTION',   'refused'],
    'both'               => [{ on_update => 'cascade', on_delete => 'cascade' }, 'CASCADE/CASCADE', 'cascaded'],
    'NO ACTION'          => [{ on_delete => 'NO ACTION', on_update => 'no action' }, 'NO ACTION/NO ACTION', 'refused'],
    'unset'              => [{ },                         'NO ACTION/NO ACTION',  'refused'],
  );

  for my $name (sort keys %case) {
    my ($attrs, $rules, $outcome) = @{ $case{$name} };
    subtest $name => sub {
      $fresh->();
      my $schema = $schema_for->($attrs, 1);
      ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install takes it' or diag $@;
      $schema->storage->disconnect;
      my $installed = $rules_of->();
      # MariaDB reports the unwritten action as RESTRICT or NO ACTION by version; compare on the written part
      (my $want = $rules) =~ s{NO ACTION}{(?:NO ACTION|RESTRICT)}g;
      like $installed, qr{^$want$}, "... the server reports $rules";
      is $delete_outcome->(), $outcome, "... and a DELETE of the parent is $outcome";
      is $fk_names->(), 'child_parent_id_fk', '... the foreign key is named by table and column';
      my $again = $schema_for->($attrs, 1);
      $diff_is_empty->($again, 'install');
      $again->storage->disconnect;

      # The upgrade: same tables without the foreign key, then upgrade to the model.
      $fresh->();
      my $before = $schema_for->($attrs, 0);
      DBIO::MySQL::Deploy->new(schema => $before)->install;
      $before->storage->disconnect;
      is $rules_of->(), '(none)', 'upgrade: starts without the foreign key';
      my $after = $schema_for->($attrs, 1);
      ok eval { DBIO::MySQL::Deploy->new(schema => $after)->upgrade; 1 }, '... upgrade adds it' or diag $@;
      $after->storage->disconnect;
      is $rules_of->(), $installed, '... with the same actions as the install';
      is $delete_outcome->(), $outcome, '... and the same behaviour';
      is $fk_names->(), 'child_parent_id_fk', '... and the same name';
      $diff_is_empty->($after, 'upgrade');

      # The upgrade that creates the child table itself: its foreign key is inline
      # in the CREATE TABLE of Diff::Table.
      $fresh->();
      my $seed = $schema_for->($attrs, 0);
      DBIO::MySQL::Deploy->new(schema => $seed)->install;
      $seed->storage->disconnect;
      $raw->do('DROP TABLE `child`');
      my $whole = $schema_for->($attrs, 1);
      ok eval { DBIO::MySQL::Deploy->new(schema => $whole)->upgrade; 1 }, 'upgrade creates the child table' or diag $@;
      $whole->storage->disconnect;
      is $rules_of->(), $installed, '... the inline foreign key has the actions of the install';
      is $delete_outcome->(), $outcome, '... and the same behaviour';
      is $fk_names->(), 'child_parent_id_fk', '... and the same name';
      $diff_is_empty->($whole, 'upgrade creating the table');
    };
  }

  for my $attr (qw/on_delete on_update/) {
    subtest "SET DEFAULT ($attr) is refused" => sub {
      $fresh->();
      my $schema = $schema_for->({ $attr => 'set default' }, 1);
      my $err = do { local $@; eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 } ? '' : "$@" };
      like $err, qr/relationship 'parent' of Child declares \Q$attr\E => 'set default'.*SET DEFAULT/, 'install is refused, naming the relationship';
      is scalar(@{ $raw->selectcol_arrayref('SHOW TABLES') }), 0, '... and nothing landed in the database';
      $schema->storage->disconnect;

      # The upgrade path: the model is made by the install DDL in a temporary
      # database, so the relationship is refused there already; a hand made
      # diff reaching the write path is refused by the diff classes (subtest ddl-foreign-key-actions in t/91-ddl-foreign-key.t).
      my $before = $schema_for->({ is_foreign_key_constraint => 0 }, 0);
      DBIO::MySQL::Deploy->new(schema => $before)->install;
      $before->storage->disconnect;
      my $after = $schema_for->({ $attr => 'set default' }, 1);
      my $up = do { local $@; eval { DBIO::MySQL::Deploy->new(schema => $after)->upgrade; 1 } ? '' : "$@" };
      like $up, qr/SET DEFAULT/, 'upgrade is refused too';
      $after->storage->disconnect;
      is $rules_of->(), '(none)', '... and no foreign key was added';
    };
  }

  # Upgrade out of an empty database (k106): the order of the new tables.
  my $cycle_schema = sub {
    my $ns = 'K106Live::Cycle' . ++$n;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    for my $m (qw/A B/) {
      my $class = "${ns}::Result::$m";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      my $o = $m eq 'A' ? 'B' : 'A';
      $class->table('cyc_' . lc $m);
      $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
        lc($o).'_id' => { data_type => 'integer', is_nullable => 1 });
      $class->set_primary_key('id');
      $class->belongs_to(other => "${ns}::Result::$o", { 'foreign.id' => 'self.'.lc($o).'_id' }, { on_delete => 'cascade' });
      $ns->register_class($m => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };
  subtest 'upgrade out of an empty database orders the new tables' => sub {
    $fresh->();
    my $schema = $schema_for->({ on_delete => 'cascade' }, 1);   # `child` sorts before `parent`
    ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade; 1 }, 'child and parent in one upgrade' or diag $@;
    like $rules_of->(), qr{^(?:NO ACTION|RESTRICT)/CASCADE$}, '... the foreign key is there, with its action';
    is $delete_outcome->(), 'cascaded', '... and it acts';
    my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $diff && !$diff->has_changes, '... the next diff is empty' or diag $@ // $diff->as_sql;
    $schema->storage->disconnect;

    $fresh->();
    my $cycle = $cycle_schema->();
    ok eval { DBIO::MySQL::Deploy->new(schema => $cycle)->upgrade; 1 }, 'two tables referencing each other in one upgrade' or diag $@;
    my $fks = $raw->selectrow_array(
      "SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = ? AND DELETE_RULE = 'CASCADE'", undef, $DB);
    is $fks, 2, '... both foreign keys are there, with their action';
    my $again = eval { DBIO::MySQL::Deploy->new(schema => $cycle)->diff };
    ok $again && !$again->has_changes, '... the next diff is empty' or diag $@ // $again->as_sql;
    $cycle->storage->disconnect;
  };

  # An action changed on an installed foreign key: drop and add under the same name.
  subtest 'a changed action is a drop and an add of the same name, and the diff is empty after' => sub {
    $fresh->();
    my $old = $schema_for->({}, 1);
    DBIO::MySQL::Deploy->new(schema => $old)->install;
    $old->storage->disconnect;
    my $new = $schema_for->({ on_delete => 'cascade' }, 1);
    ok eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'upgrade changes the action' or diag $@;
    like $rules_of->(), qr{^(?:NO ACTION|RESTRICT)/CASCADE$}, '... it is CASCADE now';
    is $fk_names->(), 'child_parent_id_fk', '... under the same name';
    $diff_is_empty->($new, 'action changed');
    $new->storage->disconnect;
  };

  # Source names (A, B, C) and table names (zz, aa, cc) in another order, a cycle
  # between zz and aa, and aa with a second foreign key (to cc).
  my $mixed_schema = sub {
    my $ns = 'K106Live::Mixed' . ++$n;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my %src = (
      A => { table => 'zz', fk => [[ aa_id => 'B' ]] },
      B => { table => 'aa', fk => [[ zz_id => 'A' ], [ cc_id => 'C' ]] },
      C => { table => 'cc', fk => [] },
    );
    for my $m (sort keys %src) {
      my $class = "${ns}::Result::$m";
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table($src{$m}{table});
      $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
        map { $_->[0] => { data_type => 'integer', is_nullable => 1 } } @{ $src{$m}{fk} });
      $class->set_primary_key('id');
      $class->belongs_to("rel_$_->[0]" => "${ns}::Result::$_->[1]", { 'foreign.id' => "self.$_->[0]" }, { on_delete => 'cascade' })
        for @{ $src{$m}{fk} };
      $ns->register_class($m => $class);
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };
  subtest 'a cycle with source names and table names in another order: install and upgrade end alike' => sub {
    my $want = 'aa_cc_id_fk,aa_zz_id_fk,zz_aa_id_fk';
    $fresh->();
    my $inst = $mixed_schema->();
    ok eval { DBIO::MySQL::Deploy->new(schema => $inst)->install; 1 }, 'install' or diag $@;
    is $fk_names->(), $want, '... the three foreign keys, by table and column';
    $diff_is_empty->($inst, 'install');
    $inst->storage->disconnect;

    $fresh->();
    my $up = $mixed_schema->();
    ok eval { DBIO::MySQL::Deploy->new(schema => $up)->upgrade; 1 }, 'upgrade out of an empty database' or diag $@;
    is $fk_names->(), $want, '... the same three, under the same names';
    $diff_is_empty->($up, 'upgrade');
    $up->storage->disconnect;
  };

  $drop_database->();
  $raw->disconnect;
  undef $raw;
};

# LIVE half of subtest ddl-foreign-key-name-collision in t/91-ddl-foreign-key.t (karr k106), on the real server: foreign keys that meet in
# one name, and a composite foreign key over a primary key (b, a).
#
# WHY IT MATTERS. An install must work for the schemas main installs, and an
# upgrade must end in the very same constraints as the install, or the next
# diff has something to say for ever. What this file claims, on MySQL and on
# MariaDB:
#   1. two belongs_to over one key to one target are ONE constraint in the
#      database;
#   2. table a_b column c and table a column b_c (one name a_b_c_fk) both
#      exist after the install, under two names, and an upgrade out of an
#      empty database and an upgrade that adds them to existing tables end in
#      the same constraints, the diff afterwards empty;
#   3. one column that references two targets: the same;
#   4. a primary key (b, a) with a foreign key over both columns installs (the
#      server takes the referenced list only in the order of the key) and the
#      upgrade ends alike, the diff empty.
#
# Gated like the other live tests; works in a database of its own (t/96).
subtest 'ddl-foreign-key-name-collision' => sub {
  my $DB = "dbio_k106c_$$";
  my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

  my $drop_database = sub { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") };
  push @CLEANUP, sub { if ($raw) { eval { $drop_database->() } } };

  unless (eval { $drop_database->(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
    my $why = "$@";
    undef $raw;
    plan skip_all => "this account may not create a database of its own: $why";
  }
  note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

  my $n = 0;
  # %spec: table => { cols, pk, rels => [ [ name, target, cond ] ] }; $fk = 0
  # builds the same tables without the foreign keys (the "before" of an upgrade).
  my $schema_for = sub {
    my ($spec, $fk) = @_;
    my $ns = 'K106CollLive::V' . ++$n;
    eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
    my %class = map { $_ => "${ns}::Result::" . join '', map { ucfirst } split /_/, $_ } keys %$spec;
    for my $t (sort keys %$spec) {
      my $class = $class{$t};
      eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
      $class->table($t);
      my %is_pk = map { $_ => 1 } @{ $spec->{$t}{pk} };
      $class->add_columns(map { $_ => { data_type => 'integer', $is_pk{$_} ? () : (is_nullable => 1) } } @{ $spec->{$t}{cols} });
      $class->set_primary_key(@{ $spec->{$t}{pk} });
    }
    for my $t (sort keys %$spec) {
      $class{$t}->belongs_to($_->[0] => $class{ $_->[1] }, $_->[2], { ($fk ? () : (is_foreign_key_constraint => 0)) })
        for @{ $spec->{$t}{rels} // [] };
      $ns->register_class($t => $class{$t});
    }
    return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
  };
  my $fresh = sub { $drop_database->(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") };

  # Every foreign key column pair of the database: name, table, column, target, target column, position.
  my $state = sub {
    return join "\n", map { join ' ', map { $_ // '' } @$_ } @{ $raw->selectall_arrayref(
      'SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, ORDINAL_POSITION '
    . 'FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL '
    . 'ORDER BY CONSTRAINT_NAME, ORDINAL_POSITION', undef, $DB) };
  };
  my $names = sub { return [ sort keys %{ { map { $_ => 1 } map { (split ' ')[0] } split /\n/, $state->() } } ] };
  my $diff_is_empty = sub {
    my ($schema, $what) = @_;
    my $d = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $d && !$d->has_changes, "$what: the next diff is empty" or diag $@ // join "\n", map { $_->as_sql } @{ $d->operations };
  };
  my $deploy = sub {
    my ($how, $spec, $fk) = @_;
    my $s = $schema_for->($spec, $fk);
    my $ok = eval { DBIO::MySQL::Deploy->new(schema => $s)->$how; 1 };
    my $err = $@;
    return ($s, $ok, $err);
  };

  my $P = { cols => ['id'], pk => ['id'] };
  my %case = (
    'two belongs_to, one foreign key' => [
      { p => $P, c => { cols => [qw/id pid/], pk => ['id'], rels => [
          [ parent => p => { 'foreign.id' => 'self.pid' } ], [ owner => p => { 'foreign.id' => 'self.pid' } ] ] } },
      1 ],
    'a_b.c and a.b_c meet in one name' => [
      { p => $P,
        a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
        a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] } },
      2 ],
    'one column to two targets' => [
      { p1 => $P, p2 => $P,
        c => { cols => [qw/id pid/], pk => ['id'], rels => [
          [ one => p1 => { 'foreign.id' => 'self.pid' } ], [ two => p2 => { 'foreign.id' => 'self.pid' } ] ] } },
      2 ],
    'primary key (b, a), composite foreign key' => [
      { q => { cols => [qw/b a/], pk => [qw/b a/] },
        r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
          [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] } },
      1 ],
  );

  for my $name (sort keys %case) {
    my ($spec, $count) = @{ $case{$name} };
    subtest $name => sub {
      $fresh->();
      my ($inst, $ok, $err) = $deploy->('install', $spec, 1);
      ok $ok, 'install takes it' or diag $err;
      is scalar(@{ $names->() }), $count, "... $count constraint(s) in the database";
      my $installed = $state->();
      $diff_is_empty->($inst, 'install');
      $inst->storage->disconnect;

      $fresh->();
      my ($up, $ok2, $err2) = $deploy->('upgrade', $spec, 1);
      ok $ok2, 'upgrade out of an empty database' or diag $err2;
      is $state->(), $installed, '... ends in the same foreign keys as the install';
      $diff_is_empty->($up, 'upgrade out of an empty database');
      $up->storage->disconnect;

      $fresh->();
      my ($before) = $deploy->('install', $spec, 0);
      $before->storage->disconnect;
      is $state->(), '', 'upgrade adding them: starts without';
      my ($add, $ok3, $err3) = $deploy->('upgrade', $spec, 1);
      ok $ok3, '... the upgrade adds them' or diag $err3;
      is $state->(), $installed, '... same foreign keys as the install';
      $diff_is_empty->($add, 'upgrade adding them');
      $add->storage->disconnect;
    };
  }
};

done_testing;
