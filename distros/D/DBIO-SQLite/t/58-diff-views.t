use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr k67.
#
# DBIO::SQLite::Introspect::Tables lists views under `tables`, with
# kind => 'view', and virtual tables too, with kind => 'table'. The diff took
# every entry there for a table:
#
#   a view the schema no longer declares   DROP TABLE "v"
#                                          -> use DROP VIEW to delete view v
#   a view whose definition changed        nothing: only columns were compared
#   a view that selects one more column    ALTER TABLE "v" ADD COLUMN ...
#                                          -> Cannot add a column to a view
#   a virtual table with another column    ALTER TABLE "docs" ADD COLUMN ...
#                                          -> virtual tables may not be altered
#
# A view is a view: it is dropped and created as one, replaced when its
# definition differs, and never gets a column op. A virtual table is created
# and dropped, and a change of one is refused, because SQLite cannot alter it.
#
# Everything here runs the upgrade in SQLite and then uses what it left.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Diff;
use DBIO::SQLite::Diff::View;
use DBIO::SQLite::Introspect;

sub memory_dbh {
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $dbh->do('PRAGMA foreign_keys = ON');
  return $dbh;
}

sub introspect { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

# One part dying must not hide what the others have to say.
sub section {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name: died -- $@");
}

sub master {
  my ($dbh, $name) = @_;
  return $dbh->selectrow_array(
    'SELECT type FROM sqlite_master WHERE name = ?', undef, $name);
}

# Where a statement stands in the diff, by the first one that matches.
sub position {
  my ($diff, $match) = @_;
  my @statements = $diff->statements;
  my ($at) = grep { $statements[$_] =~ $match } 0 .. $#statements;
  return $at;
}

# ---------------------------------------------------------------------------
# Schemas, built from a list of sources. A source with `view` is a view
# declared the way t/104view.t's schema declares one.
# ---------------------------------------------------------------------------
my $SEQ = 0;

sub schema {
  my (@sources) = @_;
  my $ns = 'KindDiff::S' . ++$SEQ;
  eval "package $ns; use base 'DBIO::Schema'; __PACKAGE__->load_components('SQLite'); 1"    ## no critic (ProhibitStringyEval)
    or die $@;

  while (my ($name, $spec) = splice @sources, 0, 2) {
    my $class = "${ns}::Result::$name";
    eval "package $class; use base 'DBIO::Core'; 1"    ## no critic (ProhibitStringyEval)
      or die $@;
    $class->load_components('SQLite::Result') if $spec->{indexes};
    $class->table_class('DBIO::ResultSource::View') if defined $spec->{view};
    $class->table($spec->{table});
    $class->add_columns(@{ $spec->{columns} });
    $class->set_primary_key(@{ $spec->{pk} }) if $spec->{pk};
    $class->result_source_instance->view_definition($spec->{view})
      if defined $spec->{view};
    $class->sqlite_index(@$_) for @{ $spec->{indexes} // [] };
    $ns->register_class($name => $class);
  }
  return $ns;
}

my @ID = (id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 });
sub text    { map { $_ => { data_type => 'text',    is_nullable => 1 } } @_ }
sub integer { map { $_ => { data_type => 'integer', is_nullable => 1 } } @_ }

# The table every part has: item (id, name, val) and whatever is added.
sub item {
  my (%more) = @_;
  return (Item => {
    table   => 'item',
    columns => [ @ID, text('name'), integer('val'), @{ $more{columns} // [] } ],
    pk      => ['id'],
    indexes => $more{indexes},
  });
}

sub view {
  my ($name, $definition, @columns) = @_;
  return (join('', map { ucfirst } split /_/, $name) => {
    table => $name, view => $definition, columns => [ text(@columns) ],
  });
}

my $NAMES = 'SELECT "id", "name" FROM "item"';

sub deploy_for {
  my ($class, $dbh) = @_;
  return DBIO::SQLite::Deploy->new(schema => $class->connect(sub { $dbh }));
}

my @ITEMS = ([ 1, 'anvil', 1 ], [ 2, 'bell', 2 ], [ 3, 'crate', 3 ]);

# A database installed from a schema, with three items in it.
sub database {
  my ($class) = @_;
  my $dbh = memory_dbh();
  deploy_for($class, $dbh)->install;
  $dbh->do('INSERT INTO item (id, name, val) VALUES (?, ?, ?)', undef, @$_)
    for @ITEMS;
  return $dbh;
}

# What every upgrade here has to do: report, apply, keep the rows, settle.
# Returns the diff, for what a part wants to say about its statements.
sub upgrade_ok {
  my ($label, $deploy, $dbh, @summary) = @_;

  # A first argument 'allow_destructive' says the case drops something the
  # schema does not declare, and releases it; any other case runs without
  # the release and has to be no destructive diff.
  my $allow = (@summary && !ref $summary[0] && $summary[0] eq 'allow_destructive')
    ? shift(@summary) && 1 : 0;

  my $diff = $deploy->diff;
  ok($diff->has_changes, "$label: the diff has changes");
  my $summary = $diff->summary;
  like($summary, $_, "$label: the summary says $_") for @summary;
  is(scalar(() = $diff->destructive_operations) ? 1 : 0, $allow,
    "$label: the diff is " . ($allow ? '' : 'not ') . 'destructive');

  lives_ok { $deploy->apply($diff, allow_destructive => $allow) } "$label: the upgrade applies"
    or diag(eval { $diff->as_sql } // $@);

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name, val FROM item ORDER BY id'),
    \@ITEMS, "$label: the rows that were there are still there",
  );

  my $again = eval { $deploy->diff };
  ok($again && !$again->has_changes, "$label: a second diff is empty")
    or diag($again ? $again->summary : $@);

  return $diff;
}

# ---------------------------------------------------------------------------
# 1. The three cases of the card
# ---------------------------------------------------------------------------

section "a declared view removed from the schema" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));
  $dbh->do(q{CREATE TRIGGER item_names_ins INSTEAD OF INSERT ON item_names
    BEGIN INSERT INTO item (name) VALUES (NEW.name); END});

  my $diff = upgrade_ok('view removed', deploy_for(schema(item()), $dbh), $dbh,
    'allow_destructive', qr/^- view: item_names$/m);

  is($diff->as_sql, 'DROP VIEW "item_names";',
    'it is dropped by DROP VIEW, and that is the whole diff');
  is(master($dbh, 'item_names'), undef, 'the view is gone');
  is(master($dbh, 'item_names_ins'), undef,
    'and its INSTEAD OF trigger went with it');
};

section "a view whose definition changed, with the same columns" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));
  my $v2  = schema(item(),
    view(item_names => qq{$NAMES WHERE "val" > 1}, qw(id name)));

  my $diff = upgrade_ok('view changed', deploy_for($v2, $dbh), $dbh,
    qr/^- view: item_names$/m, qr/^\+ view: item_names$/m);

  is_deeply(
    [ map { ref $_ } @{ $diff->operations } ],
    [ ('DBIO::SQLite::Diff::View') x 2 ],
    'two view ops and nothing else',
  );
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name FROM item_names ORDER BY id'),
    [ [ 2, 'bell' ], [ 3, 'crate' ] ],
    'the view returns the rows of its new definition',
  );
};

section "a view that selects one more column" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));
  my $v2  = schema(item(),
    view(item_names => 'SELECT "id", "name", "val" FROM "item"', qw(id name val)));

  my $diff = upgrade_ok('view widened', deploy_for($v2, $dbh), $dbh,
    qr/^- view: item_names$/m, qr/^\+ view: item_names$/m);

  unlike($diff->as_sql, qr/ALTER TABLE/, 'it is replaced, not altered');
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name, val FROM item_names ORDER BY id'),
    \@ITEMS, 'the view has its third column',
  );
};

# ---------------------------------------------------------------------------
# 2. A view only the database has
# ---------------------------------------------------------------------------

section "a view created by hand" => sub {
  my $class = schema(item());
  my $dbh   = database($class);
  $dbh->do('CREATE VIEW by_hand AS SELECT name FROM item');

  my $diff = upgrade_ok('undeclared view', deploy_for($class, $dbh), $dbh,
    'allow_destructive', qr/^- view: by_hand$/m);

  is($diff->as_sql, 'DROP VIEW "by_hand";', 'it is dropped as a view');
  is(master($dbh, 'by_hand'), undef, 'and is gone');
};

# The view as a database deployed before every name was quoted holds it. It is
# the view the schema declares, and nothing is to be done.
section "the declared view under a bare name" => sub {
  my $dbh = database(schema(item()));
  $dbh->do(qq{CREATE VIEW item_names /* as it was written then */\n  AS $NAMES});

  my $diff = deploy_for(
    schema(item(), view(item_names => $NAMES, qw(id name))), $dbh)->diff;
  ok(!$diff->has_changes, 'a view whose name is not quoted is the same view')
    or diag($diff->summary);
};

# ---------------------------------------------------------------------------
# 3. One name, a table on one side and a view on the other
# ---------------------------------------------------------------------------

section "a table in the database, a view in the schema" => sub {
  my $dbh = database(schema(item(),
    Thing => { table => 'thing', columns => [ @ID, text('name') ], pk => ['id'] }));
  $dbh->do(q{INSERT INTO thing (id, name) VALUES (1, 'a row of the table')});

  my $diff = upgrade_ok('table to view',
    deploy_for(schema(item(), view(thing => $NAMES, qw(id name))), $dbh), $dbh,
    'allow_destructive', qr/^- table: thing$/m, qr/^\+ view: thing$/m);

  is_deeply(
    [ map { ref($_) . ' ' . $_->action } @{ $diff->operations } ],
    [ 'DBIO::SQLite::Diff::Table drop', 'DBIO::SQLite::Diff::View create' ],
    'the table is dropped as a table, the view created as a view',
  );
  is(master($dbh, 'thing'), 'view', 'the name is a view afterwards');
  is_deeply(
    $dbh->selectall_arrayref('SELECT name FROM thing ORDER BY id'),
    [ map { [ $_->[1] ] } @ITEMS ], 'which selects from item',
  );
};

section "a view in the database, a table in the schema" => sub {
  my $dbh = database(schema(item(), view(thing => $NAMES, qw(id name))));

  my $diff = upgrade_ok('view to table',
    deploy_for(schema(item(),
      Thing => { table => 'thing', columns => [ @ID, text('name') ], pk => ['id'] }),
      $dbh), $dbh,
    'allow_destructive', qr/^- view: thing$/m, qr/^\+ table: thing$/m);

  is_deeply(
    [ map { ref($_) . ' ' . $_->action } @{ $diff->operations } ],
    [ 'DBIO::SQLite::Diff::View drop', 'DBIO::SQLite::Diff::Table create' ],
    'the view is dropped as a view, then the table created as a table',
  );
  is(master($dbh, 'thing'), 'table', 'the name is a table afterwards');
  lives_ok { $dbh->do(q{INSERT INTO thing (name) VALUES ('stored')}) }
    'which takes a row';
};

# ---------------------------------------------------------------------------
# 4. A replaced view keeps its INSTEAD OF trigger
# ---------------------------------------------------------------------------

section "the trigger of a replaced view" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));
  $dbh->do(q{CREATE TRIGGER item_names_ins INSTEAD OF INSERT ON item_names
    BEGIN
      INSERT INTO item (name, val) VALUES (NEW.name, 7);
    END});

  my $v2 = schema(item(),
    view(item_names => qq{$NAMES WHERE "val" > 1}, qw(id name)));
  my $diff = upgrade_ok('view with a trigger', deploy_for($v2, $dbh), $dbh,
    qr/^\+ view: item_names$/m);

  is(master($dbh, 'item_names_ins'), 'trigger',
    'the trigger is there after the view was dropped and created');
  lives_ok { $dbh->do(q{INSERT INTO item_names (name) VALUES ('probe')}) }
    'an INSERT into the view is accepted';
  is_deeply(
    $dbh->selectall_arrayref(q{SELECT name, val FROM item WHERE name = 'probe'}),
    [ [ 'probe', 7 ] ], 'and the trigger did what it does',
  );
};

# ---------------------------------------------------------------------------
# 5. Order
# ---------------------------------------------------------------------------
#
# ALTER TABLE ... DROP COLUMN reads the whole schema: a view that names the
# column stops it, and so does an index over it.

section "a view changes and the column it named is dropped" => sub {
  my $dbh = database(schema(item(columns => [ text('old') ]),
    view(item_names => 'SELECT "id", "name", "old" FROM "item"', qw(id name old))));

  my $v2   = schema(item(), view(item_names => $NAMES, qw(id name)));
  my $diff = upgrade_ok('view and column', deploy_for($v2, $dbh), $dbh,
    'allow_destructive', qr/^- view: item_names$/m, qr/-column: item\.old/);

  my $drop_view   = position($diff, qr/\ADROP VIEW/);
  my $drop_column = position($diff, qr/DROP COLUMN "old"/);
  ok(defined $drop_view && defined $drop_column && $drop_view < $drop_column,
    'the view is dropped before the column is');

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name FROM item_names ORDER BY id'),
    [ map { [ @$_[ 0, 1 ] ] } @ITEMS ], 'the new view answers',
  );
  is_deeply(
    [ map { $_->{column_name} } @{ introspect($dbh)->{columns}{item} } ],
    [qw(id name val)], 'and the column is gone',
  );
};

section "a column is dropped together with the index on it" => sub {
  my $dbh = database(schema(item(
    columns => [ text('code') ],
    indexes => [ [ idx_item_code => { columns => ['code'] } ] ],
  )));

  my $diff = upgrade_ok('column and index', deploy_for(schema(item()), $dbh), $dbh,
    'allow_destructive', qr/-index: idx_item_code on item/, qr/-column: item\.code/);

  is_deeply(
    [ $diff->statements ],
    [ 'DROP INDEX "idx_item_code";', 'ALTER TABLE "item" DROP COLUMN "code";' ],
    'the index goes first',
  );
  is(master($dbh, 'idx_item_code'), undef, 'the index is gone');
  is_deeply(
    [ map { $_->{column_name} } @{ introspect($dbh)->{columns}{item} } ],
    [qw(id name val)], 'and the column is gone',
  );
};

# item.val becomes NOT NULL: the table is rebuilt.
sub item_not_null {
  return (Item => {
    table   => 'item',
    columns => [ @ID, text('name'),
      val => { data_type => 'integer', is_nullable => 0 } ],
    pk      => ['id'],
  });
}

section "a view on a table that the same upgrade rebuilds" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));

  my $v2   = schema(item_not_null(), view(item_names => $NAMES, qw(id name)));
  my $diff = upgrade_ok('rebuild under a view', deploy_for($v2, $dbh), $dbh,
    qr/^~ table rebuild: item\b/m);

  is(scalar(grep { $_->isa('DBIO::SQLite::Diff::View') } @{ $diff->operations }),
    0, 'the view is the same view and is left alone');
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name FROM item_names ORDER BY id'),
    [ map { [ @$_[ 0, 1 ] ] } @ITEMS ], 'it answers after the rebuild',
  );
  throws_ok { $dbh->do(q{INSERT INTO item (name) VALUES ('no val')}) }
    qr/NOT NULL constraint failed/, 'and the table has its new column';
};

section "a view that changes on a table that is rebuilt" => sub {
  my $dbh = database(schema(item(), view(item_names => $NAMES, qw(id name))));

  my $v2 = schema(item_not_null(),
    view(item_names => qq{$NAMES WHERE "val" > 1}, qw(id name)));
  my $diff = upgrade_ok('rebuild and view', deploy_for($v2, $dbh), $dbh,
    qr/^~ table rebuild: item\b/m, qr/^\+ view: item_names$/m);

  my @at = map { position($diff, $_) }
    qr/\ADROP VIEW/, qr/RENAME TO "item"/, qr/\ACREATE VIEW/;
  is_deeply([ sort { $a <=> $b } @at ], \@at,
    'the view is dropped, the table rebuilt, the view created');
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name FROM item_names ORDER BY id'),
    [ [ 2, 'bell' ], [ 3, 'crate' ] ], 'the view returns its new rows',
  );
};

# ---------------------------------------------------------------------------
# 6. A declared view over a column the schema no longer has
# ---------------------------------------------------------------------------
#
# SQLite creates such a view without a word (CREATE VIEW does not look at the
# tables) and fails when it is used. The target of an upgrade is a deployment
# of the schema that is then introspected, and PRAGMA table_xinfo uses the
# view: the diff dies while the target model is built, before there is a diff
# and so before anything is applied.
#
# That holds for a definition that names the column BARE, as this one does.
# The same definition in double quotes is the part after this one.
section "a declared view names a column that is gone" => sub {
  my $definition = 'SELECT id, val FROM item';
  my $dbh = database(schema(item(), view(item_vals => $definition, qw(id val))));

  my $broken = schema(
    Item => { table => 'item', columns => [ @ID, text('name') ], pk => ['id'] },
    view(item_vals => $definition, qw(id val)),
  );
  my $deploy = deploy_for($broken, $dbh);

  throws_ok { $deploy->diff } qr/no such column: val/,
    'the diff dies on the view the schema itself cannot run';
  throws_ok { $deploy->upgrade } qr/no such column: val/, 'and so does upgrade';

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, val FROM item_vals ORDER BY id'),
    [ map { [ @$_[ 0, 2 ] ] } @ITEMS ],
    'nothing was applied: the database has its column and its view',
  );
};

# The same view with its names in double quotes: SELECT "id", "val" FROM
# "item". SQLite reads a double-quoted name that resolves to nothing as a
# string literal, so for SQLite this view is valid -- it selects the string
# 'val' in every row. Nothing dies: the target is built, the diff drops the
# column, the upgrade applies, and the view answers with the string.
#
# That is SQLite's double-quoted-string rule acting on the schema's own view
# definition, and a fresh install of the schema gives the very same view. The
# diff does not read the body of a view. This part is here so that the
# behaviour is known, not because it is wanted.
section "the same view with its names in double quotes" => sub {
  my $definition = 'SELECT "id", "val" FROM "item"';
  my $dbh = database(schema(item(), view(item_vals => $definition, qw(id val))));

  my $without_val = schema(
    Item => { table => 'item', columns => [ @ID, text('name') ], pk => ['id'] },
    view(item_vals => $definition, qw(id val)),
  );
  my $deploy = deploy_for($without_val, $dbh);

  my $diff;
  lives_ok { $diff = $deploy->diff } 'the diff is built';
  is($diff->as_sql, 'ALTER TABLE "item" DROP COLUMN "val";',
    'and drops the column; the view is the same statement and gets no op');
  lives_ok { $deploy->apply($diff, allow_destructive => 1) }
    'the upgrade applies, released: it drops a column';

  my $rows = $dbh->selectall_arrayref('SELECT * FROM item_vals ORDER BY id');
  is_deeply($rows, [ map { [ $_->[0], 'val' ] } @ITEMS ],
    q{the view returns the string 'val' where the column was});

  my $fresh = memory_dbh();
  deploy_for($without_val, $fresh)->install;
  $fresh->do('INSERT INTO item (id, name) VALUES (?, ?)', undef, @$_[ 0, 1 ])
    for @ITEMS;
  is_deeply($fresh->selectall_arrayref('SELECT * FROM item_vals ORDER BY id'),
    $rows, 'as it does in a fresh install of that schema');
  ok(!$deploy->diff->has_changes, 'a second diff is empty');
};

# ---------------------------------------------------------------------------
# 7. What counts as a changed view
# ---------------------------------------------------------------------------
sub view_ops {
  my ($old_sql, $new_sql) = @_;
  my $entry = sub { { v => { table_name => 'v', kind => 'view', sql => $_[0] } } };
  return [ map { $_->action }
    DBIO::SQLite::Diff::View->diff($entry->($old_sql), $entry->($new_sql)) ];
}

my $QUOTED = 'CREATE VIEW "v" AS SELECT "id", "name" FROM "item" WHERE val = 1';

for my $same (
  [ 'a bare name'      => 'CREATE VIEW v AS SELECT "id", "name" FROM "item" WHERE val = 1' ],
  [ 'backticks'        => 'CREATE VIEW `v` AS SELECT "id", "name" FROM "item" WHERE val = 1' ],
  [ 'brackets'         => 'CREATE VIEW [v] AS SELECT "id", "name" FROM "item" WHERE val = 1' ],
  [ 'other whitespace' => qq{CREATE VIEW v\n  AS SELECT "id","name"\n  FROM "item"   WHERE val = 1} ],
  [ 'a comment'        => qq{CREATE VIEW v /* x */ AS SELECT "id", "name" -- y\nFROM "item" WHERE val = 1} ],
  [ 'itself'           => $QUOTED ],
) {
  my ($what, $sql) = @$same;
  is_deeply(view_ops($sql, $QUOTED), [], "the same view: $what, old to new");
  is_deeply(view_ops($QUOTED, $sql), [], "the same view: $what, new to old");
}

# Behind the name the statement is the SQL the schema gave, compared as it
# stands. A respelling there is replaced once and is the same from then on.
for my $changed (
  [ 'another value'              => 'CREATE VIEW "v" AS SELECT "id", "name" FROM "item" WHERE val = 2' ],
  [ 'no WHERE'                   => 'CREATE VIEW "v" AS SELECT "id", "name" FROM "item"' ],
  [ 'another column'             => 'CREATE VIEW "v" AS SELECT "id", "sku" FROM "item" WHERE val = 1' ],
  [ 'a column list'              => 'CREATE VIEW "v" ("a", "b") AS SELECT "id", "name" FROM "item" WHERE val = 1' ],
  [ 'a name inside quoted'       => 'CREATE VIEW "v" AS SELECT "id", "name" FROM "item" WHERE "val" = 1' ],
  [ 'a string for a name inside' => q{CREATE VIEW "v" AS SELECT "id", 'name' FROM "item" WHERE val = 1} ],
  [ 'a keyword in another case'  => 'CREATE VIEW "v" AS select "id", "name" FROM "item" WHERE val = 1' ],
  [ 'another view name'          => 'CREATE VIEW "w" AS SELECT "id", "name" FROM "item" WHERE val = 1' ],
) {
  my ($what, $sql) = @$changed;
  is_deeply(view_ops($QUOTED, $sql), [qw(drop create)], "a changed view: $what");
  is_deeply(view_ops($sql, $QUOTED), [qw(drop create)], "a changed view: $what, the other way");
}

# ---------------------------------------------------------------------------
# 8. Virtual tables, and what else needs two databases made by hand
# ---------------------------------------------------------------------------
#
# Two databases made by hand: a schema cannot declare a virtual table.
{
  package KindDiff::Empty;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

sub apply_to {
  my ($dbh, $diff, %opt) = @_;
  return DBIO::SQLite::Deploy->new(
    schema => KindDiff::Empty->connect(sub { $dbh }),
  )->apply($diff, %opt);
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
}

# A pair of databases with the item table in both, and what each gets on top.
sub pair {
  my ($source_sql, $target_sql) = @_;
  my @dbh = (memory_dbh(), memory_dbh());
  for my $dbh (@dbh) {
    $dbh->do('CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, val INTEGER)');
    $dbh->do('INSERT INTO item (id, name, val) VALUES (?, ?, ?)', undef, @$_)
      for @ITEMS;
  }
  $dbh[0]->do($_) for @$source_sql;
  $dbh[1]->do($_) for @$target_sql;
  return @dbh;
}

sub all_objects {
  my ($dbh) = @_;
  return $dbh->selectall_arrayref(
    'SELECT type, name, sql FROM sqlite_master ORDER BY type, name');
}

# A change of a virtual table: reported, refused by as_sql and by apply, and
# nothing of the diff applied -- not the new table that stands beside it.
sub refused_ok {
  my ($label, $source, $target, $reason) = @_;
  my $before = all_objects($source);

  my $diff = diff_of($source, $target);
  ok($diff->has_changes, "$label: the diff has changes");
  like($diff->summary, qr/^! table: docs \(refused: .*$reason/m,
    "$label: the summary lists the table and the reason");
  is_deeply(
    [ grep { !$_->isa('DBIO::SQLite::Diff::Table') } @{ $diff->operations } ], [],
    "$label: no column op, no index op and no rebuild",
  );

  throws_ok { $diff->as_sql } qr/Cannot change table docs: .*$reason/,
    "$label: as_sql throws, naming the table and the reason";
  # The refusal of apply is the guard of DBIO::Deploy::Base (core ADR 0080):
  # it names the summary of the refused operation, which carries the reason.
  throws_ok { apply_to($source, $diff, allow_destructive => 1) }
    qr/Refusing to apply the diff.*! table: docs \(refused: .*$reason/s,
    "$label: apply refuses, naming the table and the reason, even released";

  is_deeply(all_objects($source), $before, "$label: nothing was applied");
  is_deeply(
    $source->selectall_arrayref('SELECT id, name, val FROM item ORDER BY id'),
    \@ITEMS, "$label: the rows are there",
  );
}

# ---------------------------------------------------------------------------
# 9. A view the target has no statement for
# ---------------------------------------------------------------------------
#
# A model built by hand can list a view -- kind => 'view' -- without its
# CREATE VIEW statement. There is nothing to create it from: a view cannot be
# written from its columns. The create op wrote the statement ";" for it,
# which the DDL run drops, so the diff reported a change, applied nothing and
# said nothing. It is refused instead (karr k73's way): as_sql throws, naming
# the view and the reason, the summary still lists it, and apply throws before
# it has run a statement -- the table that is new in the same diff included.
section "a view without a statement in the target" => sub {
  my ($source) = pair([], []);
  my $before   = all_objects($source);

  my $target = introspect($source);
  $target->{tables}{item_names} = { table_name => 'item_names', kind => 'view' };
  $target->{columns}{item_names} = [ { column_name => 'name', data_type => 'TEXT' } ];
  $target->{tables}{extra} = {
    table_name => 'extra', kind => 'table',
    sql => 'CREATE TABLE extra (id INTEGER PRIMARY KEY)',
  };
  $target->{columns}{extra} =
    [ { column_name => 'id', data_type => 'INTEGER', is_pk => 1 } ];

  my $diff = DBIO::SQLite::Diff->new(source => introspect($source), target => $target);
  ok($diff->has_changes, 'the diff has changes');
  is($diff->summary, "+ table: extra\n+ view: item_names",
    'the summary lists the view, beside the table that is new');

  my $refusal = qr/Cannot create view item_names: the target model holds no CREATE VIEW statement/;
  throws_ok { $diff->as_sql } $refusal,
    'as_sql throws, naming the view and the reason';
  unlike($@, qr/\n./, 'in one line');
  throws_ok { $diff->statements } $refusal, 'and so does statements';
  throws_ok { apply_to($source, $diff) } $refusal, 'apply throws the same';

  is_deeply(all_objects($source), $before,
    'nothing was applied: the new table of the same diff is not there');

  # A view that goes needs no statement.
  my $drop = DBIO::SQLite::Diff::View->new(
    action => 'drop', view_name => 'item_names', view_info => { kind => 'view' });
  is($drop->as_sql, 'DROP VIEW "item_names";', 'a drop op is not affected');
};

SKIP: {
  eval { memory_dbh()->do('CREATE VIRTUAL TABLE probe USING fts5(body)'); 1 }
    or skip 'this libsqlite has no FTS5: virtual tables not tested', 1;

  my $DOCS  = 'CREATE VIRTUAL TABLE docs USING fts5(body)';
  my $EXTRA = 'CREATE TABLE extra (id INTEGER PRIMARY KEY)';

  section "a virtual table that is gone" => sub {
    my ($source, $target) = pair(
      [ $DOCS, q{INSERT INTO docs (body) VALUES ('a stored text')} ], []);

    my $diff = diff_of($source, $target);
    is($diff->as_sql, 'DROP TABLE "docs";', 'it is dropped, by one statement');
    like($diff->summary, qr/^- table: docs$/m, 'which the summary names');
    lives_ok { apply_to($source, $diff, allow_destructive => 1) }
    'the drop applies, released: it drops a table';

    is_deeply(
      [ grep { /docs/ } map { $_->[1] } @{ all_objects($source) } ], [],
      'the virtual table and its shadow tables are gone',
    );
    is_deeply(
      $source->selectall_arrayref('SELECT id, name, val FROM item ORDER BY id'),
      \@ITEMS, 'the rows of the other table are there',
    );
    ok(!diff_of($source, $target)->has_changes, 'a second diff is empty');
  };

  section "the same virtual table" => sub {
    my ($source, $target) = pair(
      [$DOCS], [qq{CREATE VIRTUAL TABLE "docs"\n  USING fts5(body)}]);
    my $diff = diff_of($source, $target);
    ok(!$diff->has_changes, 'however its name is quoted: nothing to do')
      or diag($diff->summary);
  };

  section "a virtual table whose definition changed" => sub {
    my ($source, $target) = pair(
      [$DOCS],
      [ q{CREATE VIRTUAL TABLE docs USING fts5(body, tokenize = 'porter')}, $EXTRA ],
    );
    refused_ok('definition changed', $source, $target,
      'definition as a virtual table differs');
  };

  section "a virtual table with one more column" => sub {
    my ($source, $target) = pair(
      [$DOCS], [ 'CREATE VIRTUAL TABLE docs USING fts5(body, title)', $EXTRA ]);
    refused_ok('column added', $source, $target,
      'definition as a virtual table differs');
  };

  section "a virtual table that is a plain table in the target" => sub {
    my ($source, $target) = pair(
      [$DOCS], [ 'CREATE TABLE docs (body TEXT, title TEXT)', $EXTRA ]);
    refused_ok('virtual to plain', $source, $target,
      'virtual table in the source and a plain table in the target');
  };

  section "a plain table that is a virtual table in the target" => sub {
    my ($source, $target) = pair(
      [ 'CREATE TABLE docs (body TEXT)', 'CREATE INDEX docs_body ON docs (body)' ],
      [ $DOCS, $EXTRA ],
    );
    refused_ok('plain to virtual', $source, $target,
      'plain table in the source and a virtual table in the target');
  };
}

done_testing;
