use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;
use DBIO::Schema::ModelCompiler ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Util qw(default_value_sql pk_is_rowid_alias);

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k56 -- a table that an upgrade ADDS must be the table an install would
# have created.
#
# It was not. DBIO::SQLite::Diff::Table rebuilt the CREATE TABLE of a new table
# from the introspected column list, and the column list does not hold the
# table: PRAGMA table_xinfo reports `id INTEGER PRIMARY KEY` as type INTEGER
# with pk=1, a UNIQUE constraint only as an automatic index (which Diff::Index
# skips on purpose), a foreign key's ON DELETE in another PRAGMA altogether, and
# an expression default without the parentheses SQLite's grammar requires around
# it. So every result class added after the first deploy got a table with
#
#   id INTEGER NOT NULL          -- no rowid alias: create() without id fails
#   (no UNIQUE)                  -- duplicates accepted
#   REFERENCES a(id)             -- ON DELETE CASCADE gone
#   DEFAULT datetime('now')      -- syntax error, the upgrade aborts
#
# The target model already carries the real statement -- sqlite_master.sql, the
# same text the table rebuild has always reused (ADR 0003). A create uses it
# now. Rebuilding from columns is left as the way out for a model that has no
# statement, which is what target_from_compiled produces.
#
# Everything below runs the generated SQL in SQLite and then uses the table.
# A string comparison alone is what let this through: t/31-diff.t matched
# /CREATE TABLE author/ and /id INTEGER/, and both were true.

sub memory_dbh {
  return DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub introspect { DBIO::SQLite::Introspect->new(dbh => $_[0])->model }

sub table_sql {
  my ($dbh, $name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT sql FROM sqlite_master WHERE name = ?}, undef, $name,
  );
}

sub apply_diff {
  my ($dbh, $diff) = @_;
  $dbh->do($_->as_sql) for @{ $diff->operations };
}

# One part dying must not hide what the others have to say: a table that was
# never created kills the next statement that names it.
sub section {
  my ($name, $code) = @_;
  eval { $code->(); 1 } or fail("$name: died -- $@");
}

# ---------------------------------------------------------------------------
# 1. The live path: Deploy->upgrade for a schema that gained a result class
# ---------------------------------------------------------------------------

{
  package CT::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package CT::V1::Result::Owner;
  use base 'DBIO::Core';
  __PACKAGE__->table('owner');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package CT::V2::Result::Owner;
  use base 'DBIO::Core';
  __PACKAGE__->table('owner');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::V2::Result::Item;         # the class the upgrade has to add
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    code     => { data_type => 'varchar', size => 10, is_nullable => 0 },
    owner_id => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(item_code => ['code']);
  __PACKAGE__->belongs_to(owner => 'CT::V2::Result::Owner', 'owner_id');
}
CT::V1->register_class(Owner => 'CT::V1::Result::Owner');
CT::V2->register_class(Owner => 'CT::V2::Result::Owner');
CT::V2->register_class(Item  => 'CT::V2::Result::Item');

section "upgrade adds a result class" => sub {
  my $v1 = CT::V1->connect('dbi:SQLite::memory:');
  $v1->storage->dbh->do('PRAGMA foreign_keys = ON');
  DBIO::SQLite::Deploy->new(schema => $v1)->install;

  my $v2     = CT::V2->connect(sub { $v1->storage->dbh });
  my $deploy = DBIO::SQLite::Deploy->new(schema => $v2);

  my $diff;
  lives_ok { $diff = $deploy->upgrade } 'upgrade that adds a table applies';
  ok($diff && $diff->has_changes, 'the upgrade had the new table to add');

  # The claim in one line: what the upgrade created is what an install creates.
  my $fresh = CT::V2->connect('dbi:SQLite::memory:');
  DBIO::SQLite::Deploy->new(schema => $fresh)->install;
  is(
    table_sql($v1->storage->dbh, 'item'),
    table_sql($fresh->storage->dbh, 'item'),
    'the added table has the definition a fresh install gives it',
  );

  my $owner = $v2->resultset('Owner')->create({ name => 'Ada' });

  # INTEGER PRIMARY KEY has to arrive as the rowid alias, or there is no id.
  my ($first, $second);
  lives_ok {
    $first  = $v2->resultset('Item')->create({ code => 'a', owner_id => $owner->id });
    $second = $v2->resultset('Item')->create({ code => 'b', owner_id => $owner->id });
  } 'create without id works on the added table';
  ok($first && $first->id, 'the database assigned an id');
  isnt($first && $first->id, $second && $second->id, 'and a different one to the next row');

  throws_ok {
    $v2->resultset('Item')->create({ code => 'a', owner_id => $owner->id });
  } qr/UNIQUE constraint failed: item\.code/,
    'the unique constraint of the added table is enforced';

  throws_ok {
    $v2->resultset('Item')->create({ code => 'c', owner_id => $owner->id + 1000 });
  } qr/FOREIGN KEY constraint failed/,
    'the foreign key of the added table is enforced';

  ok(!$deploy->diff->has_changes, 'nothing left to do after the upgrade');
};

# ---------------------------------------------------------------------------
# 2. The card's table: ON DELETE CASCADE and an expression default
# ---------------------------------------------------------------------------
#
# The card's DDL is handed to the deploy as written, through its documented
# hook, _install_ddl. (DBIO::SQLite::DDL could not render ON DELETE when this
# was written; it does since karr k66, see t/49-ddl-fk-actions.t.) From there
# on it is the ordinary upgrade: deploy into a throwaway database, introspect,
# diff, apply.

my $CARD_A = 'CREATE TABLE a (id INTEGER PRIMARY KEY)';
my $CARD_T = 'CREATE TABLE t (id INTEGER PRIMARY KEY, code VARCHAR(10) NOT NULL, '
  . 'name TEXT DEFAULT (lower(hex(randomblob(4)))), '
  . 'a_id INTEGER REFERENCES a(id) ON DELETE CASCADE, UNIQUE (code))';

{
  package CT::Card::Deploy;
  use base 'DBIO::SQLite::Deploy';
  sub _install_ddl { "$CARD_A;\n$CARD_T;" }

  package CT::Card;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

  package CT::Card::Result::A;
  use base 'DBIO::Core';
  __PACKAGE__->table('a');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');

  package CT::Card::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    code => { data_type => 'varchar', size => 10, is_nullable => 0 },
    name => { data_type => 'text', is_nullable => 1 },
    a_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
CT::Card->register_class(A => 'CT::Card::Result::A');
CT::Card->register_class(T => 'CT::Card::Result::T');

section "upgrade adds the table of karr k56" => sub {
  my $schema = CT::Card->connect('dbi:SQLite::memory:');
  my $dbh    = $schema->storage->dbh;
  $dbh->do('PRAGMA foreign_keys = ON');
  $dbh->do($CARD_A);

  my $deploy = CT::Card::Deploy->new(schema => $schema);

  like($deploy->diff->as_sql, qr/\Q$CARD_T\E;/,
    'the diff carries the original CREATE TABLE of the new table');

  lives_ok { $deploy->upgrade }
    'upgrade adding a table with an expression default applies';
  is(table_sql($dbh, 't'), $CARD_T,
    'the table is stored with the statement it was declared with');

  my $parent = $schema->resultset('A')->create({});
  my $row;
  lives_ok {
    $row = $schema->resultset('T')->create({ code => 'x', a_id => $parent->id });
  } 'create without id works';
  ok($row && $row->id, 'the database assigned an id');

  like(
    scalar $dbh->selectrow_array('SELECT name FROM t WHERE code = ?', undef, 'x'),
    qr/\A[0-9a-f]{8}\z/,
    'the expression default is evaluated for a row that leaves the column out',
  );

  throws_ok {
    $schema->resultset('T')->create({ code => 'x', a_id => $parent->id });
  } qr/UNIQUE constraint failed: t\.code/, 'UNIQUE (code) is enforced';

  $parent->delete;
  is($schema->resultset('T')->count, 0,
    'ON DELETE CASCADE removed the child row with its parent');

  ok(!$deploy->diff->has_changes, 'nothing left to do after the upgrade');
};

# ---------------------------------------------------------------------------
# 3. Introspect also lists views under tables
# ---------------------------------------------------------------------------
#
# DBIO::SQLite::Introspect::Tables reads type IN ('table', 'view'), so a view
# that is new in the target reaches the same create op. Rebuilt from its
# columns it came out as a TABLE of that name; with the stored statement it is
# the view.

section "view new in the target" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  $_->do('CREATE TABLE note (id INTEGER PRIMARY KEY, body TEXT)') for $source, $target;
  $target->do('CREATE VIEW note_bodies AS SELECT body FROM note');

  my $diff = DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
  is($diff->as_sql, 'CREATE VIEW note_bodies AS SELECT body FROM note;',
    'a view new in the target is created as a view');

  apply_diff($source, $diff);
  is(
    scalar $source->selectrow_array(
      q{SELECT type FROM sqlite_master WHERE name = 'note_bodies'}),
    'view',
    'and is one afterwards',
  );
};

# A virtual table is a row of type 'table' there, with a statement of its own.
# Its columns have no declared type; rebuilt from them it was an ordinary table
# that could not be searched.
section "virtual table new in the target" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();

  SKIP: {
    eval { $target->do('CREATE VIRTUAL TABLE docs USING fts5(body)'); 1 }
      or skip 'this libsqlite has no FTS5', 2;

    my $diff = DBIO::SQLite::Diff->new(
      source => introspect($source), target => introspect($target),
    );
    is($diff->as_sql, 'CREATE VIRTUAL TABLE docs USING fts5(body);',
      'a virtual table new in the target is created as one');

    apply_diff($source, $diff);
    $source->do(q{INSERT INTO docs (body) VALUES ('rowid alias')});
    is(
      scalar $source->selectrow_array(
        q{SELECT count(*) FROM docs WHERE docs MATCH 'alias'}),
      1,
      'and can be searched',
    );
  }
};

# ---------------------------------------------------------------------------
# 4. The way out: a model without the statement (target_from_compiled)
# ---------------------------------------------------------------------------
#
# A compiled model has no database behind it and so no sqlite_master.sql. The
# table is then rebuilt from the columns, which carry enough for the two things
# that broke the table outright: the primary key, and a default that is an
# expression.

{
  package CT::Compiled::Result::Event;  # INTEGER key, expression default
  use base 'DBIO::Core';
  __PACKAGE__->table('event');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    stamp => { data_type => 'text', default_value => \"(datetime('now'))" },
    day   => { data_type => 'text', default_value => \'CURRENT_DATE' },
    hits  => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Compiled::Result::Tag;    # single-column key that is no alias
  use base 'DBIO::Core';
  __PACKAGE__->table('tag');
  __PACKAGE__->add_columns(name => { data_type => 'text', is_nullable => 0 });
  __PACKAGE__->set_primary_key('name');

  package CT::Compiled::Result::Pair;   # two-column key, as before
  use base 'DBIO::Core';
  __PACKAGE__->table('pair');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer', is_nullable => 0 },
    b => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('a', 'b');

  package CT::Compiled;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Event => 'CT::Compiled::Result::Event');
  __PACKAGE__->register_class(Tag   => 'CT::Compiled::Result::Tag');
  __PACKAGE__->register_class(Pair  => 'CT::Compiled::Result::Pair');
}

section "tables rebuilt from a compiled model" => sub {
  my $schema = CT::Compiled->connect('dbi:SQLite::memory:');
  my $target = DBIO::SQLite::Diff->target_from_compiled(
    DBIO::Schema::ModelCompiler->new(adapter => DBIO::SQLite::Adapter->new)
      ->compile($schema)
  );
  ok(!(grep { defined $_->{sql} } values %{ $target->{tables} }),
    'a compiled target carries no CREATE statement -- this is the fallback');

  my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my $diff  = DBIO::SQLite::Diff->new(source => $empty, target => $target);

  my $dbh = memory_dbh();
  lives_ok { apply_diff($dbh, $diff) }
    'the tables rebuilt from a compiled model are valid SQL'
    or diag $diff->as_sql;

  # single-column INTEGER key: the rowid alias
  lives_ok {
    $dbh->do('INSERT INTO event DEFAULT VALUES') for 1 .. 2;
  } 'rows can be inserted without an id';
  is_deeply(
    $dbh->selectcol_arrayref('SELECT id FROM event ORDER BY id'), [ 1, 2 ],
    'the single-column INTEGER key assigns ids',
  );
  ok(pk_is_rowid_alias($dbh, 'event'), 'because it is the rowid alias');

  # expression default: parenthesised, and evaluated
  my ($stamp, $day, $hits) =
    $dbh->selectrow_array('SELECT stamp, day, hits FROM event WHERE id = 1');
  like($stamp, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/,
    'a default that is an expression is evaluated');
  like($day, qr/\A\d{4}-\d\d-\d\d\z/, 'a keyword default still is');
  is($hits, 0, 'a literal default still is');

  # single-column key of another type: a key all the same
  $dbh->do(q{INSERT INTO tag (name) VALUES ('perl')});
  throws_ok { $dbh->do(q{INSERT INTO tag (name) VALUES ('perl')}) }
    qr/UNIQUE constraint failed: tag\.name/,
    'a single-column key of another type is a key';

  # the two-column key is what it was
  $dbh->do('INSERT INTO pair (a, b) VALUES (1, 1)');
  $dbh->do('INSERT INTO pair (a, b) VALUES (1, 2)');
  throws_ok { $dbh->do('INSERT INTO pair (a, b) VALUES (1, 1)') }
    qr/UNIQUE constraint failed: pair\.a, pair\.b/,
    'the two-column key is still a table constraint';

  # The compiled default and the introspected one have to be the same string,
  # or the table just created differs from the model it was created from. The
  # schema says \"(datetime('now'))"; PRAGMA table_xinfo says datetime('now').
  my $again = DBIO::SQLite::Diff->new(source => introspect($dbh), target => $target);
  ok(!$again->has_changes, 'the created tables do not differ from their model')
    or diag $again->summary;

  # ... and the same holds for the tables install_ddl creates from that schema.
  DBIO::SQLite::Deploy->new(schema => $schema)->install;
  my $installed = DBIO::SQLite::Diff->new(
    source => introspect($schema->storage->dbh), target => $target,
  );
  ok(!$installed->has_changes, 'nor do the installed ones')
    or diag $installed->summary;
};

# ---------------------------------------------------------------------------
# 4a. A compiled default that is a plain string (karr k68, karr k57)
# ---------------------------------------------------------------------------
#
# default_value => 'hello world' is a value, not SQL. install_ddl writes it as
# the literal 'hello world', and PRAGMA table_xinfo reports it with the
# apostrophes. target_from_compiled passed the bare value on, which is neither
# what the introspector reports nor something that can follow DEFAULT:
#
#   hello world   ->  DEFAULT (hello world)   syntax error
#   it's          ->  DEFAULT (it's)          syntax error
#   abc           ->  DEFAULT abc             runs (SQLite reads the identifier
#                                             as a string), but differs from the
#                                             installed column: 'abc' ne abc
#
# The two schemas are apart on purpose. An apostrophe also broke install_ddl
# itself (karr k57), so in one schema that failure would have hidden what the
# other defaults had to say about the compiled model alone.

{
  package CT::Lit::Result::Spaced;
  use base 'DBIO::Core';
  __PACKAGE__->table('spaced');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => 'hello world' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Lit::Result::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => 'abc' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Lit::Result::Counted;     # a number stays a number
  use base 'DBIO::Core';
  __PACKAGE__->table('counted');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'integer', is_nullable => 0, default_value => 5 },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Lit;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Spaced  => 'CT::Lit::Result::Spaced');
  __PACKAGE__->register_class(Plain   => 'CT::Lit::Result::Plain');
  __PACKAGE__->register_class(Counted => 'CT::Lit::Result::Counted');

  package CT::Apos::Result::One;
  use base 'DBIO::Core';
  __PACKAGE__->table('one');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => q{it's} },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Apos::Result::Two;
  use base 'DBIO::Core';
  __PACKAGE__->table('two');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => q{rock 'n' roll} },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Apos;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(One => 'CT::Apos::Result::One');
  __PACKAGE__->register_class(Two => 'CT::Apos::Result::Two');

  # A string that looks like a number, in a column that holds strings. The
  # scalar does not say which of the two it is; the column's TEXT affinity
  # does, and both sides have to ask it -- install_ddl of the type it writes,
  # the compiled model of its native_type.
  package CT::Num::Result::Padded;
  use base 'DBIO::Core';
  __PACKAGE__->table('padded');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => '007' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Num::Result::Ten;
  use base 'DBIO::Core';
  __PACKAGE__->table('ten');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => '10' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Num::Result::Rate;
  use base 'DBIO::Core';
  __PACKAGE__->table('rate');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'text', is_nullable => 0, default_value => '1.50' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Num::Result::Code;
  use base 'DBIO::Core';
  __PACKAGE__->table('code');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    word => { data_type => 'char', size => 3, is_nullable => 0, default_value => '007' },
  );
  __PACKAGE__->set_primary_key('id');

  package CT::Num;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Padded => 'CT::Num::Result::Padded');
  __PACKAGE__->register_class(Ten    => 'CT::Num::Result::Ten');
  __PACKAGE__->register_class(Rate   => 'CT::Num::Result::Rate');
  __PACKAGE__->register_class(Code   => 'CT::Num::Result::Code');
}

sub compiled_target {
  my ($schema) = @_;
  return DBIO::SQLite::Diff->target_from_compiled(
    DBIO::Schema::ModelCompiler->new(adapter => DBIO::SQLite::Adapter->new)
      ->compile($schema)
  );
}

for my $case (
  [ 'CT::Lit',  { spaced => 'hello world', plain => 'abc', counted => 5 } ],
  [ 'CT::Apos', { one => q{it's}, two => q{rock 'n' roll} } ],
  [ 'CT::Num',  { padded => '007', ten => '10', rate => '1.50', code => '007' } ],
) {
  my ($class, $declared) = @$case;

  # (a) the table rebuilt from the compiled model runs, and its default is the
  # declared value. One statement at a time, so that each table answers for
  # itself.
  section "$class: string defaults of a compiled model" => sub {
    my $target = compiled_target($class->connect('dbi:SQLite::memory:'));
    my $empty  = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
    my $diff   = DBIO::SQLite::Diff->new(source => $empty, target => $target);

    my $dbh = memory_dbh();
    my %op  = map { $_->table_name => $_ } @{ $diff->operations };
    for my $table (sort keys %$declared) {
      my $sql = $op{$table}->as_sql;
      lives_ok { $dbh->do($sql) }
        "the table with the default <$declared->{$table}> is valid SQL"
        or do { diag $sql; next };

      $dbh->do(qq{INSERT INTO "$table" DEFAULT VALUES});
      is(
        scalar $dbh->selectrow_array(qq{SELECT word FROM "$table"}),
        $declared->{$table},
        "and a row that leaves the column out gets <$declared->{$table}>",
      );
    }

    # What was just created is what the model says.
    my $again = DBIO::SQLite::Diff->new(source => introspect($dbh), target => $target);
    is_deeply([ map { $_->summary } @{ $again->operations } ], [],
      'the created tables do not differ from their model');
  };

  # (b) no phantom diff: the compiled model holds the default the way the
  # introspector reports it after install_ddl has written it.
  section "$class: compiled model against the installed tables" => sub {
    my $schema = $class->connect('dbi:SQLite::memory:');
    DBIO::SQLite::Deploy->new(schema => $schema)->install;

    my $installed = introspect($schema->storage->dbh);
    my $target    = compiled_target($schema);

    for my $table (sort keys %$declared) {
      my ($live) = grep { $_->{column_name} eq 'word' } @{ $installed->{columns}{$table} };
      my ($want) = grep { $_->{column_name} eq 'word' } @{ $target->{columns}{$table} };
      is($want->{default_value}, $live->{default_value},
        "the compiled default <$declared->{$table}> is spelled as the installed one reads");
    }

    my $diff = DBIO::SQLite::Diff->new(source => $installed, target => $target);
    is_deeply([ map { $_->summary } @{ $diff->operations } ], [],
      'the installed tables do not differ from the compiled model');
  };
}

# ---------------------------------------------------------------------------
# 4b. A compiled key of several columns keeps its declared order (karr k68)
# ---------------------------------------------------------------------------
#
# set_primary_key('a', 'b') on a table whose columns are declared b, a is the
# key (a, b): that is the order of its index, and so of every lookup by a
# leading part of it. install_ddl writes PRIMARY KEY (a, b). target_from_compiled
# dropped the order (pk_position 0 on every column), and the table rebuilt from
# the columns got PRIMARY KEY (b, a).
#
# The second table has three key columns, declared in an order that is neither
# the column order nor its reverse.

{
  package CT::Key::Result::Pair;
  use base 'DBIO::Core';
  __PACKAGE__->table('pair');
  __PACKAGE__->add_columns(
    b    => { data_type => 'integer', is_nullable => 0 },
    a    => { data_type => 'integer', is_nullable => 0 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('a', 'b');

  package CT::Key::Result::Triple;
  use base 'DBIO::Core';
  __PACKAGE__->table('triple');
  __PACKAGE__->add_columns(
    c    => { data_type => 'integer', is_nullable => 0 },
    note => { data_type => 'text', is_nullable => 1 },
    b    => { data_type => 'integer', is_nullable => 0 },
    a    => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('b', 'a', 'c');

  package CT::Key;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Pair   => 'CT::Key::Result::Pair');
  __PACKAGE__->register_class(Triple => 'CT::Key::Result::Triple');
}

# Position within the key by column, as PRAGMA table_info reports it (pk: 1-based,
# 0 for a column outside the key).
sub pk_positions {
  my ($dbh, $table) = @_;
  return { map { $_->{name} => $_->{pk} }
    @{ $dbh->selectall_arrayref(qq{PRAGMA table_info("$table")}, { Slice => {} }) } };
}

# The columns of the key's own index, in index order.
sub pk_index_columns {
  my ($dbh, $table) = @_;
  my ($pk) = grep { $_->{origin} eq 'pk' }
    @{ $dbh->selectall_arrayref(qq{PRAGMA index_list("$table")}, { Slice => {} }) };
  return [] unless $pk;
  return [ map { $_->{name} } grep { $_->{key} }
    @{ $dbh->selectall_arrayref(qq{PRAGMA index_xinfo("$pk->{name}")}, { Slice => {} }) } ];
}

section "key order of a compiled model" => sub {
  my $schema = CT::Key->connect('dbi:SQLite::memory:');
  my $target = compiled_target($schema);

  # the model: the introspector's convention, position within the key
  is_deeply(
    { map { $_->{column_name} => $_->{pk_position} } @{ $target->{columns}{pair} } },
    { a => 1, b => 2, note => 0 },
    'the compiled model carries the declared key order as pk_position',
  );

  my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my $dbh   = memory_dbh();
  apply_diff($dbh, DBIO::SQLite::Diff->new(source => $empty, target => $target));

  DBIO::SQLite::Deploy->new(schema => $schema)->install;
  my $installed = $schema->storage->dbh;

  for my $case (
    [ pair   => { a => 1, b => 2, note => 0 },         [qw(a b)]   ],
    [ triple => { b => 1, a => 2, c => 3, note => 0 }, [qw(b a c)] ],
  ) {
    my ($table, $positions, $index) = @$case;

    is_deeply(pk_positions($dbh, $table), $positions,
      "$table: the key created from the compiled model is in declared order");
    is_deeply(pk_index_columns($dbh, $table), $index,
      "$table: and so is its index");
    is_deeply(pk_positions($dbh, $table), pk_positions($installed, $table),
      "$table: which is the key install_ddl creates");
  }

  # ... and reading the created table back gives the model its positions.
  is_deeply(
    { map { $_->{column_name} => $_->{pk_position} } @{ introspect($dbh)->{columns}{triple} } },
    { map { $_->{column_name} => $_->{pk_position} } @{ $target->{columns}{triple} } },
    'the introspected positions are the compiled ones',
  );
};

# ---------------------------------------------------------------------------
# 5. ADD COLUMN with a literal default
# ---------------------------------------------------------------------------
#
# This section used to add `stamp TEXT DEFAULT (datetime('now'))` too and assert
# the ADD COLUMN text with the parentheses. That claim is gone for a target that
# has a CREATE TABLE statement (karr k65): SQLite refuses a non-constant default
# in ADD COLUMN for a table that holds rows, and a diff cannot know whether the
# table does, so such a column rebuilds the table instead
# (t/48-diff-add-column.t, section 6). The parenthesised rendering of an
# ADD COLUMN lives on for a model without a statement, where nothing can be
# rebuilt (t/48, "no statement in the model").

section "ADD COLUMN" => sub {
  my $source = memory_dbh();
  my $target = memory_dbh();
  $source->do('CREATE TABLE log (id INTEGER PRIMARY KEY)');
  $target->do(q{CREATE TABLE log (id INTEGER PRIMARY KEY,
    level TEXT NOT NULL DEFAULT 'info',
    hits  INTEGER DEFAULT 0)});

  my $diff = DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
  my %sql = map { $_->column_name => $_->as_sql } @{ $diff->operations };

  is($sql{level}, q{ALTER TABLE "log" ADD COLUMN "level" TEXT NOT NULL DEFAULT 'info';},
    'a string literal stays as it is');
  is($sql{hits}, q{ALTER TABLE "log" ADD COLUMN "hits" INTEGER DEFAULT 0;},
    'a number stays as it is');

  lives_ok { apply_diff($source, $diff) } 'the ADD COLUMN statements apply';

  $source->do('INSERT INTO log DEFAULT VALUES');
  my ($level, $hits) =
    $source->selectrow_array('SELECT level, hits FROM log');
  is($level, 'info', 'the added string default is used');
  is($hits,  0,      'the added numeric default is used');

  my $again = DBIO::SQLite::Diff->new(
    source => introspect($source), target => introspect($target),
  );
  ok(!$again->has_changes, 'nothing left to add') or diag $again->summary;
};

# ---------------------------------------------------------------------------
# 6. default_value_sql: when the parentheses go on
# ---------------------------------------------------------------------------
#
# PRAGMA table_xinfo reports a default as SQL text and drops the parentheses
# of DEFAULT (expr). What it leaves cannot simply be wrapped again: a literal
# may stand either way, an expression must be wrapped, and an identifier --
# DEFAULT abc, which SQLite reads as the string 'abc' -- must NOT be, because
# (abc) is a column reference and "not constant".
#
# Each form is declared, read back, rendered and declared again; the second
# table has to exist and report the default the first one did.

for my $case (
  # declared as                        default_value_sql of what is read back
  [ q{'abc'},                          q{'abc'}                       ],
  [ q{'it''s'},                        q{'it''s'}                     ],
  [ q{42},                             q{42}                          ],
  [ q{-1},                             q{-1}                          ],
  [ q{1.5e3},                          q{1.5e3}                       ],
  [ q{0x10},                           q{0x10}                        ],
  [ q{x'00ff'},                        q{x'00ff'}                     ],
  [ q{NULL},                           q{NULL}                        ],
  [ q{TRUE},                           q{TRUE}                        ],
  [ q{CURRENT_TIMESTAMP},              q{CURRENT_TIMESTAMP}           ],
  [ q{abc},                            q{abc}                         ],
  [ q{a$b},                            q{a$b}                         ],
  [ q{"abc"},                          q{"abc"}                       ],
  [ q{[abc]},                          q{[abc]}                       ],
  [ q{`abc`},                          q{`abc`}                       ],
  [ q{(datetime('now'))},              q{(datetime('now'))}           ],
  [ q{( lower(hex(randomblob(4))) )},  q{(lower(hex(randomblob(4))))} ],
  [ q{(1+2)},                          q{(1+2)}                       ],
  [ q{((1)+(2))},                      q{((1)+(2))}                   ],
  [ q{('a' || 'b')},                   q{('a' || 'b')}                ],
  [ q{(-(1))},                         q{(-(1))}                      ],
  [ q{(5)},                            q{5}                           ],
  [ qq{(1 -- one\n)},                  qq{(1 -- one\n)}               ],
) {
  my ($declared, $expected) = @$case;
  (my $label = $declared) =~ s/\n/\\n/g;

  section "DEFAULT $label" => sub {
    my $dbh = memory_dbh();
    $dbh->do("CREATE TABLE first (c DEFAULT $declared)");
    my $reported = $dbh->selectall_arrayref(
      'PRAGMA table_xinfo("first")', { Slice => {} })->[0]{dflt_value};

    my $rendered = default_value_sql($reported);
    is($rendered, $expected, "DEFAULT $label is rendered as expected");

    lives_ok { $dbh->do("CREATE TABLE second (c DEFAULT $rendered)") }
      "DEFAULT $label can be declared again from what was read back";
    is(
      $dbh->selectall_arrayref(
        'PRAGMA table_xinfo("second")', { Slice => {} })->[0]{dflt_value},
      $reported,
      "DEFAULT $label reads back the same the second time",
    );
  };
}

done_testing;
