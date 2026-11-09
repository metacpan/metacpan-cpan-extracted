use strict; use warnings;
use Test::More;
use DBI;
use DBIO::Schema::ModelCompiler ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Diff ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k32 -- a table must diff to NOTHING against the schema it was deployed
# from, for every shape a SQLite primary key comes in.
#
# It did not. DBIO::SQLite::Diff::target_from_compiled zeroed not_null on every
# primary-key column, unconditionally, under the comment "SQLite reports PK
# columns as notnull=0". That is true of two key shapes and false of two others:
#
#   PRAGMA table_info reports notnull=1 for a key column DECLARED NOT NULL, and
#   for the key of a WITHOUT ROWID table (SQLite declares that one itself).
#
# So a result class with is_nullable => 0 on a non-INTEGER key deployed a NOT
# NULL column, read it back as notnull=1, compared it against a target claiming
# 0, and reported an alter of a column nobody had touched.
#
# The other half of the same question was settled by karr k29: the ROWID ALIAS
# -- INTEGER PRIMARY KEY on a rowid table -- cannot hold NULL whatever it was
# declared as, because NULL there is the "assign a rowid" input token rather
# than a stored value. That is a fact only the database can answer (PRAGMA
# index_list: every primary key materialises an origin='pk' index except the
# alias), and DBIO::SQLite::Util::pk_is_rowid_alias is where k29 put it. It is
# now applied where the database is -- in the introspected model -- instead of
# being guessed at on the target side, which has no database to ask.
#
# Every case below deploys or creates a real table and diffs it against its own
# schema. This uses SQLite for real, which is what SQLite is: a library.

my $ADAPTER = DBIO::SQLite::Adapter->new;

sub compiled_target {
  my ($schema) = @_;
  return DBIO::SQLite::Diff->target_from_compiled(
    DBIO::Schema::ModelCompiler->new(adapter => $ADAPTER)->compile($schema)
  );
}

# Deploy $schema's own DDL into its own (in-memory) database.
sub deploy {
  my ($schema) = @_;
  my $ddl = DBIO::SQLite::DDL->install_ddl($schema);
  $schema->storage->dbh_do(sub {
    my (undef, $dbh) = @_;
    for my $stmt (split /;\s*\n/, $ddl) {
      next unless $stmt =~ /\S/;
      $dbh->do($stmt);
    }
  });
  return $ddl;
}

sub diff_of {
  my ($schema) = @_;
  return DBIO::SQLite::Diff->new(
    source => DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh)->model,
    target => compiled_target($schema),
  );
}

sub columns_of {
  my ($schema, $table) = @_;
  my $cols = DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh)
    ->model->{columns}{$table};
  return { map { $_->{column_name} => $_ } @$cols };
}

# ---------------------------------------------------------------------------
# 1. the shapes DBIO::SQLite::DDL itself emits
# ---------------------------------------------------------------------------

{
  package PK::Result::Alias;          # INTEGER PRIMARY KEY -- the rowid alias
  use base 'DBIO::Core';
  __PACKAGE__->table('alias_pk');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package PK::Result::Text;           # TEXT key on a rowid table
  use base 'DBIO::Core';
  __PACKAGE__->table('text_pk');
  __PACKAGE__->add_columns(
    name => { data_type => 'text', is_nullable => 0 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('name');

  package PK::Result::Composite;      # two-column key
  use base 'DBIO::Core';
  __PACKAGE__->table('composite_pk');
  __PACKAGE__->add_columns(
    part  => { data_type => 'integer', is_nullable => 0 },
    label => { data_type => 'text', is_nullable => 0 },
    note  => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('part', 'label');

  package PK::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Alias     => 'PK::Result::Alias');
  __PACKAGE__->register_class(Text      => 'PK::Result::Text');
  __PACKAGE__->register_class(Composite => 'PK::Result::Composite');
}

my $schema = PK::Schema->connect('dbi:SQLite:dbname=:memory:');
my $ddl    = deploy($schema);

# The DDL is asserted, not assumed: the whole point of the round trip is that
# the target predicts what THIS text produces once SQLite has read it.
like $ddl, qr/\Q"id" INTEGER PRIMARY KEY\E/,
  'the auto-increment INTEGER key deploys as the bare rowid alias -- no NOT '
. 'NULL clause, which is why PRAGMA table_info reports notnull=0 for it';
like $ddl, qr/\Q"name" TEXT NOT NULL\E/,
  '... while a key column declared is_nullable => 0 deploys WITH NOT NULL, '
. 'which is what the target used to claim could not happen';

{
  my $diff = diff_of($schema);
  ok !$diff->has_changes,
    'a freshly deployed schema diffs to nothing -- rowid alias, TEXT key and '
  . 'composite key alike. Before karr k32 the TEXT and composite keys each '
  . 'reported an alter of a column that had just been created from this very '
  . 'target'
    or diag $diff->summary;
}

# The model behind that answer, so a green diff cannot come from both sides
# being wrong in the same way.
{
  my $alias = columns_of($schema, 'alias_pk');
  is $alias->{id}{not_null}, 1,
    'the rowid alias reads as NOT NULL although PRAGMA table_info says '
  . 'notnull=0: it cannot hold NULL, since NULL there is the "assign a rowid" '
  . 'token (karr k29). The model states the truth, not the declaration';
  is $alias->{note}{not_null}, 0,
    '... and an ordinary nullable column is untouched by that';

  my $text = columns_of($schema, 'text_pk');
  is $text->{name}{not_null}, 1,
    'the TEXT key reads as NOT NULL because it was declared NOT NULL -- the '
  . 'PRAGMA answer, passed through';

  my $comp = columns_of($schema, 'composite_pk');
  is_deeply
    [ map { $comp->{$_}{not_null} } qw/part label note/ ],
    [ 1, 1, 0 ],
    '... and both columns of a composite key, which is never the alias';
}

# ---------------------------------------------------------------------------
# 2. the shapes DBIO::SQLite::DDL cannot emit, created by hand
# ---------------------------------------------------------------------------
#
# WITHOUT ROWID has no DBIO declaration, and nothing in this driver emits NOT
# NULL on an alias column. Both exist in the wild -- a hand-written schema, a
# legacy database, another tool's DDL -- and both are what the diff meets on
# the source side of an upgrade.

{
  package WR::Result::Code;
  use base 'DBIO::Core';
  __PACKAGE__->table('codes');
  __PACKAGE__->add_columns(
    code  => { data_type => 'text', is_nullable => 0 },
    label => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('code');

  package WR::Result::Legacy;
  use base 'DBIO::Core';
  __PACKAGE__->table('legacy');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package WR::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Code   => 'WR::Result::Code');
  __PACKAGE__->register_class(Legacy => 'WR::Result::Legacy');
}

my $hand = WR::Schema->connect('dbi:SQLite:dbname=:memory:');
$hand->storage->dbh_do(sub {
  my (undef, $dbh) = @_;
  $dbh->do('CREATE TABLE codes (code TEXT NOT NULL, label TEXT, '
         . 'PRIMARY KEY (code)) WITHOUT ROWID');
  $dbh->do('CREATE TABLE legacy (id INTEGER PRIMARY KEY NOT NULL, note TEXT)');
});

{
  my $cols = columns_of($hand, 'codes');
  is $cols->{code}{not_null}, 1,
    'a WITHOUT ROWID key reads as NOT NULL -- SQLite declares that one itself, '
  . 'and it is not the alias (it has an origin=pk index like every other key)';

  my $diff = diff_of($hand);
  ok !$diff->has_changes,
    'both hand-written shapes diff to nothing against the same schema: the '
  . 'WITHOUT ROWID key, and the alias spelled INTEGER PRIMARY KEY NOT NULL. '
  . 'The target used to answer 0 for each and demand an alter SQLite cannot '
  . 'even perform in place'
    or diag $diff->summary;
}

# ---------------------------------------------------------------------------
# 3. what it cost on the real upgrade path
# ---------------------------------------------------------------------------
#
# DBIO::SQLite::Deploy never calls target_from_compiled: it deploys the DDL into
# a throwaway in-memory database and introspects THAT, so both sides of its diff
# come from PRAGMA. The alias still made those two sides disagree, because the
# PRAGMA reports the declaration and the two spellings of one alias differ in
# it. And here a column alter does not stand on its own -- DBIO::SQLite::Diff
# escalates any alter on a table whose target carries its CREATE statement into
# a DBIO::SQLite::Diff::Rebuild, the 12-step create/copy/drop/rename. An
# unchanged schema rebuilt its tables on every upgrade.

{
  my $live = WR::Schema->connect('dbi:SQLite:dbname=:memory:');
  $live->storage->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->do('CREATE TABLE codes (code TEXT NOT NULL, label TEXT, '
           . 'PRIMARY KEY (code)) WITHOUT ROWID');
    $dbh->do('CREATE TABLE legacy (id INTEGER PRIMARY KEY NOT NULL, note TEXT)');
  });

  my $diff = DBIO::SQLite::Deploy->new(schema => $live)->diff;

  ok !$diff->has_changes,
    'upgrading a database whose alias column carries an explicit NOT NULL is a '
  . 'no-op. The schema deploys the same alias without the clause, so the two '
  . 'introspected models differed on notnull alone'
    or diag $diff->summary;

  is_deeply
    [ grep { $_->isa('DBIO::SQLite::Diff::Rebuild') } @{ $diff->operations } ],
    [],
    '... and specifically no table rebuild, which is what that one-column '
  . 'difference escalated to: every row copied through a new table, at every '
  . 'upgrade, for a schema nobody had changed';
}

done_testing;
