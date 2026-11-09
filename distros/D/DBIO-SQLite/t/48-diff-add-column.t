use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::SQL::Util ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k64 -- a column that an upgrade ADDS must be the column an install would
# have declared.
#
# It was not. DBIO::SQLite::Diff::Column rebuilt the ADD COLUMN from the
# introspected fields -- type, NOT NULL, DEFAULT -- and a column is more than
# those three. For a target that declares
#
#   owner_id INTEGER REFERENCES owner(id) ON DELETE CASCADE,
#   qty      INTEGER CHECK (qty >= 0),
#   code     TEXT COLLATE NOCASE,
#   tag      TEXT UNIQUE
#
# the diff came out as four bare `ALTER TABLE item ADD COLUMN x TYPE;`. No
# foreign key, no CHECK, no collation, no UNIQUE -- and the next diff reported
# no change, because none of the four is among the fields a column is compared
# by. The loss stayed.
#
# Same cause as karr k56, same cure: the target model carries the statement the
# table was created with (sqlite_master.sql), and the column's declaration is
# in it. Where SQLite takes that declaration in an ADD COLUMN it goes in as
# written. Where it cannot -- UNIQUE or PRIMARY KEY on the column, or a table
# constraint that names the column, which is the form DBIO::SQLite::DDL writes
# every foreign key and every unique constraint in -- the table is rebuilt from
# the target statement (ADR 0003).
#
# Everything below runs the generated SQL in SQLite and then uses the table.
# Matching /ADD COLUMN owner_id/ is what was true all along.

sub memory_dbh {
  my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  $dbh->do('PRAGMA foreign_keys = ON');
  return $dbh;
}

sub introspect { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
}

# The way DBIO::Deploy::Base::_execute_ddl runs a diff: statement by statement.
# It drops a statement that is only a comment; here that dies, because a diff
# that answers a change with a comment has not applied it. No op does: a
# change the diff cannot carry out is refused by as_sql (karr k73,
# t/51-diff-refuse-column-change.t).
sub apply_diff {
  my ($dbh, $diff) = @_;
  for my $stmt (DBIO::SQL::Util::_split_statements($diff->as_sql)) {
    die "the diff emitted a comment instead of a statement: $stmt\n"
      if $stmt =~ /^\s*--/;
    $dbh->do($stmt);
  }
}

sub rebuilds { grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $_[0]->operations } }

sub column_names {
  my ($dbh, $table) = @_;
  return [
    map { $_->{name} } @{ $dbh->selectall_arrayref(
      sprintf('PRAGMA table_xinfo(%s)', $dbh->quote_identifier($table)),
      { Slice => {} },
    ) }
  ];
}

# One part dying must not hide what the others have to say.
sub section {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name: died -- $@");
}

# A table that holds rows before the upgrade: what was there has to be there
# afterwards, whichever way the column got in.
sub source_with_rows {
  my $dbh = memory_dbh();
  $dbh->do('CREATE TABLE owner (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do('CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do(q{INSERT INTO owner (id, name) VALUES (1, 'Ada'), (2, 'Bob')});
  $dbh->do(q{INSERT INTO item (id, name) VALUES (1, 'first'), (2, 'second')});
  return $dbh;
}

sub target_with {
  my (@item_ddl) = @_;
  my $dbh = memory_dbh();
  $dbh->do('CREATE TABLE owner (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do($_) for @item_ddl;
  return $dbh;
}

sub rows_survived {
  my ($dbh, $label) = @_;
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, name FROM item ORDER BY id'),
    [ [ 1, 'first' ], [ 2, 'second' ] ],
    "$label: the rows that were there are still there",
  );
}

sub nothing_left {
  my ($source, $target, $label) = @_;
  my $again = diff_of($source, $target);
  ok(!$again->has_changes, "$label: a second diff has nothing left to do")
    or diag $again->summary;
}

# ---------------------------------------------------------------------------
# 1. What ADD COLUMN can carry goes in by ADD COLUMN, as declared
# ---------------------------------------------------------------------------
#
# REFERENCES (with its ON DELETE), CHECK and COLLATE are all accepted by
# `ALTER TABLE ... ADD COLUMN`. Nothing here needs a rebuild, and none happens:
# a rebuild drops the table, and with it whatever the model does not hold.

section "ADD COLUMN carries the declaration" => sub {
  my $source = source_with_rows();
  my $target = target_with(q{CREATE TABLE item (
    id       INTEGER PRIMARY KEY,
    name     TEXT,
    owner_id INTEGER REFERENCES owner(id) ON DELETE CASCADE,
    qty      INTEGER CHECK (qty >= 0),
    code     TEXT COLLATE NOCASE
  )});

  my $diff = diff_of($source, $target);
  is(scalar(rebuilds($diff)), 0, 'no rebuild for what ADD COLUMN can carry');
  lives_ok { apply_diff($source, $diff) } 'the ADD COLUMN statements apply';

  rows_survived($source, 'ADD COLUMN');

  # ADD COLUMN appends, so the order the statements run in is the order the
  # columns end up in. Sorted by name it was code, owner_id, qty.
  is_deeply(column_names($source, 'item'), column_names($target, 'item'),
    'the added columns are in the order the target declares them');

  # REFERENCES: enforced ...
  throws_ok {
    $source->do(q{INSERT INTO item (id, name, owner_id) VALUES (10, 'orphan', 99)})
  } qr/FOREIGN KEY constraint failed/, 'the added foreign key is enforced';

  # ... and ON DELETE CASCADE came with it.
  $source->do(q{INSERT INTO item (id, name, owner_id) VALUES (11, 'of Bob', 2)});
  $source->do('DELETE FROM owner WHERE id = 2');
  is(
    scalar $source->selectrow_array('SELECT COUNT(*) FROM item WHERE id = 11'), 0,
    'deleting the owner deletes its item (ON DELETE CASCADE)',
  );

  # CHECK
  throws_ok {
    $source->do(q{INSERT INTO item (id, name, qty) VALUES (12, 'negative', -1)})
  } qr/CHECK constraint failed/, 'the added CHECK is enforced';
  lives_ok {
    $source->do(q{INSERT INTO item (id, name, qty) VALUES (13, 'fine', 0)})
  } 'and lets a valid value through';

  # COLLATE
  $source->do(q{INSERT INTO item (id, name, code) VALUES (14, 'cased', 'ABC')});
  is(
    scalar $source->selectrow_array(q{SELECT id FROM item WHERE code = 'abc'}), 14,
    'the added column compares with its collation (COLLATE NOCASE)',
  );

  nothing_left($source, $target, 'ADD COLUMN');
};

# A CHECK may name another column, and ADD COLUMN refuses one that is not
# there yet. Declared order has `low` before `high`; sorted order had it after.
section "ADD COLUMN in declared order" => sub {
  my $source = source_with_rows();
  my $target = target_with(q{CREATE TABLE item (
    id   INTEGER PRIMARY KEY,
    name TEXT,
    low  INTEGER,
    high INTEGER CHECK (high >= low)
  )});

  my $diff = diff_of($source, $target);
  lives_ok { apply_diff($source, $diff) }
    'a column whose CHECK names an earlier new column can be added';
  throws_ok {
    $source->do(q{INSERT INTO item (id, name, low, high) VALUES (10, 'x', 5, 1)})
  } qr/CHECK constraint failed/, 'and the CHECK across the two columns holds';
  nothing_left($source, $target, 'declared order');
};

# The declaration is found in the statement as SQLite stores it: with whatever
# quoting the name was written in, with comments, and with commas and
# parentheses that are not the ones separating the columns.
section "ADD COLUMN from a statement that is not tidy" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  $source->do('CREATE TABLE "odd one" (id INTEGER PRIMARY KEY)');
  $target->do(qq{CREATE TABLE "odd one" (id INTEGER PRIMARY KEY, -- the key, (really
    'sq' TEXT DEFAULT 'a,b)' /* not, a ( column */ ,
    [br ack] TEXT CHECK ([br ack] <> ','),
    `bt` TEXT COLLATE NOCASE -- trailing, comment
  )});
  # ... and as SQLite rewrites it when a column is added later.
  $target->do('ALTER TABLE "odd one" ADD COLUMN later INTEGER CHECK (later IN (1, 2))');

  my $diff = diff_of($source, $target);
  is(scalar(rebuilds($diff)), 0, 'every declaration was found: no rebuild');
  lives_ok { apply_diff($source, $diff) } 'the statements apply';
  is_deeply(column_names($source, 'odd one'), column_names($target, 'odd one'),
    'all the columns arrived, in order');

  $source->do('INSERT INTO "odd one" (id) VALUES (1)');
  is(scalar $source->selectrow_array('SELECT sq FROM "odd one"'), 'a,b)',
    'a default holding a comma and a parenthesis arrived whole');
  throws_ok { $source->do(q{UPDATE "odd one" SET "br ack" = ','}) }
    qr/CHECK constraint failed/, 'the CHECK of a bracket-quoted column holds';
  $source->do(q{UPDATE "odd one" SET bt = 'ABC'});
  is(scalar $source->selectrow_array(q{SELECT id FROM "odd one" WHERE bt = 'abc'}), 1,
    'the collation of a backtick-quoted column holds');
  throws_ok { $source->do('UPDATE "odd one" SET later = 3') }
    qr/CHECK constraint failed/, 'the CHECK of a column added later holds';

  my $again = diff_of($source, $target);
  ok(!$again->has_changes, 'a second diff has nothing left to do')
    or diag $again->summary;
};

# ---------------------------------------------------------------------------
# 2. What ADD COLUMN cannot carry goes in by rebuilding the table
# ---------------------------------------------------------------------------
#
# SQLite refuses `ADD COLUMN ... UNIQUE` and `ADD COLUMN ... PRIMARY KEY`
# outright, and it has no ALTER TABLE that adds a table constraint. For each of
# these the bare ADD COLUMN "worked" and left the constraint out.
#
# [ label, the column and constraint the target adds, a statement the
#   constraint has to refuse, what SQLite says ]

for my $case (
  [ 'UNIQUE on the column',
    'tag TEXT UNIQUE',
    q{INSERT INTO item (id, name, tag) VALUES (10, 'a', 't'), (11, 'b', 't')},
    qr/UNIQUE constraint failed/ ],
  [ 'a named UNIQUE on the column',
    'tag TEXT CONSTRAINT item_tag UNIQUE',
    q{INSERT INTO item (id, name, tag) VALUES (10, 'a', 't'), (11, 'b', 't')},
    qr/UNIQUE constraint failed/ ],
  [ 'a table-level FOREIGN KEY',
    'owner_id INTEGER, FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE',
    q{INSERT INTO item (id, name, owner_id) VALUES (10, 'orphan', 99)},
    qr/FOREIGN KEY constraint failed/ ],
  [ 'a table-level UNIQUE',
    'code TEXT, UNIQUE (code)',
    q{INSERT INTO item (id, name, code) VALUES (10, 'a', 'c'), (11, 'b', 'c')},
    qr/UNIQUE constraint failed/ ],
  [ 'a table-level UNIQUE over an old and the new column',
    'code TEXT, UNIQUE (name, code)',
    q{INSERT INTO item (id, name, code) VALUES (10, 'a', 'c'), (11, 'a', 'c')},
    qr/UNIQUE constraint failed/ ],
  [ 'a named table-level UNIQUE that spells the column differently',
    'Code TEXT, CONSTRAINT item_code UNIQUE ("CODE")',
    q{INSERT INTO item (id, name, code) VALUES (10, 'a', 'c'), (11, 'b', 'c')},
    qr/UNIQUE constraint failed/ ],
  [ 'a table-level CHECK',
    'qty INTEGER, CHECK (qty >= 0)',
    q{INSERT INTO item (id, name, qty) VALUES (10, 'negative', -1)},
    qr/CHECK constraint failed/ ],
) {
  my ($label, $added, $refused, $error) = @$case;

  section $label => sub {
    my $source = source_with_rows();
    my $target = target_with(
      "CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, $added)",
    );

    my $diff = diff_of($source, $target);
    lives_ok { apply_diff($source, $diff) } "$label: the diff applies";
    rows_survived($source, $label);
    throws_ok { $source->do($refused) } $error, "$label: enforced after the upgrade";
    nothing_left($source, $target, $label);
  };
}

# The rebuilt table is the target's in every other respect too: ON DELETE
# CASCADE of a table-level key, and the index the target has on the new column.
section "rebuild: the rest of the declaration" => sub {
  my $source = source_with_rows();
  my $target = target_with(
    q{CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, owner_id INTEGER,
        FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE)},
    'CREATE INDEX item_owner ON item (owner_id)',
  );

  my $diff = diff_of($source, $target);
  is(scalar(rebuilds($diff)), 1, 'a column in a table constraint rebuilds the table');
  lives_ok { apply_diff($source, $diff) } 'the diff applies';

  $source->do(q{INSERT INTO item (id, name, owner_id) VALUES (11, 'of Bob', 2)});
  $source->do('DELETE FROM owner WHERE id = 2');
  is(
    scalar $source->selectrow_array('SELECT COUNT(*) FROM item WHERE id = 11'), 0,
    'deleting the owner deletes its item (ON DELETE CASCADE)',
  );
  ok(
    scalar $source->selectrow_array(
      q{SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = 'item_owner'}),
    'the index on the new column exists',
  );
  nothing_left($source, $target, 'rebuild');
};

# A key column cannot be added either. The table had no key; the target has
# the rowid alias.
section "PRIMARY KEY on the column" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  $source->do('CREATE TABLE note (body TEXT)');
  $source->do(q{INSERT INTO note (body) VALUES ('first'), ('second')});
  $target->do('CREATE TABLE note (body TEXT, id INTEGER PRIMARY KEY)');

  my $diff = diff_of($source, $target);
  lives_ok { apply_diff($source, $diff) } 'the diff applies';
  is_deeply(
    $source->selectcol_arrayref('SELECT body FROM note ORDER BY body'),
    [ 'first', 'second' ],
    'the rows that were there are still there',
  );
  $source->do(q{INSERT INTO note (body) VALUES ('third')});
  is(
    scalar $source->selectrow_array(
      q{SELECT id = rowid FROM note WHERE body = 'third'}), 1,
    'the added key is the rowid alias',
  );
  my $again = diff_of($source, $target);
  ok(!$again->has_changes, 'a second diff has nothing left to do')
    or diag $again->summary;
};

# The four columns of the card, in one upgrade. One of them needs the rebuild,
# so the table is rebuilt once and all four arrive with it.
section "the four of the card together" => sub {
  my $source = source_with_rows();
  my $target = target_with(q{CREATE TABLE item (
    id       INTEGER PRIMARY KEY,
    name     TEXT,
    owner_id INTEGER REFERENCES owner(id) ON DELETE CASCADE,
    qty      INTEGER CHECK (qty >= 0),
    code     TEXT COLLATE NOCASE,
    tag      TEXT UNIQUE
  )});

  my $diff = diff_of($source, $target);
  lives_ok { apply_diff($source, $diff) } 'the diff applies';
  rows_survived($source, 'all four');
  is(
    scalar @{ $source->selectall_arrayref('PRAGMA foreign_key_list(item)') }, 1,
    'the table has its foreign key',
  );

  throws_ok {
    $source->do(q{INSERT INTO item (id, name, owner_id) VALUES (10, 'orphan', 99)})
  } qr/FOREIGN KEY constraint failed/, 'the foreign key is enforced';
  $source->do(q{INSERT INTO item (id, name, owner_id) VALUES (11, 'of Bob', 2)});
  $source->do('DELETE FROM owner WHERE id = 2');
  is(
    scalar $source->selectrow_array('SELECT COUNT(*) FROM item WHERE id = 11'), 0,
    'ON DELETE CASCADE cascades',
  );
  throws_ok {
    $source->do(q{INSERT INTO item (id, name, qty) VALUES (12, 'negative', -1)})
  } qr/CHECK constraint failed/, 'the CHECK is enforced';
  $source->do(q{INSERT INTO item (id, name, code, tag) VALUES (14, 'cased', 'ABC', 't')});
  is(
    scalar $source->selectrow_array(q{SELECT id FROM item WHERE code = 'abc'}), 14,
    'the collation is in effect',
  );
  throws_ok {
    $source->do(q{INSERT INTO item (id, name, tag) VALUES (15, 'again', 't')})
  } qr/UNIQUE constraint failed/, 'the UNIQUE is enforced';

  nothing_left($source, $target, 'all four');
};

# A rebuild is not free -- it drops the table -- so a constraint has to name
# the column to cause one. The column a FOREIGN KEY points at lives in the
# other table: `code` below is owner's, not the item.code being added.
section "no rebuild for a name that only matches the referenced column" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  for my $dbh ($source, $target) {
    $dbh->do('CREATE TABLE owner (id INTEGER PRIMARY KEY, code TEXT UNIQUE)');
  }
  $source->do(q{CREATE TABLE item (id INTEGER PRIMARY KEY, owner_code TEXT,
    FOREIGN KEY (owner_code) REFERENCES owner(code))});
  $target->do(q{CREATE TABLE item (id INTEGER PRIMARY KEY, owner_code TEXT, code TEXT,
    FOREIGN KEY (owner_code) REFERENCES owner(code))});

  my $diff = diff_of($source, $target);
  is(scalar(rebuilds($diff)), 0, 'item.code is in no constraint: plain ADD COLUMN');
  lives_ok { apply_diff($source, $diff) } 'which applies';
  my $again = diff_of($source, $target);
  ok(!$again->has_changes, 'a second diff has nothing left to do')
    or diag $again->summary;
};

# ---------------------------------------------------------------------------
# 3. The live path: Deploy->upgrade for result classes that gained columns
# ---------------------------------------------------------------------------
#
# DBIO::SQLite::DDL writes a belongs_to as `FOREIGN KEY (...) REFERENCES ...`
# and add_unique_constraint as `UNIQUE (...)` -- table constraints, both. So
# this, not the column-level form above, is what an upgrade from result
# classes meets.

{
  package AC::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package AC::V1::Result::Owner;
  use base 'DBIO::Core';
  __PACKAGE__->table('owner');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package AC::V1::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package AC::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package AC::V2::Result::Owner;
  use base 'DBIO::Core';
  __PACKAGE__->table('owner');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package AC::V2::Result::Item;         # gains a foreign key and a unique column
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'text', is_nullable => 0 },
    owner_id => { data_type => 'integer', is_nullable => 1 },
    code     => { data_type => 'varchar', size => 10, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(item_code => ['code']);
  __PACKAGE__->belongs_to(
    owner => 'AC::V2::Result::Owner', 'owner_id', { join_type => 'left' },
  );
}
AC::V1->register_class(Owner => 'AC::V1::Result::Owner');
AC::V1->register_class(Item  => 'AC::V1::Result::Item');
AC::V2->register_class(Owner => 'AC::V2::Result::Owner');
AC::V2->register_class(Item  => 'AC::V2::Result::Item');

section "upgrade adds columns to a result class" => sub {
  my $v1 = AC::V1->connect('dbi:SQLite::memory:');
  $v1->storage->dbh->do('PRAGMA foreign_keys = ON');
  DBIO::SQLite::Deploy->new(schema => $v1)->install;

  my $ada = $v1->resultset('Owner')->create({ name => 'Ada' });
  $v1->resultset('Item')->create({ name => $_ }) for qw(first second);

  my $v2     = AC::V2->connect(sub { $v1->storage->dbh });
  my $deploy = DBIO::SQLite::Deploy->new(schema => $v2);

  my $diff;
  lives_ok { $diff = $deploy->upgrade } 'upgrade that adds the columns applies';
  ok($diff && $diff->has_changes, 'the upgrade had the columns to add');

  # The claim in one line: what the upgrade left is what an install creates.
  # (The rebuild's RENAME puts the table name in quotes; nothing else differs.)
  my $fresh = AC::V2->connect('dbi:SQLite::memory:');
  DBIO::SQLite::Deploy->new(schema => $fresh)->install;
  my $table_sql = sub {
    my $sql = $_[0]->storage->dbh->selectrow_array(
      q{SELECT sql FROM sqlite_master WHERE name = 'item'});
    $sql =~ s/\ACREATE TABLE "item"/CREATE TABLE item/;
    return $sql;
  };
  is($table_sql->($v1), $table_sql->($fresh),
    'the upgraded table has the definition a fresh install gives it');

  is_deeply(
    [ map { $_->name } $v2->resultset('Item')->search({}, { order_by => 'id' })->all ],
    [ 'first', 'second' ],
    'the rows that were there are still there',
  );

  throws_ok {
    $v2->resultset('Item')->create({ name => 'orphan', owner_id => 999 })
  } qr/FOREIGN KEY constraint failed/, 'the added belongs_to is enforced';
  lives_ok {
    $v2->resultset('Item')->create({ name => 'owned', owner_id => $ada->id, code => 'A' })
  } 'and takes an owner that exists';
  throws_ok {
    $v2->resultset('Item')->create({ name => 'twin', code => 'A' })
  } qr/UNIQUE constraint failed/, 'the added unique constraint is enforced';

  ok(!$deploy->diff->has_changes, 'a second diff has nothing left to do');
};

# ---------------------------------------------------------------------------
# 4. A statement the column cannot be found in: rebuild, never the bare form
# ---------------------------------------------------------------------------
#
# The model says the table has the column and the statement does not show it
# -- a model put together by hand, or a statement this reader gets wrong. The
# bare ADD COLUMN is the one answer that is known to be lossy, so as long as
# there is a statement to rebuild from, that is what happens.

section "declaration not found" => sub {
  my $source = source_with_rows();
  my $target = target_with(
    'CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, tag TEXT UNIQUE)',
  );

  my $model = introspect($target);
  $model->{tables}{item}{sql} =~ s/tag TEXT UNIQUE/"other" TEXT UNIQUE/
    or die 'the statement was not changed';

  my $diff = DBIO::SQLite::Diff->new(source => introspect($source), target => $model);
  is(scalar(rebuilds($diff)), 1, 'the table is rebuilt');
  unlike($diff->as_sql, qr/ADD COLUMN/, 'and no ADD COLUMN is emitted for it');
};

# ---------------------------------------------------------------------------
# 5. A model without a statement keeps the column-built form
# ---------------------------------------------------------------------------
#
# target_from_compiled has no database behind it and so no statement. There the
# column is still written from type, NOT NULL and DEFAULT -- which is all such a
# model knows about it.

section "no statement in the model" => sub {
  my $source = memory_dbh();
  $source->do('CREATE TABLE log (id INTEGER PRIMARY KEY)');

  my $model = introspect($source);
  my $target = {
    tables       => { log => { table_name => 'log' } },
    columns      => { log => [
      @{ $model->{columns}{log} },
      { column_name => 'level', data_type => 'TEXT', not_null => 1,
        default_value => q{'info'} },
      { column_name => 'stamp', data_type => 'TEXT', not_null => 0,
        default_value => q{datetime('now')} },
    ] },
    indexes      => {},
    foreign_keys => {},
  };

  my $diff = DBIO::SQLite::Diff->new(source => $model, target => $target);
  is_deeply(
    [ map { $_->as_sql } @{ $diff->operations } ],
    [
      q{ALTER TABLE "log" ADD COLUMN "level" TEXT NOT NULL DEFAULT 'info';},
      q{ALTER TABLE "log" ADD COLUMN "stamp" TEXT DEFAULT (datetime('now'));},
    ],
    'the columns are written from the model, an expression default in parentheses',
  );
  lives_ok { apply_diff($source, $diff) } 'and the statements apply';
};

# ---------------------------------------------------------------------------
# 6. A default SQLite refuses on a populated table: rebuild (karr k65)
# ---------------------------------------------------------------------------
#
# ADD COLUMN ... DEFAULT (datetime('now')) is valid and runs on an empty table;
# on a table with rows SQLite answers "Cannot add a column with non-constant
# default" -- and a diff of two models cannot know which table it has. So a
# parenthesised default and CURRENT_TIME / CURRENT_DATE / CURRENT_TIMESTAMP
# take the rebuild (ADR 0003, amended 2026-10-09), which evaluates the default
# once per copied row. A literal stays an ADD COLUMN, and so does NOT NULL
# without a default: that one is not helped by a rebuild, and fails at SQLite.

section "a non-constant default rebuilds the table" => sub {
  for my $case (
    [ q{TEXT DEFAULT (datetime('now'))}, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/ ],
    [ q{TEXT DEFAULT CURRENT_TIMESTAMP}, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/ ],
    [ q{TEXT DEFAULT current_date},      qr/\A\d{4}-\d\d-\d\d\z/ ],
    [ q{TEXT DEFAULT CURRENT_TIME},      qr/\A\d\d:\d\d:\d\d\z/ ],
    [ q{INTEGER DEFAULT (1 + 2)},        qr/\A3\z/ ],
  ) {
    my ($decl, $value) = @$case;
    my $source = source_with_rows();
    my $target = target_with("CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, stamp $decl)");

    my $diff = diff_of($source, $target);
    is(scalar(rebuilds($diff)), 1, "$decl: the table is rebuilt");
    unlike($diff->as_sql, qr/ADD COLUMN/, "$decl: and not added to");
    lives_ok { apply_diff($source, $diff) } "$decl: the upgrade applies to a table with rows";

    rows_survived($source, $decl);
    my $stamps = $source->selectcol_arrayref('SELECT stamp FROM item ORDER BY id');
    is(scalar(@$stamps), 2, "$decl: both rows have the column");
    like($_, $value, "$decl: and it is filled") for @$stamps;
    nothing_left($source, $target, $decl);
  }
};

section "a constant default stays ADD COLUMN" => sub {
  for my $decl (
    q{TEXT DEFAULT 'none'}, q{INTEGER DEFAULT 5}, q{INTEGER DEFAULT -3},
    q{INTEGER DEFAULT +3}, q{TEXT DEFAULT NULL}, q{INTEGER DEFAULT TRUE},
    q{INTEGER DEFAULT FALSE}, q{TEXT DEFAULT (NULL)}, q{TEXT DEFAULT ('lit')},
    q{INTEGER DEFAULT (-5)},
  ) {
    my $source = source_with_rows();
    my $target = target_with("CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, c $decl)");

    my $diff = diff_of($source, $target);
    is(scalar(rebuilds($diff)), 0, "$decl: no rebuild");
    like($diff->as_sql, qr/ADD COLUMN/, "$decl: ADD COLUMN");
    lives_ok { apply_diff($source, $diff) } "$decl: applies to a table with rows";
    rows_survived($source, $decl);
  }
};

section "an expression after a literal default is not the default" => sub {
  my $source = source_with_rows();
  my $target = target_with(q{CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT,
    qty INTEGER DEFAULT 1 CHECK (qty <> (1 + 1)))});
  is(scalar(rebuilds(diff_of($source, $target))), 0, 'no rebuild');
};

section "NOT NULL without a default still fails loudly" => sub {
  my $source = source_with_rows();
  my $target = target_with(q{CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT, must TEXT NOT NULL)});

  my $diff = diff_of($source, $target);
  is(scalar(rebuilds($diff)), 0, 'no rebuild for it');
  throws_ok { apply_diff($source, $diff) }
    qr/Cannot add a NOT NULL column with default value NULL/,
    'SQLite refuses it for a table with rows';
};

done_testing;
