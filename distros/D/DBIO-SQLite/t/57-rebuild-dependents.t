use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Diff::Rebuild ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k69, k70, k71 -- a rebuild knew only the table.
#
# DBIO::SQLite::Diff::Rebuild is create-new / copy / drop / rename, written
# from the table's statement and a list of column names. What hangs on the
# table, and the connection it runs on, were outside its view:
#
#   k69  a view naming the table made the final RENAME fail -- after the DROP
#        (`error in view ...: no such table`); a trigger on the table went
#        with the DROP and nothing brought it back; and whatever stopped the
#        rebuild half way left the table under <name>__dbio_rebuild and
#        PRAGMA foreign_keys OFF.
#   k70  a generated column was in the copy list: `cannot INSERT into
#        generated column`, after the CREATE.
#   k71  the bracket ended in a fixed PRAGMA foreign_keys=ON, on a connection
#        that had them off as well.
#
# Everything below runs the upgrade in SQLite and then uses what it left
# behind. That the rebuild's text holds a SAVEPOINT says nothing about whether
# the table is back after a failure.

sub memory_dbh {
  return DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub introspect { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
}

# A database made by hand has no result classes; DBIO::SQLite::Deploy only
# needs a schema for its connection.
{
  package HandMade::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

sub deploy_on {
  my ($dbh) = @_;
  return DBIO::SQLite::Deploy->new(
    schema => HandMade::Schema->connect(sub { $dbh }),
  );
}

sub rebuilds { grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $_[0]->operations } }

sub pragma { scalar $_[0]->selectrow_array("PRAGMA $_[1]") }

sub master {
  my ($dbh, $type) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT name FROM sqlite_master WHERE type = ? ORDER BY name}, undef, $type,
  );
}

sub log_lines {
  my ($dbh) = @_;
  my $lines = $dbh->selectcol_arrayref('SELECT msg FROM log ORDER BY rowid');
  $dbh->do('DELETE FROM log');
  return $lines;
}

# One part dying must not hide what the others have to say.
sub section {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name: died -- $@");
}

# ---------------------------------------------------------------------------
# The schema of the first two parts. "item" is what gets rebuilt: its "val"
# becomes NOT NULL in V2. Around it stands everything a rebuild used to trip
# over or lose -- a view that selects from it, a table that references it, and
# (made by hand below, a schema cannot declare them) a trigger on it and a
# trigger on another table that reads it.
#
# The view is declared in the schema: an undeclared one is a table to drop for
# the diff as it stands (karr k67).
# ---------------------------------------------------------------------------
{
  package DepV1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package DepV1::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'text',    is_nullable => 0 },
    val  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package DepV1::Result::Note;
  use base 'DBIO::Core';
  __PACKAGE__->table('note');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    item_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(item => 'DepV1::Result::Item', 'item_id');
}
{
  package DepV1::Result::Log;
  use base 'DBIO::Core';
  __PACKAGE__->table('log');
  __PACKAGE__->add_columns(msg => { data_type => 'text', is_nullable => 1 });
}
{
  package DepV1::Result::ItemView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('item_view');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'text' },
    val  => { data_type => 'integer' },
  );
  __PACKAGE__->result_source_instance->view_definition(
    'SELECT "id", "name", "val" FROM "item"');
}
DepV1->register_class(Item     => 'DepV1::Result::Item');
DepV1->register_class(Note     => 'DepV1::Result::Note');
DepV1->register_class(Log      => 'DepV1::Result::Log');
DepV1->register_class(ItemView => 'DepV1::Result::ItemView');

{
  package DepV2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package DepV2::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'text',    is_nullable => 0 },
    val  => { data_type => 'integer', is_nullable => 0 },   # now NOT NULL
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package DepV2::Result::Note;
  use base 'DBIO::Core';
  __PACKAGE__->table('note');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    item_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(item => 'DepV2::Result::Item', 'item_id');
}
{
  package DepV2::Result::Log;
  use base 'DBIO::Core';
  __PACKAGE__->table('log');
  __PACKAGE__->add_columns(msg => { data_type => 'text', is_nullable => 1 });
}
{
  package DepV2::Result::ItemView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('item_view');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'text' },
    val  => { data_type => 'integer' },
  );
  __PACKAGE__->result_source_instance->view_definition(
    'SELECT "id", "name", "val" FROM "item"');
}
DepV2->register_class(Item     => 'DepV2::Result::Item');
DepV2->register_class(Note     => 'DepV2::Result::Note');
DepV2->register_class(Log      => 'DepV2::Result::Log');
DepV2->register_class(ItemView => 'DepV2::Result::ItemView');

my $ITEM_TRIGGER = q{CREATE TRIGGER item_ai AFTER INSERT ON item BEGIN
  INSERT INTO log (msg) VALUES ('item ' || NEW.name);
END};

# The V1 database, deployed, with its two triggers and two items of which one
# has a note. Foreign keys are enforced on the connection.
sub v1_database {
  my (@items) = @_;
  my $dbh = memory_dbh();
  $dbh->do('PRAGMA foreign_keys = ON');
  DBIO::SQLite::Deploy->new(schema => DepV1->connect(sub { $dbh }))->install;

  $dbh->do($ITEM_TRIGGER);
  $dbh->do(q{CREATE TRIGGER note_ai AFTER INSERT ON note BEGIN
    INSERT INTO log (msg)
    SELECT 'note for ' || name FROM item WHERE id = NEW.item_id;
  END});

  $dbh->do('INSERT INTO item (id, name, val) VALUES (?, ?, ?)', undef, @$_)
    for @items;
  $dbh->do('INSERT INTO note (id, item_id) VALUES (1, 1)');
  log_lines($dbh);
  return $dbh;
}

sub v2_deploy {
  my ($dbh) = @_;
  return DBIO::SQLite::Deploy->new(schema => DepV2->connect(sub { $dbh }));
}

# What has to hold for the item table and everything around it, before an
# upgrade, after one, and after one that failed. Uses the database: each line
# is a statement SQLite runs.
sub dependents_work {
  my ($dbh, $label, $rows) = @_;

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name, val FROM item ORDER BY id'),
    $rows, "$label: the rows of the table",
  );
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name, val FROM item_view ORDER BY id'),
    $rows, "$label: the view answers, with those rows",
  );
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, item_id FROM note'), [ [ 1, 1 ] ],
    "$label: the row of the referencing table",
  );

  $dbh->do(q{INSERT INTO item (id, name, val) VALUES (90, 'probe', 9)});
  is_deeply(log_lines($dbh), ['item probe'],
    "$label: the table's own trigger fires");

  $dbh->do('INSERT INTO note (id, item_id) VALUES (90, 90)');
  is_deeply(log_lines($dbh), ['note for probe'],
    "$label: the trigger of another table that reads this one fires");

  throws_ok { $dbh->do('INSERT INTO note (id, item_id) VALUES (91, 4711)') }
    qr/FOREIGN KEY constraint failed/,
    "$label: the foreign key into the table is enforced";

  $dbh->do('DELETE FROM note WHERE id = 90');
  $dbh->do('DELETE FROM item WHERE id = 90');

  is_deeply(
    [ grep { /__dbio_rebuild/ } @{ master($dbh, 'table') } ], [],
    "$label: no __dbio_rebuild table",
  );
  is(pragma($dbh, 'foreign_keys'), 1, "$label: foreign_keys is ON, as it was");
  is(pragma($dbh, 'legacy_alter_table'), 0,
    "$label: legacy_alter_table is OFF, as it was");
}

# ---------------------------------------------------------------------------
# 1. k69 -- a rebuild with a view, two triggers and a foreign key around it
# ---------------------------------------------------------------------------

section "rebuild with dependents" => sub {
  my @rows = ([ 1, 'first', 10 ], [ 2, 'second', 20 ]);
  my $dbh    = v1_database(@rows);
  my $deploy = v2_deploy($dbh);

  dependents_work($dbh, 'before', \@rows);

  my $diff;
  lives_ok { $diff = $deploy->upgrade }
    'the upgrade lives: a view naming the table does not stop the rename';
  ok($diff && rebuilds($diff), 'and it went through a rebuild')
    or return;

  dependents_work($dbh, 'after the rebuild', \@rows);

  throws_ok { $dbh->do(q{INSERT INTO item (id, name) VALUES (92, 'no val')}) }
    qr/NOT NULL constraint failed: item\.val/,
    'the rebuilt table has the new NOT NULL';

  my $again = $deploy->diff;
  ok(!$again->has_changes, 'a second diff has nothing left to do')
    or diag $again->summary;
};

# ---------------------------------------------------------------------------
# 2. An upgrade whose rebuild fails is no rebuild at all
# ---------------------------------------------------------------------------
#
# The copy fails: a row holds NULL where the new table says NOT NULL. That is
# after the CREATE of the new table. Nothing of the rebuild may be left, and
# the connection is as it was -- then the data is fixed and the same upgrade
# applies.

section "rebuild that fails in the copy" => sub {
  my @rows = ([ 1, 'first', 10 ], [ 2, 'second', undef ]);
  my $dbh    = v1_database(@rows);
  my $deploy = v2_deploy($dbh);
  my $before = $dbh->selectall_arrayref(
    'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name');

  # The deploy looks at the rows first and refuses (karr k91); the copy never
  # runs. That leaves the claim of this part -- a rebuild that fails in the
  # copy is no rebuild at all -- to the diff applied without that look.
  throws_ok { $deploy->upgrade }
    qr/refuses to make the column item\.val NOT NULL/,
    'the upgrade refuses before it runs a statement';
  is_deeply(
    $dbh->selectall_arrayref(
      'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name'),
    $before, 'and the database is as it was',
  );

  my $diff = $deploy->diff;
  $_->data_checks([]) for rebuilds($diff);
  throws_ok { $deploy->apply($diff) }
    qr/NOT NULL constraint failed: item__dbio_rebuild\.val/,
    'the diff applied without that look dies with what SQLite said';

  is_deeply(
    $dbh->selectall_arrayref(
      'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name'),
    $before, 'the database holds what it held before, statement for statement',
  );
  dependents_work($dbh, 'after the failed rebuild', \@rows);

  $dbh->do('UPDATE item SET val = 0 WHERE val IS NULL');
  $rows[1][2] = 0;

  lives_ok { $deploy->upgrade } 'with the row fixed the same upgrade applies';
  dependents_work($dbh, 'after the second attempt', \@rows);
  throws_ok { $dbh->do(q{INSERT INTO item (id, name) VALUES (92, 'no val')}) }
    qr/NOT NULL constraint failed: item\.val/,
    'and the table has the new NOT NULL';
};

# The same for a failure AFTER the DROP, where the original table is gone and
# only the savepoint has it. No upgrade from result classes fails there any
# more, so the op is made by hand, with a trigger statement SQLite refuses; the
# diff is given its operation list instead of building one.

section "rebuild that fails after the DROP" => sub {
  my @rows  = ([ 1, 'first', 10 ], [ 2, 'second', 20 ]);
  my $dbh   = v1_database(@rows);
  my $model = introspect($dbh);
  my $before = $dbh->selectall_arrayref(
    'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name');

  my $op = DBIO::SQLite::Diff::Rebuild->new(
    table_name   => 'item',
    table_sql    => $model->{tables}{item}{sql},
    copy_columns => [qw(id name val)],
    triggers     => [
      'CREATE TRIGGER broken AFTER INSERT ON no_such_table BEGIN SELECT 1; END',
    ],
  );
  my $diff = DBIO::SQLite::Diff->new(
    source => $model, target => $model, operations => [$op],
  );

  throws_ok { deploy_on($dbh)->apply($diff) }
    qr/no such table: main\.no_such_table/,
    'the rebuild dies at the statement after the rename';

  is_deeply(
    $dbh->selectall_arrayref(
      'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name'),
    $before, 'the dropped table is back, with its trigger, statement for statement',
  );
  dependents_work($dbh, 'after the failure behind the DROP', \@rows);
};

# ---------------------------------------------------------------------------
# 3. k70 -- generated columns
# ---------------------------------------------------------------------------
#
# install_ddl cannot declare one, so source and target are two databases made
# by hand. "label" becomes NOT NULL, which is what rebuilds the table. Beside
# it: a VIRTUAL and a STORED generated column that stay what they are, a
# column that is generated in the source and plain in the target -- its
# values are data from now on and have to come along -- and one that is plain
# in the source and generated in the target, which takes its values from the
# expression and none from the old column.

section "rebuild of a table with generated columns" => sub {
  my $source = memory_dbh();
  $source->do(q{CREATE TABLE price (
    id      INTEGER PRIMARY KEY,
    net     INTEGER,
    gross   INTEGER GENERATED ALWAYS AS (net * 2) VIRTUAL,
    total   INTEGER GENERATED ALWAYS AS (net + 1) STORED,
    was_gen INTEGER GENERATED ALWAYS AS (net * 10) STORED,
    now_gen INTEGER,
    label   TEXT
  )});
  $source->do(q{INSERT INTO price (id, net, now_gen, label)
                VALUES (1, 5, 777, 'five'), (2, 7, 888, 'seven')});

  my $target = memory_dbh();
  $target->do(q{CREATE TABLE price (
    id      INTEGER PRIMARY KEY,
    net     INTEGER,
    gross   INTEGER GENERATED ALWAYS AS (net * 2) VIRTUAL,
    total   INTEGER GENERATED ALWAYS AS (net + 1) STORED,
    was_gen INTEGER,
    now_gen INTEGER GENERATED ALWAYS AS (net * 3) VIRTUAL,
    label   TEXT NOT NULL
  )});

  my $diff = diff_of($source, $target);
  ok(scalar rebuilds($diff), 'the table is rebuilt') or return;

  lives_ok { deploy_on($source)->apply($diff) }
    'the rebuild applies: no generated column is written to';

  is_deeply(
    $source->selectall_arrayref(
      'SELECT id, net, gross, total, was_gen, now_gen, label FROM price ORDER BY id'),
    [
      [ 1, 5, 10, 6, 50, 15, 'five' ],
      [ 2, 7, 14, 8, 70, 21, 'seven' ],
    ],
    'the generated values are right, the formerly generated ones were copied, '
    . 'the newly generated ones come from the expression',
  );

  $source->do('UPDATE price SET net = 6, was_gen = 1 WHERE id = 1');
  is_deeply(
    $source->selectrow_arrayref(
      'SELECT gross, total, was_gen, now_gen FROM price WHERE id = 1'),
    [ 12, 7, 1, 18 ],
    'and they are still generated, the formerly generated one is a plain column',
  );

  is_deeply([ grep { /__dbio_rebuild/ } @{ master($source, 'table') } ], [],
    'no __dbio_rebuild table');
  ok(!diff_of($source, $target)->has_changes, 'a second diff has nothing left to do');
};

# ---------------------------------------------------------------------------
# 4. k71 -- the connection is left as it was found
# ---------------------------------------------------------------------------
#
# "parent" is rebuilt (its "name" becomes NOT NULL); "child" references it and
# holds a row that points nowhere.

sub family {
  my (%arg) = @_;
  my $dbh = memory_dbh();
  $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY, name TEXT'
    . ($arg{target} ? ' NOT NULL' : '') . ')');
  $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, '
    . 'parent_id INTEGER REFERENCES parent(id))');
  return $dbh if $arg{target};

  $dbh->do(q{INSERT INTO parent (id, name) VALUES (1, 'one')});
  $dbh->do('INSERT INTO child (id, parent_id) VALUES (1, 1)');
  $dbh->do('INSERT INTO child (id, parent_id) VALUES (2, 4711)') if $arg{dangling};
  return $dbh;
}

section "foreign keys off stay off" => sub {
  my $source = family(dangling => 1);
  is(pragma($source, 'foreign_keys'), 0, 'foreign keys are off on this connection');

  my $diff = diff_of($source, family(target => 1));
  ok(scalar rebuilds($diff), 'the referenced table is rebuilt') or return;

  # With enforcement off a dangling row is the state the caller chose, not
  # something this upgrade did.
  lives_ok { deploy_on($source)->apply($diff) }
    'the upgrade lives: no foreign_key_check on a connection that does not enforce them';
  is(pragma($source, 'foreign_keys'), 0, 'and foreign keys are still off');
  is(scalar $source->selectrow_array('SELECT count(*) FROM child'), 2,
    'the dangling row is where it was');
  throws_ok { $source->do('INSERT INTO parent (id) VALUES (2)') }
    qr/NOT NULL constraint failed: parent\.name/, 'the table was rebuilt';
};

section "foreign keys on stay on, and are checked" => sub {
  my $source = family(dangling => 1);
  $source->do('PRAGMA foreign_keys = ON');
  my $diff = diff_of($source, family(target => 1));

  throws_ok { deploy_on($source)->apply($diff) }
    qr/Foreign key violations after table rebuild: child/,
    'a dangling row is reported where foreign keys are enforced';
  is(pragma($source, 'foreign_keys'), 1, 'and foreign keys are still on');

  my $clean = family();
  $clean->do('PRAGMA foreign_keys = ON');
  lives_ok { deploy_on($clean)->apply(diff_of($clean, family(target => 1))) }
    'without one the upgrade lives';
  is(pragma($clean, 'foreign_keys'), 1, 'and foreign keys are still on');
};

section "legacy_alter_table on stays on" => sub {
  my $source = family();
  $source->do('PRAGMA legacy_alter_table = ON');

  lives_ok { deploy_on($source)->apply(diff_of($source, family(target => 1))) }
    'the upgrade lives';
  is(pragma($source, 'legacy_alter_table'), 1, 'legacy_alter_table is still on');
  is(pragma($source, 'foreign_keys'), 0, 'foreign keys are still off');
};

# ---------------------------------------------------------------------------
# 5. The text of the diff is a complete script
# ---------------------------------------------------------------------------
#
# Deploy::apply runs the statements of a diff; somebody who prints as_sql and
# feeds it to the sqlite3 shell must arrive at the same database. A trigger's
# statement has semicolons inside it, so this is also where a script that is
# cut at every semicolon falls apart.

sub shop {
  my (%arg) = @_;
  my $dbh = memory_dbh();
  $dbh->do('CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT'
    . ($arg{target} ? ' NOT NULL' : '') . ')');
  $dbh->do('CREATE TABLE log (msg TEXT)');
  return $dbh if $arg{target};

  $dbh->do($ITEM_TRIGGER);
  $dbh->do(q{INSERT INTO item (id, name) VALUES (1, 'first')});
  log_lines($dbh);
  return $dbh;
}

section "as_sql is a script" => sub {
  my $applied  = shop();
  my $scripted = shop();
  my $diff     = diff_of($applied, shop(target => 1));
  ok(scalar rebuilds($diff), 'the table is rebuilt') or return;

  my @statements = $diff->statements;
  is($diff->as_sql, join("\n", @statements),
    'as_sql is the statements of the diff, one after the other');
  is_deeply([ grep { /CREATE TRIGGER/ } @statements ], ["$ITEM_TRIGGER;"],
    'the trigger of the rebuilt table is one of them, whole, as it was stored');

  lives_ok { deploy_on($applied)->apply($diff) } 'apply runs them';

  lives_ok {
    local $scripted->{sqlite_allow_multiple_statements} = 1;
    $scripted->do($diff->as_sql);
  } 'and SQLite runs the text as one script';

  for ([ applied => $applied ], [ scripted => $scripted ]) {
    my ($how, $dbh) = @$_;
    is_deeply(master($dbh, 'trigger'), ['item_ai'], "$how: the trigger is there");
    $dbh->do(q{INSERT INTO item (id, name) VALUES (2, 'second')});
    is_deeply(log_lines($dbh), ['item second'], "$how: and fires");
    throws_ok { $dbh->do('INSERT INTO item (id) VALUES (3)') }
      qr/NOT NULL constraint failed: item\.name/, "$how: the table was rebuilt";
  }

  is_deeply(
    $scripted->selectall_arrayref(
      'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name'),
    $applied->selectall_arrayref(
      'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name'),
    'both ways end in the same database',
  );
};

# The rebuild is a SAVEPOINT, not a BEGIN: it also runs inside a transaction
# the caller has open, and is that transaction's to keep or to take back.

section "inside the caller's transaction" => sub {
  for my $end (qw(rollback commit)) {
    my $dbh  = shop();
    my $diff = diff_of($dbh, shop(target => 1));
    my ($before) = $dbh->selectrow_array(
      q{SELECT sql FROM sqlite_master WHERE name = 'item'});

    $dbh->begin_work;
    lives_ok { deploy_on($dbh)->apply($diff) }
      "$end: the rebuild applies inside an open transaction";
    $dbh->$end;

    my ($after) = $dbh->selectrow_array(
      q{SELECT sql FROM sqlite_master WHERE name = 'item'});
    if ($end eq 'rollback') {
      is($after, $before, 'rolled back by the caller, the table is the old one');
    }
    else {
      like($after, qr/NOT NULL/, 'committed by the caller, it is the new one');
    }
    is_deeply(master($dbh, 'trigger'), ['item_ai'], "$end: with its trigger");
    is_deeply([ grep { /__dbio_rebuild/ } @{ master($dbh, 'table') } ], [],
      "$end: no __dbio_rebuild table");
  }
};

# A statement with a semicolon inside it that is no trigger: a string. apply
# hands it to SQLite whole as well.

section "a semicolon in a string" => sub {
  my $source = memory_dbh();
  $source->do('CREATE TABLE item (id INTEGER PRIMARY KEY)');
  my $target = memory_dbh();
  $target->do('CREATE TABLE item (id INTEGER PRIMARY KEY)');
  $target->do(q{CREATE TABLE list (id INTEGER PRIMARY KEY, sep TEXT DEFAULT '; ')});
  $target->do('CREATE TABLE last (id INTEGER PRIMARY KEY)');

  lives_ok { deploy_on($source)->apply(diff_of($source, $target)) }
    'a table whose default holds a semicolon is created';
  $source->do('INSERT INTO list (id) VALUES (1)');
  is(scalar $source->selectrow_array('SELECT sep FROM list'), '; ',
    'with the default as declared');
  is_deeply(master($source, 'table'), [qw(item last list)],
    'and the statements around it ran too');
};

done_testing;
