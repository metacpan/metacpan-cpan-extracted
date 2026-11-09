use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k66 -- a belongs_to that declares on_delete / on_update gets the foreign
# key it declared.
#
# It did not. DBIO::SQLite::DDL wrote every foreign key as
#
#   FOREIGN KEY ("parent_id") REFERENCES "parent"("id")
#
# and stopped there; the two attributes never reached the statement. A schema
# that said on_delete => 'CASCADE' deployed without a word and then refused to
# delete the parent ("FOREIGN KEY constraint failed"), or with foreign_keys off
# left the children behind. The only way to a cascading key was to hand the
# deploy its DDL by hand, which is what t/47-diff-create-table.t had to do.
#
# The rule now: what the relationship declares is written, as declared. What it
# does not declare -- attribute absent, undef, '' -- is not written, and the key
# keeps SQLite's default, NO ACTION. Nothing is derived from the other side of
# the relationship: a has_many defaults to cascade_delete => 1, and that is the
# ORM deleting rows, not a statement about the constraint.
#
# The parent is deleted and renumbered with plain SQL throughout, so that
# whatever happens to a child row is the database's doing.

{
  package FA;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package FA::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package FA::Result::Cascade;
  use base 'DBIO::Core';
  __PACKAGE__->table('cascade_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'CASCADE', on_update => 'CASCADE' });

  package FA::Result::SetNull;          # one attribute only
  use base 'DBIO::Core';
  __PACKAGE__->table('setnull_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'SET NULL' });

  package FA::Result::SetDefault;
  use base 'DBIO::Core';
  __PACKAGE__->table('setdefault_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0, default_value => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'SET DEFAULT' });

  package FA::Result::Restrict;
  use base 'DBIO::Core';
  __PACKAGE__->table('restrict_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'RESTRICT', on_update => 'RESTRICT' });

  package FA::Result::Lower;            # lower case is written as it stands
  use base 'DBIO::Core';
  __PACKAGE__->table('lower_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'cascade' });

  package FA::Result::NoAction;         # the default, spelled out
  use base 'DBIO::Core';
  __PACKAGE__->table('noaction_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => 'NO ACTION', on_update => 'NO ACTION' });

  package FA::Result::Plain;            # no attribute at all
  use base 'DBIO::Core';
  __PACKAGE__->table('plain_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id');

  package FA::Result::Undef;
  use base 'DBIO::Core';
  __PACKAGE__->table('undef_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => undef, on_update => undef });

  package FA::Result::Empty;
  use base 'DBIO::Core';
  __PACKAGE__->table('empty_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Result::Parent', 'parent_id',
    { on_delete => '', on_update => '' });
}

# cascade_delete => 1 by default. It must not turn the key of plain_child into
# ON DELETE CASCADE.
FA::Result::Parent->has_many(plains => 'FA::Result::Plain', 'parent_id');

FA->register_class(Parent     => 'FA::Result::Parent');
FA->register_class(Cascade    => 'FA::Result::Cascade');
FA->register_class(SetNull    => 'FA::Result::SetNull');
FA->register_class(SetDefault => 'FA::Result::SetDefault');
FA->register_class(Restrict   => 'FA::Result::Restrict');
FA->register_class(Lower      => 'FA::Result::Lower');
FA->register_class(NoAction   => 'FA::Result::NoAction');
FA->register_class(Plain      => 'FA::Result::Plain');
FA->register_class(Undef      => 'FA::Result::Undef');
FA->register_class(Empty      => 'FA::Result::Empty');

my $REF = 'FOREIGN KEY ("parent_id") REFERENCES "parent"("id")';

# table => [ the line install_ddl writes, on_delete and on_update as SQLite
# reports the key afterwards ]
my %EXPECT = (
  cascade_child    => [ "$REF ON DELETE CASCADE ON UPDATE CASCADE",     'CASCADE',     'CASCADE'   ],
  setnull_child    => [ "$REF ON DELETE SET NULL",                      'SET NULL',    'NO ACTION' ],
  setdefault_child => [ "$REF ON DELETE SET DEFAULT",                   'SET DEFAULT', 'NO ACTION' ],
  restrict_child   => [ "$REF ON DELETE RESTRICT ON UPDATE RESTRICT",   'RESTRICT',    'RESTRICT'  ],
  lower_child      => [ "$REF ON DELETE cascade",                       'CASCADE',     'NO ACTION' ],
  # NO ACTION is the default of a key and writes no clause (karr k88).
  noaction_child   => [ $REF,                                           'NO ACTION',   'NO ACTION' ],
  plain_child      => [ $REF,                                           'NO ACTION',   'NO ACTION' ],
  undef_child      => [ $REF,                                           'NO ACTION',   'NO ACTION' ],
  empty_child      => [ $REF,                                           'NO ACTION',   'NO ACTION' ],
);

# One part dying must not hide what the others have to say.
sub section {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name: died -- $@");
}

sub table_sql {
  my ($dbh, $name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT sql FROM sqlite_master WHERE name = ?}, undef, $name,
  );
}

sub connect_with_fks {
  my ($class) = @_;
  my $schema = $class->connect('dbi:SQLite::memory:');
  $schema->storage->dbh->do('PRAGMA foreign_keys = ON');
  return $schema;
}

# ---------------------------------------------------------------------------
# 1. What install_ddl writes
# ---------------------------------------------------------------------------
#
# The only place where "nothing declared" and "NO ACTION declared" can be told
# apart: SQLite reports both as NO ACTION.

section "the foreign key line" => sub {
  my %line;
  for my $stmt (split /\n\n/, DBIO::SQLite::DDL->install_ddl('FA')) {
    my ($table) = $stmt =~ /\ACREATE TABLE "(\w+)"/ or next;
    ($line{$table}) = $stmt =~ /^\s*(FOREIGN KEY.*?),?$/m;
  }

  is($line{$_}, $EXPECT{$_}[0], "$_: the foreign key as install_ddl writes it")
    for sort keys %EXPECT;
};

# ---------------------------------------------------------------------------
# 2. Installed, read back, and used
# ---------------------------------------------------------------------------

my $schema = connect_with_fks('FA');
my $dbh    = $schema->storage->dbh;
my $deploy = DBIO::SQLite::Deploy->new(schema => $schema);
$deploy->install;

is(scalar $dbh->selectrow_array('PRAGMA foreign_keys'), 1,
  'foreign keys are enforced on this connection');

section "the introspected foreign key" => sub {
  my $fks = DBIO::SQLite::Introspect->new(dbh => $dbh)->model->{foreign_keys};

  for my $table (sort keys %EXPECT) {
    my @fk = @{ $fks->{$table} // [] };
    is(scalar @fk, 1, "$table: one foreign key");
    is($fk[0]{on_delete}, $EXPECT{$table}[1], "$table: on_delete as introspected");
    is($fk[0]{on_update}, $EXPECT{$table}[2], "$table: on_update as introspected");
  }
};

# The first parent is the one setdefault_child falls back to: its column
# default is 1.
my $fallback = $schema->resultset('Parent')->create({ name => 'fallback' })->id;
is($fallback, 1, 'the fallback parent has the id the column default names');

sub parent_with_child {
  my ($source) = @_;
  my $id = $schema->resultset('Parent')->create({ name => $source })->id;
  $schema->resultset($source)->create({ parent_id => $id });
  return $id;
}

sub parent_ids_in {
  my ($table) = @_;
  return $dbh->selectcol_arrayref("SELECT parent_id FROM $table");
}

section "CASCADE" => sub {
  my $id = parent_with_child('Cascade');

  lives_ok { $dbh->do('UPDATE parent SET id = 500 WHERE id = ?', undef, $id) }
    'the key of a parent with an ON UPDATE CASCADE child can be changed';
  is_deeply(parent_ids_in('cascade_child'), [ 500 ],
    'ON UPDATE CASCADE: the child follows its parent to the new key');

  lives_ok { $dbh->do('DELETE FROM parent WHERE id = 500') }
    'a parent with an ON DELETE CASCADE child can be deleted';
  is_deeply(parent_ids_in('cascade_child'), [],
    'ON DELETE CASCADE: the child went with its parent');
};

section "cascade, in lower case" => sub {
  my $id = parent_with_child('Lower');

  lives_ok { $dbh->do('DELETE FROM parent WHERE id = ?', undef, $id) }
    'a parent with an "on delete cascade" child can be deleted';
  is_deeply(parent_ids_in('lower_child'), [],
    'the action cascades whichever case it was declared in');
};

section "SET NULL" => sub {
  my $id = parent_with_child('SetNull');

  # on_update is not declared on this one. The declared on_delete must not
  # have brought an ON UPDATE along.
  throws_ok { $dbh->do('UPDATE parent SET id = 600 WHERE id = ?', undef, $id) }
    qr/FOREIGN KEY constraint failed/,
    'no on_update declared: changing the parent key is refused';

  lives_ok { $dbh->do('DELETE FROM parent WHERE id = ?', undef, $id) }
    'a parent with an ON DELETE SET NULL child can be deleted';
  is_deeply(parent_ids_in('setnull_child'), [ undef ],
    'ON DELETE SET NULL: the child stays and points nowhere');
};

section "SET DEFAULT" => sub {
  my $id = parent_with_child('SetDefault');

  lives_ok { $dbh->do('DELETE FROM parent WHERE id = ?', undef, $id) }
    'a parent with an ON DELETE SET DEFAULT child can be deleted';
  is_deeply(parent_ids_in('setdefault_child'), [ $fallback ],
    'ON DELETE SET DEFAULT: the child falls back to the column default');
};

# RESTRICT refuses, and so does a key without an action: on a connection in
# autocommit the two cannot be told apart by what happens. That it is RESTRICT
# is what the introspected key says above.
section "RESTRICT, NO ACTION, and nothing declared" => sub {
  for my $source (qw(Restrict NoAction Plain Undef Empty)) {
    my $id    = parent_with_child($source);
    my $table = $schema->source($source)->name;

    throws_ok { $dbh->do('DELETE FROM parent WHERE id = ?', undef, $id) }
      qr/FOREIGN KEY constraint failed/,
      "$table: deleting the parent is refused";
    throws_ok { $dbh->do('UPDATE parent SET id = id + 1000 WHERE id = ?', undef, $id) }
      qr/FOREIGN KEY constraint failed/,
      "$table: changing the parent key is refused";
    is_deeply(parent_ids_in($table), [ $id ], "$table: the child is untouched");
  }
};

section "the schema against the database it was installed into" => sub {
  my $diff = $deploy->diff;
  ok(!$diff->has_changes, 'nothing to change right after the install')
    or diag $diff->summary;
};

# ---------------------------------------------------------------------------
# 3. A table an upgrade adds
# ---------------------------------------------------------------------------
#
# An added table is created from the statement install_ddl writes for it
# (karr k56), so the action has to arrive there as well.

{
  package FA::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package FA::V1::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
FA::V1->register_class(Parent => 'FA::V1::Result::Parent');

section "upgrade adds the child tables" => sub {
  my $v1 = connect_with_fks('FA::V1');
  DBIO::SQLite::Deploy->new(schema => $v1)->install;
  my $v1_dbh = $v1->storage->dbh;

  my $v2      = FA->connect(sub { $v1_dbh });
  my $upgrade = DBIO::SQLite::Deploy->new(schema => $v2);
  lives_ok { $upgrade->upgrade } 'the upgrade that adds the child tables applies';

  is(table_sql($v1_dbh, $_), table_sql($dbh, $_),
    "$_: the added table has the definition a fresh install gives it")
    for sort keys %EXPECT;

  my $id = $v2->resultset('Parent')->create({ name => 'upgraded' })->id;
  $v2->resultset('Cascade')->create({ parent_id => $id });
  $v1_dbh->do('DELETE FROM parent WHERE id = ?', undef, $id);
  is($v2->resultset('Cascade')->count, 0,
    'ON DELETE CASCADE works on a table the upgrade added');

  ok(!$upgrade->diff->has_changes, 'nothing left to do after the upgrade');
};

# ---------------------------------------------------------------------------
# 4. An action SQLite does not know
# ---------------------------------------------------------------------------
#
# The value is not checked here; it goes into the statement as written and
# SQLite is the one to say no. What must not happen is the old behaviour by
# another road: the attribute dropped, the table created, nobody told.

{
  package FA::Typo;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package FA::Typo::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');

  package FA::Typo::Result::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FA::Typo::Result::Parent', 'parent_id',
    { on_delete => 'CASCDE' });
}
FA::Typo->register_class(Parent => 'FA::Typo::Result::Parent');
FA::Typo->register_class(Child  => 'FA::Typo::Result::Child');

section "an unknown action" => sub {
  my $typo = connect_with_fks('FA::Typo');

  # Since karr k88 the action is checked when the DDL is generated: the
  # exception names the word, it is no longer SQLite's syntax error.
  throws_ok { DBIO::SQLite::Deploy->new(schema => $typo)->install }
    qr/CASCDE/,
    'an action SQLite does not know fails the install, naming the word';
  is(table_sql($typo->storage->dbh, 'child'), undef,
    'and leaves no table behind that lacks it');
};

# ---------------------------------------------------------------------------
# 5. One key, declared by more than one relationship
# ---------------------------------------------------------------------------
#
# karr k74. A foreign key is a statement about the table; a belongs_to is a way
# to walk it. Two relationships over the same column to the same target -- an
# accessor under a second name, a second one with other join attributes -- are
# still one key. install_ddl wrote one FOREIGN KEY line per relationship, SQLite
# took both and kept two keys (PRAGMA foreign_key_list lists each), and every
# insert and every delete of a parent was checked twice.
#
# The same key is: the same columns in the same order, the same target table
# and columns, the same ON DELETE and ON UPDATE -- the action compared without
# regard to letter case, as SQLite reads it. It is written once.
#
# The lines come in the order of the relationship names. They came in the order
# of a hash, which is another one in every process: the text of a table with
# several keys was not the same twice, and neither was which of two
# declarations got to write the line.

{
  package FB;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package FB::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');

  package FB::Result::Other;
  use base 'DBIO::Core';
  __PACKAGE__->table('other');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');

  package FB::Result::Pair;             # the target of a key of two columns
  use base 'DBIO::Core';
  __PACKAGE__->table('pair');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer', is_nullable => 0 },
    b => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key(qw(a b));

  package FB::Result::TwiceCascade;     # the same key, with actions
  use base 'DBIO::Core';
  __PACKAGE__->table('twice_cascade');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FB::Result::Parent', 'parent_id',
    { on_delete => 'CASCADE', on_update => 'CASCADE' });
  __PACKAGE__->belongs_to(parent_again => 'FB::Result::Parent',
    { 'foreign.id' => 'self.parent_id' },
    { on_delete => 'CASCADE', on_update => 'CASCADE' });

  package FB::Result::TwicePlain;       # the same key, nothing declared
  use base 'DBIO::Core';
  __PACKAGE__->table('twice_plain');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent       => 'FB::Result::Parent', 'parent_id');
  __PACKAGE__->belongs_to(parent_again => 'FB::Result::Parent', 'parent_id');

  package FB::Result::TwiceCase;        # the same action in two letter cases
  use base 'DBIO::Core';
  __PACKAGE__->table('twice_case');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FB::Result::Parent', 'parent_id',
    { on_delete => 'CASCADE' });
  # Declared second, first by name: "again" sorts before "parent".
  __PACKAGE__->belongs_to(again => 'FB::Result::Parent', 'parent_id',
    { on_delete => 'cascade' });

  package FB::Result::TwicePair;        # a key of two columns
  use base 'DBIO::Core';
  __PACKAGE__->table('twice_pair');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    pair_a => { data_type => 'integer', is_nullable => 0 },
    pair_b => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(pair => 'FB::Result::Pair',
    { 'foreign.a' => 'self.pair_a', 'foreign.b' => 'self.pair_b' },
    { on_delete => 'CASCADE' });
  __PACKAGE__->belongs_to(pair_again => 'FB::Result::Pair',
    { 'foreign.b' => 'self.pair_b', 'foreign.a' => 'self.pair_a' },
    { on_delete => 'CASCADE' });

  # Not the same key, three times over: the same column to another table, the
  # same table from another column, and the pair with its columns crossed.
  # Each of these is a key of its own and stays one.
  package FB::Result::Apart;
  use base 'DBIO::Core';
  __PACKAGE__->table('apart');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    first_id  => { data_type => 'integer', is_nullable => 0 },
    second_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(first        => 'FB::Result::Parent', 'first_id');
  __PACKAGE__->belongs_to(first_other  => 'FB::Result::Other',  'first_id');
  __PACKAGE__->belongs_to(second       => 'FB::Result::Parent', 'second_id');
  __PACKAGE__->belongs_to(straight => 'FB::Result::Pair',
    { 'foreign.a' => 'self.first_id', 'foreign.b' => 'self.second_id' });
  __PACKAGE__->belongs_to(crossed => 'FB::Result::Pair',
    { 'foreign.a' => 'self.second_id', 'foreign.b' => 'self.first_id' });

  # Six keys, declared in an order that is neither that of their names nor
  # that of their columns.
  package FB::Result::Six;
  use base 'DBIO::Core';
  __PACKAGE__->table('six');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    map { ("c$_" => { data_type => 'integer', is_nullable => 1 }) } 1 .. 6,
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(zulu    => 'FB::Result::Parent', 'c1');
  __PACKAGE__->belongs_to(alpha   => 'FB::Result::Parent', 'c2');
  __PACKAGE__->belongs_to(mike    => 'FB::Result::Parent', 'c3');
  __PACKAGE__->belongs_to(bravo   => 'FB::Result::Parent', 'c4');
  __PACKAGE__->belongs_to(yankee  => 'FB::Result::Parent', 'c5');
  __PACKAGE__->belongs_to(charlie => 'FB::Result::Parent', 'c6');

  # The same columns and target, and two different actions.
  package FB::Result::Differ;
  use base 'DBIO::Core';
  __PACKAGE__->table('differ');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FB::Result::Parent', 'parent_id',
    { on_delete => 'CASCADE' });
  __PACKAGE__->belongs_to(parent_again => 'FB::Result::Parent', 'parent_id',
    { on_delete => 'SET NULL' });
}

FB->register_class(Parent       => 'FB::Result::Parent');
FB->register_class(Other        => 'FB::Result::Other');
FB->register_class(Pair         => 'FB::Result::Pair');
FB->register_class(TwiceCascade => 'FB::Result::TwiceCascade');
FB->register_class(TwicePlain   => 'FB::Result::TwicePlain');
FB->register_class(TwiceCase    => 'FB::Result::TwiceCase');
FB->register_class(TwicePair    => 'FB::Result::TwicePair');
FB->register_class(Apart        => 'FB::Result::Apart');
FB->register_class(Six          => 'FB::Result::Six');
FB->register_class(Differ       => 'FB::Result::Differ');

# The FOREIGN KEY lines of a CREATE TABLE statement, in the order they stand
# there.
sub fk_lines_in {
  my ($stmt) = @_;
  return [ map { /^\s*(FOREIGN KEY.*?),?$/ ? $1 : () } split /\n/, $stmt ];
}

# The FOREIGN KEY lines install_ddl writes for a table, as written.
sub fk_lines {
  my ($class, $table) = @_;
  for my $stmt (split /\n\n/, DBIO::SQLite::DDL->install_ddl($class)) {
    return fk_lines_in($stmt) if $stmt =~ /\ACREATE TABLE "\Q$table\E" \(/;
  }
  return undef;
}

# The foreign keys SQLite holds for a table, one line of text per key, sorted.
# PRAGMA foreign_key_list has a row per column of a key; they share the id.
sub fk_held {
  my ($dbh, $table) = @_;
  my %key;
  for my $row (@{ $dbh->selectall_arrayref(
    qq{PRAGMA foreign_key_list("$table")}, { Slice => {} },
  ) }) {
    my $key = $key{ $row->{id} } //= { %$row, from => [], to => [] };
    $key->{from}[ $row->{seq} ] = $row->{from};
    $key->{to}[ $row->{seq} ]   = $row->{to};
  }
  return [ sort map {
    sprintf '(%s) -> %s(%s) delete %s update %s',
      join(', ', @{ $_->{from} }), $_->{table}, join(', ', @{ $_->{to} }),
      $_->{on_delete}, $_->{on_update};
  } values %key ];
}

my $PAIR = 'FOREIGN KEY ("pair_a", "pair_b") REFERENCES "pair"("a", "b")';

section "one key, several relationships: the line" => sub {
  is_deeply(fk_lines(FB => 'twice_cascade'),
    [ "$REF ON DELETE CASCADE ON UPDATE CASCADE" ],
    'twice_cascade: two relationships with the same actions write one line');
  is_deeply(fk_lines(FB => 'twice_plain'), [ $REF ],
    'twice_plain: two relationships without an action write one line');
  is_deeply(fk_lines(FB => 'twice_pair'), [ "$PAIR ON DELETE CASCADE" ],
    'twice_pair: a key of two columns declared twice is written once');

  # Of two declarations of one key the first by relationship name writes the
  # line: "again" with its lower case, though "parent" was declared before it.
  is_deeply(fk_lines(FB => 'twice_case'), [ "$REF ON DELETE cascade" ],
    'twice_case: CASCADE and cascade are one action, one line, as the first by name spells it');

  # crossed, first, first_other, second, straight
  is_deeply(fk_lines(FB => 'apart'), [
    'FOREIGN KEY ("second_id", "first_id") REFERENCES "pair"("a", "b")',
    'FOREIGN KEY ("first_id") REFERENCES "parent"("id")',
    'FOREIGN KEY ("first_id") REFERENCES "other"("id")',
    'FOREIGN KEY ("second_id") REFERENCES "parent"("id")',
    'FOREIGN KEY ("first_id", "second_id") REFERENCES "pair"("a", "b")',
  ], 'apart: another target, another column, the columns crossed -- five keys, five lines');
};

# The order of the lines. While it was the hash's, six keys had one chance in
# 720 of coming out in this order: this was red before by chance, not by
# necessity -- a chance of 719 in 720 -- and a run that passed proved nothing.
my @SIX = map { qq{FOREIGN KEY ("c$_") REFERENCES "parent"("id")} } 2, 4, 6, 3, 5, 1;

section "the lines come in the order of the relationship names" => sub {
  # alpha, bravo, charlie, mike, yankee, zulu
  is_deeply(fk_lines(FB => 'six'), \@SIX,
    'six: six keys, written in the order of their relationship names');
};

my $twice     = connect_with_fks('FB');
my $twice_dbh = $twice->storage->dbh;

section "one key, several relationships: installed and used" => sub {
  my $deploy = DBIO::SQLite::Deploy->new(schema => $twice);
  lives_ok { $deploy->install } 'the schema installs';

  is_deeply(fk_held($twice_dbh, 'twice_cascade'),
    [ '(parent_id) -> parent(id) delete CASCADE update CASCADE' ],
    'twice_cascade: SQLite holds one foreign key');
  is_deeply(fk_held($twice_dbh, 'twice_plain'),
    [ '(parent_id) -> parent(id) delete NO ACTION update NO ACTION' ],
    'twice_plain: SQLite holds one foreign key');
  is_deeply(fk_held($twice_dbh, 'twice_case'),
    [ '(parent_id) -> parent(id) delete CASCADE update NO ACTION' ],
    'twice_case: SQLite holds one foreign key');
  is_deeply(fk_held($twice_dbh, 'twice_pair'),
    [ '(pair_a, pair_b) -> pair(a, b) delete CASCADE update NO ACTION' ],
    'twice_pair: SQLite holds one foreign key, of two columns');
  is_deeply(fk_held($twice_dbh, 'apart'), [
    '(first_id) -> other(id) delete NO ACTION update NO ACTION',
    '(first_id) -> parent(id) delete NO ACTION update NO ACTION',
    '(first_id, second_id) -> pair(a, b) delete NO ACTION update NO ACTION',
    '(second_id) -> parent(id) delete NO ACTION update NO ACTION',
    '(second_id, first_id) -> pair(a, b) delete NO ACTION update NO ACTION',
  ], 'apart: SQLite holds all five');

  # A connected schema has its own copy of every source, and its relationships
  # were a hash of their own with an order of their own: the table as installed
  # could differ from what install_ddl says for the class.
  is_deeply(fk_lines_in(table_sql($twice_dbh, 'six')), \@SIX,
    'six: the installed table has its keys in the order of the relationship names');
  is(scalar @{ fk_held($twice_dbh, 'six') }, 6, 'six: SQLite holds all six');

  # The one key that is left is a key: it refuses what it should and does what
  # was declared.
  $twice_dbh->do('INSERT INTO parent (id) VALUES (1), (2), (3)');
  $twice_dbh->do('INSERT INTO pair (a, b) VALUES (1, 2)');

  $twice_dbh->do('INSERT INTO twice_cascade (parent_id) VALUES (1)');
  throws_ok { $twice_dbh->do('INSERT INTO twice_cascade (parent_id) VALUES (99)') }
    qr/FOREIGN KEY constraint failed/,
    'twice_cascade: a row without its parent is refused';
  $twice_dbh->do('UPDATE parent SET id = 10 WHERE id = 1');
  is_deeply($twice_dbh->selectcol_arrayref('SELECT parent_id FROM twice_cascade'), [ 10 ],
    'twice_cascade: ON UPDATE CASCADE, the child follows its parent');
  $twice_dbh->do('DELETE FROM parent WHERE id = 10');
  is_deeply($twice_dbh->selectcol_arrayref('SELECT parent_id FROM twice_cascade'), [],
    'twice_cascade: ON DELETE CASCADE, the child went with its parent');

  $twice_dbh->do('INSERT INTO twice_plain (parent_id) VALUES (2)');
  throws_ok { $twice_dbh->do('INSERT INTO twice_plain (parent_id) VALUES (99)') }
    qr/FOREIGN KEY constraint failed/,
    'twice_plain: a row without its parent is refused';
  throws_ok { $twice_dbh->do('DELETE FROM parent WHERE id = 2') }
    qr/FOREIGN KEY constraint failed/,
    'twice_plain: no action declared, deleting the parent is refused';

  $twice_dbh->do('INSERT INTO twice_case (parent_id) VALUES (3)');
  $twice_dbh->do('DELETE FROM parent WHERE id = 3');
  is_deeply($twice_dbh->selectcol_arrayref('SELECT parent_id FROM twice_case'), [],
    'twice_case: the delete cascades');

  $twice_dbh->do('INSERT INTO twice_pair (pair_a, pair_b) VALUES (1, 2)');
  throws_ok { $twice_dbh->do('INSERT INTO twice_pair (pair_a, pair_b) VALUES (2, 1)') }
    qr/FOREIGN KEY constraint failed/,
    'twice_pair: a row whose pair does not exist is refused';
  $twice_dbh->do('DELETE FROM pair WHERE a = 1 AND b = 2');
  is_deeply($twice_dbh->selectcol_arrayref('SELECT id FROM twice_pair'), [],
    'twice_pair: the delete cascades');

  my $diff = $deploy->diff;
  ok(!$diff->has_changes, 'nothing to change right after the install')
    or diag $diff->summary;
};

# The same columns to the same target, declared with DIFFERENT actions. What
# that should be is undecided (karr k74: refuse it, or let one of them win).
# Until it is decided nothing changes here: each relationship writes its own
# line and SQLite holds two keys with two actions.
#
# The two lines come in the order of the relationship names, "parent" before
# "parent_again", like any others. With two actions on one key that order is
# not without consequence -- SQLite runs the later line's action first -- so
# what such a schema does is now the same in every process. That makes it
# reproducible; it does not make it decided.
#
# This pins what happens today so that it cannot change without anybody
# noticing. It does not say that two keys are right, or that this order is.
section "one key, two different actions: as it is today (karr k74 open)" => sub {
  is_deeply(fk_lines(FB => 'differ'),
    [ "$REF ON DELETE CASCADE", "$REF ON DELETE SET NULL" ],
    'differ: each relationship writes its line, with its own action, in name order');
  is_deeply(fk_held($twice_dbh, 'differ'), [
    '(parent_id) -> parent(id) delete CASCADE update NO ACTION',
    '(parent_id) -> parent(id) delete SET NULL update NO ACTION',
  ], 'differ: SQLite holds two foreign keys');
};

done_testing;
