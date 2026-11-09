use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr k72.
#
# On a table both sides have, DBIO::SQLite::Diff compared the columns' type,
# NOT NULL and default, and the explicit indexes. Whatever else the table
# declares never entered: its primary key, its UNIQUE constraints, its foreign
# keys with their ON DELETE / ON UPDATE, its CHECKs, a column's COLLATE, a
# generated column's expression. Two databases that differ in any of these
# diffed to nothing, and an upgrade did nothing.
#
# None of it can be altered in place, so a difference rebuilds the table from
# the target's CREATE TABLE statement, and the rebuild says why.
#
# A key, a UNIQUE and a foreign key are what a result class declares, so one
# only the database has goes. A CHECK, a COLLATE, a generated column, WITHOUT
# ROWID and STRICT no result class can declare: there the target is compared
# only in what it states, and what only the database has is left alone.
#
# Where DBIO::SQLite::DDL can declare the thing, the case goes through
# Deploy->upgrade with result classes; where it cannot (CHECK, COLLATE,
# generated columns, WITHOUT ROWID, STRICT) through two databases made by
# hand. Every case runs the upgrade in SQLite and then uses the table.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Diff;
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

sub rebuilds { grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $_[0]->operations } }

# ---------------------------------------------------------------------------
# Part 1 -- result classes, through Deploy->upgrade
# ---------------------------------------------------------------------------
#
# owner and depot are two parents; item points at owner, or at whatever a
# variant says. Each variant is a schema of its own.
my $SEQ = 0;

sub schema {
  my (%item) = @_;
  my $ns = 'TableDiff::S' . ++$SEQ;
  eval "package $ns; use base 'DBIO::Schema'; __PACKAGE__->load_components('SQLite'); 1"    ## no critic (ProhibitStringyEval)
    or die $@;

  for my $parent (qw(Owner Depot)) {
    my $class = "${ns}::Result::$parent";
    eval "package $class; use base 'DBIO::Core'; 1"    ## no critic (ProhibitStringyEval)
      or die $@;
    $class->table(lc $parent);
    $class->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text', is_nullable => 1 },
    );
    $class->set_primary_key('id');
    $ns->register_class($parent => $class);
  }

  my $class = "${ns}::Result::Item";
  eval "package $class; use base 'DBIO::Core'; 1"    ## no critic (ProhibitStringyEval)
    or die $@;
  $class->table('item');
  $class->add_columns(
    id       => { data_type => 'integer', is_nullable => 0,
                  is_auto_increment => $item{pk} ? 0 : 1 },
    owner_id => { data_type => 'integer', is_nullable => 1 },
    sku      => { data_type => 'text', is_nullable => 0 },
    @{ $item{columns} // [ name => { data_type => 'text', is_nullable => 1 } ] },
  );
  $class->set_primary_key(@{ $item{pk} // ['id'] });
  $class->add_unique_constraint(@$_) for @{ $item{unique} // [] };
  if (my $rel = $item{belongs_to}) {
    my ($parent, $attrs) = @$rel;
    $class->belongs_to(owner => "${ns}::Result::$parent", 'owner_id', $attrs // {});
  }
  $ns->register_class(Item => $class);
  return $ns;
}

sub deploy_for {
  my ($class, $dbh) = @_;
  return DBIO::SQLite::Deploy->new(schema => $class->connect(sub { $dbh }));
}

my @ITEMS = ([ 1, 1, 'A-1', 'anvil' ], [ 2, 2, 'B-2', 'bell' ]);

sub database {
  my ($class) = @_;
  my $dbh = memory_dbh();
  deploy_for($class, $dbh)->install;
  $dbh->do(q{INSERT INTO owner (id, name) VALUES (1, 'Ada'), (2, 'Bob')});
  $dbh->do(q{INSERT INTO depot (id, name) VALUES (1, 'north')});
  $dbh->do('INSERT INTO item (id, owner_id, sku, name) VALUES (?, ?, ?, ?)',
    undef, @$_) for @ITEMS;
  return $dbh;
}

# What every case has to do: report the change and its reason, apply, keep
# the rows, settle. Returns the diff.
sub upgrade_ok {
  my ($label, $deploy, $dbh, $reason, $rows, %opt) = @_;
  my $allow = $opt{allow_destructive} ? 1 : 0;

  my $diff = $deploy->diff;
  ok($diff->has_changes, "$label: the diff has changes");
  like($diff->summary, qr/^~ table rebuild: item \(.*$reason/m,
    "$label: the summary names the table and the reason");
  is(scalar(() = $diff->destructive_operations) ? 1 : 0, $allow,
    "$label: the diff is " . ($allow ? '' : 'not ') . 'destructive');

  lives_ok { $deploy->apply($diff, allow_destructive => $allow) } "$label: the upgrade applies"
    or diag(eval { $diff->as_sql } // $@);

  is_deeply(
    $dbh->selectall_arrayref('SELECT id, owner_id, sku FROM item ORDER BY id'),
    $rows // [ map { [ @$_[ 0 .. 2 ] ] } @ITEMS ],
    "$label: the rows that were there are still there",
  );

  my $again = eval { $deploy->diff };
  ok($again && !$again->has_changes, "$label: a second diff is empty")
    or diag($again ? $again->summary : $@);

  return $diff;
}

my @OWNER  = (belongs_to => ['Owner']);
my @NO_KEY = (belongs_to => [ 'Owner', { is_foreign_key_constraint => 0 } ]);

# --- foreign keys ----------------------------------------------------------

# The link to karr k66: install_ddl writes ON DELETE since then, and a
# database deployed before has the key without it.
section "ON DELETE CASCADE added to an existing belongs_to" => sub {
  my $dbh = database(schema(@OWNER));
  upgrade_ok('action added',
    deploy_for(schema(belongs_to => [ 'Owner', { on_delete => 'CASCADE' } ]), $dbh),
    $dbh, qr/foreign key \(owner_id\) -> owner \(id\) ON DELETE CASCADE added/);

  $dbh->do('DELETE FROM owner WHERE id = 2');
  is_deeply($dbh->selectall_arrayref('SELECT id FROM item ORDER BY id'), [ [1] ],
    'deleting the owner deletes its item');
};

section "the action of a foreign key changed" => sub {
  my $dbh = database(schema(belongs_to => [ 'Owner', { on_delete => 'CASCADE' } ]));
  upgrade_ok('action changed',
    deploy_for(schema(belongs_to => [ 'Owner', { on_delete => 'SET NULL' } ]), $dbh),
    $dbh, qr/ON DELETE SET NULL added; foreign key .* ON DELETE CASCADE removed/);

  $dbh->do('DELETE FROM owner WHERE id = 2');
  is_deeply(
    $dbh->selectall_arrayref('SELECT id, owner_id FROM item ORDER BY id'),
    [ [ 1, 1 ], [ 2, undef ] ],
    'deleting the owner keeps the item and empties its owner_id',
  );
};

section "a foreign key removed" => sub {
  my $dbh = database(schema(@OWNER));
  throws_ok { $dbh->do(q{INSERT INTO item (id, owner_id, sku) VALUES (9, 99, 'Z')}) }
    qr/FOREIGN KEY constraint failed/, 'before: a dangling owner_id is refused';

  upgrade_ok('key removed', deploy_for(schema(@NO_KEY), $dbh), $dbh,
    qr/foreign key \(owner_id\) -> owner \(id\) removed/);

  lives_ok { $dbh->do(q{INSERT INTO item (id, owner_id, sku) VALUES (9, 99, 'Z')}) }
    'afterwards a dangling owner_id is accepted';
};

section "a foreign key added on an existing column" => sub {
  my $dbh = database(schema(@NO_KEY));
  lives_ok { $dbh->do(q{INSERT INTO item (id, owner_id, sku) VALUES (9, 1, 'Z')}) }
    'before: the column takes any value';
  $dbh->do('DELETE FROM item WHERE id = 9');

  upgrade_ok('key added', deploy_for(schema(@OWNER), $dbh), $dbh,
    qr/foreign key \(owner_id\) -> owner \(id\) added/);

  throws_ok { $dbh->do(q{INSERT INTO item (id, owner_id, sku) VALUES (9, 99, 'Z')}) }
    qr/FOREIGN KEY constraint failed/, 'afterwards a dangling owner_id is refused';
};

section "a foreign key pointed at another table" => sub {
  my $dbh = database(schema(@OWNER));
  $dbh->do('UPDATE item SET owner_id = 1');    # depot has only id 1

  upgrade_ok('key retargeted', deploy_for(schema(belongs_to => ['Depot']), $dbh),
    $dbh, qr/foreign key \(owner_id\) -> depot \(id\) added; foreign key \(owner_id\) -> owner \(id\) removed/,
    [ [ 1, 1, 'A-1' ], [ 2, 1, 'B-2' ] ]);

  throws_ok { $dbh->do(q{INSERT INTO item (id, owner_id, sku) VALUES (9, 2, 'Z')}) }
    qr/FOREIGN KEY constraint failed/,
    'owner 2 exists, depot 2 does not: the key is checked against depot';
};

# --- UNIQUE ----------------------------------------------------------------

section "UNIQUE added on an existing column" => sub {
  my $dbh = database(schema(@OWNER));
  upgrade_ok('unique added',
    deploy_for(schema(@OWNER, unique => [ [ item_sku => ['sku'] ] ]), $dbh),
    $dbh, qr/unique \(sku\) added/);

  throws_ok { $dbh->do(q{INSERT INTO item (id, sku) VALUES (9, 'A-1')}) }
    qr/UNIQUE constraint failed/, 'a second row with the same sku is refused';
};

section "UNIQUE removed" => sub {
  my $dbh = database(schema(@OWNER, unique => [ [ item_sku => ['sku'] ] ]));
  upgrade_ok('unique removed', deploy_for(schema(@OWNER), $dbh), $dbh,
    qr/unique \(sku\) removed/);

  lives_ok { $dbh->do(q{INSERT INTO item (id, sku) VALUES (9, 'A-1')}) }
    'a second row with the same sku is accepted';
};

# SQLite's own DROP COLUMN refuses this one. For UNIQUE written on the column
# it says `cannot drop UNIQUE column`; for the table constraint
# DBIO::SQLite::DDL writes, UNIQUE ("code"), it says `error in table item after
# drop column: expressions prohibited in PRIMARY KEY and UNIQUE constraints` --
# the name no longer resolves and is read as a string.
section "a column dropped together with its UNIQUE constraint" => sub {
  my @name = (name => { data_type => 'text', is_nullable => 1 });
  my @code = (code => { data_type => 'text', is_nullable => 1 });
  my $dbh  = database(schema(@OWNER,
    columns => [ @name, @code ], unique => [ [ item_code => ['code'] ] ]));

  my $diff = upgrade_ok('unique column dropped',
    deploy_for(schema(@OWNER, columns => [@name]), $dbh), $dbh,
    qr/unique \(code\) removed/, undef, allow_destructive => 1);

  unlike($diff->as_sql, qr/DROP COLUMN/, 'the rebuild takes the place of DROP COLUMN');
  is_deeply(
    [ map { $_->{column_name} } @{ introspect($dbh)->{columns}{item} } ],
    [qw(id owner_id sku name)], 'the column is gone',
  );
};

# --- primary key -----------------------------------------------------------

section "the primary key changed from one column to two" => sub {
  my $dbh = database(schema(@OWNER, pk => ['id']));
  upgrade_ok('key widened',
    deploy_for(schema(@OWNER, pk => [ 'id', 'sku' ]), $dbh), $dbh,
    qr/primary key \(id\) -> \(id, sku\)/);

  lives_ok { $dbh->do(q{INSERT INTO item (id, sku) VALUES (1, 'other')}) }
    'the same id with another sku is a row of its own';
  throws_ok { $dbh->do(q{INSERT INTO item (id, sku) VALUES (1, 'A-1')}) }
    qr/UNIQUE constraint failed/, 'the same id and sku is not';
};

# --- no rebuild for nothing ------------------------------------------------

# A database deployed before bccd4a1 has its FOREIGN KEY lines in a hash's
# order, and may hold one key twice (karr k74). It is the table the schema
# declares.
section "the same keys twice and in another order" => sub {
  my $class = schema(@OWNER);
  my $dbh   = memory_dbh();
  $dbh->do('CREATE TABLE owner (id INTEGER PRIMARY KEY NOT NULL, name TEXT)');
  $dbh->do('CREATE TABLE depot (id INTEGER PRIMARY KEY NOT NULL, name TEXT)');
  $dbh->do(q{CREATE TABLE item (
    id INTEGER PRIMARY KEY NOT NULL,
    owner_id INTEGER,
    sku TEXT NOT NULL,
    name TEXT,
    FOREIGN KEY (owner_id) REFERENCES owner(id),
    FOREIGN KEY (owner_id) REFERENCES Owner(id) ON DELETE no action
  )});

  is(scalar @{ introspect($dbh)->{foreign_keys}{item} }, 2,
    'the database holds the key twice');
  my $diff = deploy_for($class, $dbh)->diff;
  ok(!$diff->has_changes, 'and that is no difference from the key declared once')
    or diag($diff->summary);
};

# ---------------------------------------------------------------------------
# Part 2 -- two databases made by hand
# ---------------------------------------------------------------------------
{
  package TableDiff::Empty;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
}

sub apply_to {
  my ($dbh, $diff) = @_;
  return DBIO::SQLite::Deploy->new(
    schema => TableDiff::Empty->connect(sub { $dbh }),
  )->apply($diff);
}

my @ROWS = ([ 1, 'Anvil', 5 ], [ 2, 'bell', 7 ]);

# A source and a target with the table t (id, name, qty) as each declares it.
sub pair {
  my ($source_sql, $target_sql) = @_;
  my @dbh = (memory_dbh(), memory_dbh());
  $dbh[0]->do($source_sql);
  $dbh[1]->do($target_sql);
  $dbh[0]->do('INSERT INTO t (id, name, qty) VALUES (?, ?, ?)', undef, @$_)
    for @ROWS;
  return @dbh;
}

sub changed_ok {
  my ($label, $source, $target, $reason) = @_;

  my $diff = diff_of($source, $target);
  ok($diff->has_changes, "$label: the diff has changes");
  like($diff->summary, qr/^~ table rebuild: t \(.*$reason/m,
    "$label: the summary names the table and the reason");

  lives_ok { apply_to($source, $diff) } "$label: the diff applies"
    or diag(eval { $diff->as_sql } // $@);

  is_deeply(
    $source->selectall_arrayref('SELECT id, name, qty FROM t ORDER BY id'),
    \@ROWS, "$label: the rows that were there are still there",
  );

  my $again = diff_of($source, $target);
  ok(!$again->has_changes, "$label: a second diff is empty")
    or diag($again->summary);
  return $diff;
}

my $PLAIN = 'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER)';

# No result class can declare a CHECK, a COLLATE, a generated column, WITHOUT
# ROWID or STRICT, so a target that has none of a kind states nothing about
# it: what only the live table has is left alone (core ADR 0019, a field the
# target leaves unstated is not compared). Such a table is not rebuilt for it.
sub left_alone_ok {
  my ($label, $source, $target) = @_;
  my $diff = diff_of($source, $target);
  ok(!$diff->has_changes, "$label: only the database has it, and there is no op")
    or diag($diff->summary);
}

# --- CHECK -----------------------------------------------------------------

section "a column CHECK added" => sub {
  my ($source, $target) = pair($PLAIN,
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER CHECK (qty >= 0))');
  changed_ok('column check added', $source, $target,
    qr/check on column qty: \(qty >= 0\) added/);
  throws_ok { $source->do('UPDATE t SET qty = -1') }
    qr/CHECK constraint failed/, 'the CHECK holds';
};

section "a column CHECK changed" => sub {
  my ($source, $target) = pair(
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER CHECK (qty >= 0))',
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER CHECK (qty >= 6))');
  my $diff = diff_of($source, $target);
  like($diff->summary, qr/\(qty >= 6\) added; check on column qty: \(qty >= 0\) removed/,
    'the summary shows the new CHECK and the old one');

  # Row 1 has qty 5, which the new CHECK forbids. The rebuild copies the rows
  # into the new table by INSERT, SQLite checks each against the CHECK the new
  # table has, the INSERT fails, and apply rolls the rebuild back.
  throws_ok { apply_to($source, $diff) } qr/CHECK constraint failed/,
    'a row the new CHECK forbids stops the rebuild';
  is_deeply(
    $source->selectall_arrayref('SELECT id, name, qty FROM t ORDER BY id'),
    \@ROWS, 'and the table is there as before, with its rows',
  );

  $source->do('UPDATE t SET qty = 6 WHERE id = 1');
  lives_ok { apply_to($source, diff_of($source, $target)) }
    'once the rows fit, the diff applies';
  throws_ok { $source->do('UPDATE t SET qty = 5') }
    qr/CHECK constraint failed/, 'and the new CHECK holds';
  ok(!diff_of($source, $target)->has_changes, 'a second diff is empty');
};

section "a column CHECK only the database has" => sub {
  my ($source, $target) = pair(
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER CHECK (qty >= 0))',
    $PLAIN);
  left_alone_ok('column check', $source, $target);
  throws_ok { $source->do('UPDATE t SET qty = -1 WHERE id = 1') }
    qr/CHECK constraint failed/, 'the CHECK still holds';
};

section "a table CHECK added" => sub {
  my $checked =
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER, CHECK (qty <> id))';

  my ($source, $target) = pair($PLAIN, $checked);
  changed_ok('table check added', $source, $target,
    qr/table check \(qty <> id\) added/);
  throws_ok { $source->do('UPDATE t SET qty = id') }
    qr/CHECK constraint failed/, 'the CHECK holds';
};

section "a table CHECK only the database has" => sub {
  my ($source, $target) = pair(
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER, CHECK (qty <> id))',
    $PLAIN);
  left_alone_ok('table check', $source, $target);
  throws_ok { $source->do('UPDATE t SET qty = id WHERE id = 1') }
    qr/CHECK constraint failed/, 'the CHECK still holds';
};

# A target that states table CHECKs has stated all of them: the two sets are
# compared, and one only the database has goes with the rebuild.
section "a table CHECK beside the ones the target states" => sub {
  my ($source, $target) = pair(
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER, '
    . 'CHECK (qty <> id), CHECK (qty < 100))',
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER, CHECK (qty <> id))');
  changed_ok('extra table check', $source, $target,
    qr/table check \(qty < 100\) removed/);
  lives_ok { $source->do('UPDATE t SET qty = 500 WHERE id = 1') }
    'a value the extra CHECK forbade is accepted';
  throws_ok { $source->do('UPDATE t SET qty = id') }
    qr/CHECK constraint failed/, 'and the CHECK the target states holds';
};

# The case the card names: the column that is new appears only in the CHECK of
# a column that was there. The diff saw one ADD COLUMN and no change of qty.
section "a new column named only in the CHECK of an old column" => sub {
  my ($source, $target) = pair($PLAIN,
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, '
    . 'qty INTEGER CHECK (qty <= cap), cap INTEGER DEFAULT 100)');
  my $diff = changed_ok('check over a new column', $source, $target,
    qr/check on column qty: \(qty <= cap\) added/);

  is_deeply($source->selectall_arrayref('SELECT cap FROM t ORDER BY id'),
    [ [100], [100] ], 'the new column has its default in the rows that were there');
  throws_ok { $source->do('UPDATE t SET qty = 101') }
    qr/CHECK constraint failed/, 'and the CHECK of the old column holds';
};

# --- COLLATE ---------------------------------------------------------------

section "COLLATE NOCASE added" => sub {
  my ($source, $target) = pair($PLAIN,
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT COLLATE NOCASE, qty INTEGER)');
  is($source->selectrow_array(q{SELECT id FROM t WHERE name = 'anvil'}), undef,
    'before: the comparison minds the letter case');
  changed_ok('collation added', $source, $target,
    qr/collation of column name: none -> nocase/);
  is($source->selectrow_array(q{SELECT id FROM t WHERE name = 'anvil'}), 1,
    'afterwards it does not');
};

section "a COLLATE only the database has" => sub {
  my ($source, $target) = pair(
    'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT COLLATE NOCASE, qty INTEGER)',
    $PLAIN);
  left_alone_ok('collation', $source, $target);
  is($source->selectrow_array(q{SELECT id FROM t WHERE name = 'anvil'}), 1,
    'the comparison is still case-insensitive');
};

# --- generated columns -----------------------------------------------------

section "the expression of a generated column changed" => sub {
  my ($source, $target) = pair(
    $PLAIN =~ s/\)\z/, twice INTEGER GENERATED ALWAYS AS (qty * 2) VIRTUAL)/r,
    $PLAIN =~ s/\)\z/, twice INTEGER GENERATED ALWAYS AS (qty * 3) VIRTUAL)/r);
  changed_ok('generated changed', $source, $target,
    qr/generated expression of column twice: \(qty \* 2 VIRTUAL\) -> \(qty \* 3 VIRTUAL\)/);
  is_deeply($source->selectall_arrayref('SELECT twice FROM t ORDER BY id'),
    [ [15], [21] ], 'the column has the values of the new expression');
};

section "a generated column that is a plain one in the target" => sub {
  my ($source, $target) = pair(
    $PLAIN =~ s/\)\z/, twice INTEGER GENERATED ALWAYS AS (qty * 2) VIRTUAL)/r,
    $PLAIN =~ s/\)\z/, twice INTEGER)/r);
  left_alone_ok('generated', $source, $target);
  is_deeply($source->selectall_arrayref('SELECT twice FROM t ORDER BY id'),
    [ [10], [14] ], 'the column is still computed');
};

section "a plain column that is generated in the target" => sub {
  my ($source, $target) = pair(
    $PLAIN =~ s/\)\z/, twice INTEGER)/r,
    $PLAIN =~ s/\)\z/, twice INTEGER GENERATED ALWAYS AS (qty * 2) VIRTUAL)/r);
  changed_ok('generated added', $source, $target,
    qr/generated expression of column twice: none -> \(qty \* 2 VIRTUAL\)/);
  is_deeply($source->selectall_arrayref('SELECT twice FROM t ORDER BY id'),
    [ [10], [14] ], 'the column is computed afterwards');
};

# --- WITHOUT ROWID, STRICT -------------------------------------------------

for my $option ('WITHOUT ROWID', 'STRICT') {
  section "$option added" => sub {
    my ($source, $target) = pair($PLAIN, "$PLAIN $option");
    changed_ok("$option added", $source, $target, qr/\Q$option\E added/);
    like(
      scalar $source->selectrow_array(q{SELECT sql FROM sqlite_master WHERE name = 't'}),
      qr/\)\s*\Q$option\E\z/, "the table is $option afterwards",
    );
  };

  section "$option only the database has" => sub {
    my ($source, $target) = pair("$PLAIN $option", $PLAIN);
    left_alone_ok($option, $source, $target);
    like(
      scalar $source->selectrow_array(q{SELECT sql FROM sqlite_master WHERE name = 't'}),
      qr/\)\s*\Q$option\E\z/, "the table is still $option",
    );
  };
}

# STRICT beside WITHOUT ROWID: the option the introspector used to miss.
section "STRICT added to a WITHOUT ROWID table" => sub {
  my ($source, $target) = pair("$PLAIN WITHOUT ROWID", "$PLAIN WITHOUT ROWID, STRICT");
  changed_ok('STRICT beside WITHOUT ROWID', $source, $target, qr/STRICT added/);
  throws_ok { $source->do(q{UPDATE t SET qty = 'not a number' WHERE id = 1}) }
    qr/cannot store TEXT value in INTEGER column/, 'the table is strict afterwards';
};

# --- no rebuild for nothing ------------------------------------------------

# SQLite rewrites a table's statement when a column is added: the declaration
# is spliced in before the closing parenthesis, as the ALTER wrote it. It is
# the table one statement declares.
section "a table grown by ADD COLUMN against the same table in one statement" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  $_->do('CREATE TABLE owner (id INTEGER PRIMARY KEY)') for $source, $target;

  $source->do('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)');
  $source->do('ALTER TABLE t ADD COLUMN owner_id INTEGER REFERENCES owner(id) '
    . 'ON DELETE CASCADE CHECK (owner_id > 0)');
  $source->do('ALTER TABLE t ADD COLUMN code TEXT COLLATE NOCASE');

  $target->do(q{CREATE TABLE "t" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "owner_id" INTEGER REFERENCES "owner"("id") ON DELETE CASCADE
      CHECK (owner_id > 0),   -- as one statement declares it
    "code" TEXT COLLATE nocase
  )});

  my $diff = diff_of($source, $target);
  ok(!$diff->has_changes, 'nothing to do') or diag($diff->summary);
};

# A model without statements states no keys and no constraints: nothing of
# the above is compared for it.
section "a model without statements" => sub {
  my $class = schema(belongs_to => [ 'Owner', { on_delete => 'CASCADE' } ],
    unique => [ [ item_sku => ['sku'] ] ]);
  my $dbh = database($class);

  my $live   = introspect($dbh);
  my $target = {
    tables       => { map { $_ => { table_name => $_ } } keys %{ $live->{tables} } },
    columns      => $live->{columns},
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::SQLite::Diff->new(source => $live, target => $target);
  is(scalar(rebuilds($diff)), 0,
    'an installed database with a foreign key and a UNIQUE is not rebuilt for it');
  ok(!$diff->has_changes, 'and there is no other op') or diag($diff->summary);
};

done_testing;
