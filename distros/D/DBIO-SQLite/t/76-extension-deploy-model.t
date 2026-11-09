use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Extension;
use DBIO::SQLite::Extension::FTS5;
use DBIO::SQLite::Extension::RTree;

# OFFLINE test (in-memory databases): what the SQLite deploy does with the
# answers of the extensions -- the probe of phase 0, claims with their
# cascade, the states -- and what they bring to the model (ADR 0066; karr k85).
#
# WHY: SQLite has no catalog of extensions, so the extension itself probes the
# database; and FTS5 and R*Tree keep shadow tables in the application's own
# schema, which a diff would otherwise try to drop one by one (karr k44) --
# a cascade SQLite already performs. A claim that takes a neighbour, a probe
# that mistakes a string for a module, or a state an extension can change
# would be a diff that drops or creates something it must not.
#
# What this file claims:
#   1. the probe finds the virtual tables of its module and no others, reads
#      the statement with the lexer (a string is not a module), and names the
#      shadow tables the module gives them;
#   2. [table] and [column] claims remove the object with the cascade the POD
#      documents, and nothing else; an absent object is passed over, claiming
#      twice is claiming once, an address of another kind is refused;
#   3. through Deploy::diff the claims run on both sides, the shadow tables
#      are not in the model of either, and the state is in the model, read-only;
#   4. WHAT THE CLAIMS BRING: with the classifier of the introspection
#      (PRAGMA table_list, karr k44) out of the way, the shadow tables are in
#      the model and the diff drops them one by one -- unless the extension is
#      declared. With the classifier in place both give the same diff, which
#      is the point of idempotence;
#   5. an annotation is refused (this deploy has no attribute to add), an
#      undeclared extension's rules do not run.

my $have_fts5  = eval { DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 })->do('CREATE VIRTUAL TABLE t USING fts5(a)'); 1 };
my $have_rtree = eval { DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 })->do('CREATE VIRTUAL TABLE t USING rtree(id, a, b)'); 1 };
plan skip_all => 'FTS5 and R*Tree are not compiled into this libsqlite' unless $have_fts5 && $have_rtree;

sub memory_db {
  return DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
}

# --- 1. the probe ----------------------------------------------------------------
{
  my $dbh = memory_db;
  $dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do('CREATE VIRTUAL TABLE docs USING fts5(title, body)');
  $dbh->do('CREATE VIRTUAL TABLE "my notes" USING FTS5(body)');
  $dbh->do('CREATE VIRTUAL TABLE geo USING rtree(id, minx, maxx, miny, maxy)');
  $dbh->do(q{CREATE TABLE decoy (id INTEGER PRIMARY KEY, note TEXT DEFAULT 'CREATE VIRTUAL TABLE x USING fts5(a)')});
  $dbh->do(q{CREATE VIEW decoy_view AS SELECT 'CREATE VIRTUAL TABLE y USING fts5(a)' AS s});
  $dbh->do('CREATE TABLE docs_decoy (id INTEGER PRIMARY KEY)');

  my $fts = DBIO::SQLite::Extension::FTS5->inspect({ dbh => $dbh });
  is $fts->{module}, 'fts5', 'the probe names its module';
  is $fts->{available}, 1, '... says the library has it';
  is_deeply $fts->{virtual_tables}, [ 'docs', 'my notes' ], 'the virtual tables of fts5, by name (a quoted name too)';
  is_deeply $fts->{shadow_tables}, [
    (map { "docs$_" }     qw( _config _content _data _docsize _idx )),
    (map { "my notes$_" } qw( _config _content _data _docsize _idx )),
  ], '... and the shadow tables the module gives them';
  ok !grep({ $_ eq 'decoy' || $_ eq 'decoy_view' || $_ eq 'geo' } @{ $fts->{virtual_tables} }),
    'a string in a default, a view and an rtree table are no fts5 table';

  my $rtree = DBIO::SQLite::Extension::RTree->inspect({ dbh => $dbh });
  is_deeply $rtree->{virtual_tables}, ['geo'], 'rtree: its own tables only';
  is_deeply $rtree->{shadow_tables}, [qw( geo_node geo_parent geo_rowid )], '... and its shadow tables';

  my $none = memory_db;
  is_deeply(DBIO::SQLite::Extension::FTS5->inspect({ dbh => $none }),
    { module => 'fts5', available => 1, virtual_tables => [], shadow_tables => [] },
    'a database without a virtual table: an empty state, not undef');
}

# --- 2. claims -----------------------------------------------------------------------
my $deploy = DBIO::SQLite::Deploy->new;

sub fixture {
  return {
    tables  => map_of(qw( docs docs_data docs_config artist )),
    columns => {
      artist       => [ { column_name => 'id' }, { column_name => 'name' } ],
      docs         => [ { column_name => 'title' } ],
      docs_data    => [ { column_name => 'id' }, { column_name => 'block' } ],
      docs_config  => [ { column_name => 'k' } ],
    },
    indexes      => { artist => { artist_name => {} }, docs_data => { docs_data_ix => {} } },
    foreign_keys => { artist => [ {} ], docs_data => [ {} ] },
    triggers     => { artist => { t => {} }, docs_data => { u => {} } },
  };
}
sub map_of { return { map { $_ => { table_name => $_ } } @_ } }
sub claimed { my ($model, @addresses) = @_; $deploy->_apply_extension_claims($model, \@addresses); return $model }
sub keys_of { [ sort keys %{ $_[0] } ] }

{
  my $m = claimed(fixture(), [ table => 'docs_data' ]);
  is_deeply keys_of($m->{tables}), [qw( artist docs docs_config )], 'a claimed table leaves the model';
  is_deeply keys_of($m->{columns}), [qw( artist docs docs_config )], '... with its columns';
  is_deeply keys_of($m->{indexes}), ['artist'], '... indexes';
  is_deeply keys_of($m->{foreign_keys}), ['artist'], '... foreign keys';
  is_deeply keys_of($m->{triggers}), ['artist'], '... triggers';
}
{
  my $m = claimed(fixture(), [ column => 'docs_data', 'block' ]);
  is_deeply [ map { $_->{column_name} } @{ $m->{columns}{docs_data} } ], ['id'], 'a claimed column leaves its table';
  is_deeply keys_of($m->{tables}), [qw( artist docs docs_config docs_data )], '... the table stays';
}
{
  my $m = claimed(fixture(), [ table => 'docs_data' ], [ table => 'docs_config' ]);
  my $n = claimed(fixture(), [ table => 'docs_config' ], [ table => 'docs_data' ]);
  is_deeply $m, $n, 'claims in any order give the same model';
  is_deeply claimed(claimed(fixture(), [ table => 'docs_data' ]), [ table => 'docs_data' ]),
    claimed(fixture(), [ table => 'docs_data' ]), 'claiming twice is claiming once';

  is_deeply claimed(fixture(), [ table => 'nowhere' ], [ column => 'nowhere', 'x' ], [ column => 'artist', 'nope' ]),
    fixture(), 'an address the model does not hold changes nothing';

  my $bare = { tables => {} };
  claimed($bare, [ table => 'x' ], [ column => 'x', 'y' ]);
  is_deeply $bare, { tables => {} }, '... and puts no section into a model that has none';

  throws_ok { claimed(fixture(), [ schema => 'main' ]) }
    qr/extension claim: the address \[schema, main\] is of a kind this deploy does not know \(table, column\)/,
    'an address of another kind is refused, naming it';
}

# --- 3. through Deploy::diff -----------------------------------------------------------
my $n = 0;
sub deploy_over {
  my ($dbh, @declaration) = @_;
  my $pkg = 'T76::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('SQLite');
  $pkg->sqlite_extensions(@declaration) if @declaration;
  eval "package ${pkg}::Result::Artist; use base q(DBIO::Core); 1" or die $@;
  "${pkg}::Result::Artist"->table('artist');
  "${pkg}::Result::Artist"->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  "${pkg}::Result::Artist"->set_primary_key('id');
  $pkg->register_class(Artist => "${pkg}::Result::Artist");
  return DBIO::SQLite::Deploy->new(schema => $pkg->connect(sub { $dbh }));
}

sub live_db {
  my $dbh = memory_db;
  $dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100))');
  $dbh->do('CREATE VIRTUAL TABLE docs USING fts5(title, body)');
  $dbh->do('CREATE VIRTUAL TABLE geo USING rtree(id, minx, maxx, miny, maxy)');
  return $dbh;
}

sub ops_of {
  my ($diff) = @_;
  return [ sort map { join ' ', $_->action, $_->table_name } @{ $diff->operations } ];
}

{
  my $diff = deploy_over(live_db(), 'fts5', 'rtree')->diff;
  is_deeply ops_of($diff), ['drop docs', 'drop geo'],
    'the diff drops the virtual tables the schema does not have, and nothing for their shadow tables';
  is_deeply keys_of($diff->source->{tables}), [qw( artist docs geo )], 'the live model: no shadow table';
  is_deeply keys_of($diff->target->{tables}), ['artist'], '... the target model: the schema\'s table';

  is_deeply $diff->source->{extensions}{fts5}{virtual_tables}, ['docs'], 'the state is in the model of the source';
  is_deeply $diff->source->{extensions}{rtree}{virtual_tables}, ['geo'], '... of each extension';
  is_deeply $diff->target->{extensions}{fts5}{virtual_tables}, ['docs'],
    '... and in the target (the state is the live database\'s, on both sides)';
  # core's default locks the hashes (lock_hashref_recurse); the arrays inside stay writable.
  throws_ok { $diff->source->{extensions}{fts5}{module} = 'x' } qr/read-only|Modification/i,
    'the state is read-only';
  throws_ok { $diff->source->{extensions}{new} = 1 } qr/disallowed|restricted/i, '... also against a new key';
}

# --- 4. what the claims bring ------------------------------------------------------------
{
  no warnings 'redefine';
  local *DBIO::SQLite::Introspect::Tables::_drop_shadow_tables = sub {};

  my $without = ops_of(deploy_over(live_db())->diff);
  is scalar(@$without), 2 + 5 + 3,
    'without the classifier and without the declaration: a drop for each of docs, geo and their eight shadow tables';
  ok((grep { $_ eq 'drop docs_data' } @$without) && (grep { $_ eq 'drop geo_node' } @$without),
    '... shadow tables among them (the chain that fails with "no such table", karr k44)');

  is_deeply ops_of(deploy_over(live_db(), 'fts5', 'rtree')->diff), ['drop docs', 'drop geo'],
    'declared, the claims keep every shadow table out of the diff, by the name of the module alone';
  is_deeply ops_of(deploy_over(live_db(), 'fts5')->diff),
    [ 'drop docs', 'drop geo', grep { /^drop geo_/ } @$without ],
    '... each extension for its own module: fts5 alone leaves the shadow tables of the rtree';
}
{
  is_deeply ops_of(deploy_over(live_db())->diff), ['drop docs', 'drop geo'],
    'with the classifier in place the declaration changes nothing: the claims find nothing left to take';
  is_deeply ops_of(deploy_over(live_db(), 'fts5', 'rtree')->diff), ['drop docs', 'drop geo'],
    '... the same diff, declared';
  is_deeply ops_of(deploy_over(live_db(), 'json1', 'fts5')->diff), ['drop docs', 'drop geo'],
    '... with a plain extension beside';
}

# --- 5. annotations, undeclared --------------------------------------------------------------
{
  package T76::Annotator;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'annotator' }
  sub driver { 'DBIO::SQLite' }
  sub annotate { [ [ [ table => 'artist' ], flavour => 'x' ] ] }
}
$INC{'T76/Annotator.pm'} = __FILE__;
throws_ok { deploy_over(live_db(), annotator => { class => 'T76::Annotator' })->diff }
  qr/cannot apply the extension annotations of 1 triple/,
  'an annotation is refused: this deploy has no attribute to add to an object';

{
  my $diff = deploy_over(live_db())->diff;
  ok !exists $diff->source->{extensions}, 'a schema that declares none gets no extensions section';
  is_deeply ops_of($diff), ['drop docs', 'drop geo'], '... and the diff as before';
}

done_testing;
