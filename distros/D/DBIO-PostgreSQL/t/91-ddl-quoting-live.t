use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified quote_literal);
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k110 / k115 / k117: the names and values the driver
# writes into DDL are the ones the server reads.
#
# WHY it exists: the offline halves (t/88, t/89, t/90) pin what is written;
# only a server says whether it is right. Three things are held here:
#
#  1. the rule itself -- every word the server would quote, we quote, and a
#     literal comes back as the value it was made from;
#  2. k115 / k117 -- a table with the columns "user" and "order", an
#     apostrophe in a default and in an enum value deploys, and the values
#     come back;
#  3. k110 -- Deploy->diff and ->apply run through with a Mixed-Case table,
#     its index, trigger and policy, creating and dropping, and a second diff
#     finds nothing left to do.
#
# Everything happens in databases of this file's own (karr k81).

sub connect_to {
  my (@login) = @_;
  return LiveServer->control_dbh(login => \@login, attrs => { PrintWarn => 0 });
}

# ---------------------------------------------------------------------------
# 1. The rule, against the server
# ---------------------------------------------------------------------------
{
  my $dbh = connect_to(PrivatePgDatabase->create('t91rule'));
  note 'server ' . $dbh->selectrow_array('SHOW server_version');

  my $keywords = $dbh->selectall_arrayref(
    'SELECT word, catcode FROM pg_catalog.pg_get_keywords() ORDER BY word');
  my @must_quote = map { $_->[0] } grep { $_->[1] ne 'U' } @$keywords;
  my @unreserved = map { $_->[0] } grep { $_->[1] eq 'U' } @$keywords;
  cmp_ok scalar @must_quote, '>', 100, 'the server names its key words (' . @must_quote . ' not unreserved)';

  my @bare = grep { quote_ident($_) ne qq{"$_"} } @must_quote;
  is_deeply \@bare, [],
    'every key word the server does not class as unreserved is quoted'
    or diag "written bare, but the server would quote: @bare";

  # The other direction is no error -- a word quoted without need names the
  # same object -- but on the server the list was taken from it is exact,
  # and a drift is worth seeing.
  my @extra = grep { quote_ident($_) ne $_ } @unreserved;
  note "quoted although unreserved on this server: @extra" if @extra;

  # quote_ident() of the server is the rule; ask it.
  my @names = (
    @must_quote, @unreserved,
    qw(users _x a1 Users MixedCase USER 1a x$y uuid-ossp), 'a b', 'a.b', 'a"b', '"', "\x{e9}t\x{e9}",
  );
  my $sth = $dbh->prepare('SELECT quote_ident(?)');
  my @differ;
  for my $name (@names) {
    $sth->execute($name);
    my ($server) = $sth->fetchrow_array;
    my $ours = quote_ident($name);
    next if $ours eq $server;
    next if $ours eq qq{"$name"} && grep { $_ eq $name } @extra;   # noted above
    push @differ, "$name: ours $ours, server $server";
  }
  $sth->finish;
  is_deeply \@differ, [], 'quote_ident agrees with the server\'s quote_ident() on ' . @names . ' names'
    or diag join "\n", @differ;

  # A literal is the value again once the server has read it.
  for my $value ('draft', "it's", "''", "o'b'c", '', 'a\\b', 'a"b', "line\nbreak") {
    my ($back) = $dbh->selectrow_array('SELECT ' . quote_literal($value) . '::text');
    is $back, $value, 'the literal ' . quote_literal($value) . ' is read back as its value';
  }

  # Each part of a qualified name for itself: a dot inside a name stays there.
  $dbh->do('CREATE SCHEMA ' . quote_ident('My.Schema'));
  $dbh->do('CREATE TABLE ' . quote_qualified('My.Schema', 'Mixed.Case') . ' (id integer)');
  is_deeply $dbh->selectrow_arrayref(
      q{SELECT n.nspname, c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relname LIKE 'Mixed%'}),
    [ 'My.Schema', 'Mixed.Case' ], 'quote_qualified names schema and table, each with its own dot';

  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 2. install: reserved words, apostrophes (k115, k117)
# ---------------------------------------------------------------------------
{
  package T91::Install;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('uuid-ossp');
}
{
  package T91::Install::Result::Entry;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    user  => { data_type => 'bigint', is_nullable => 0 },
    order => { data_type => 'text',   is_nullable => 1 },
    Title => { data_type => 'text',   is_nullable => 0, default_value => "it's" },
    mood  => { data_type => 'enum',   is_nullable => 1, extra => { list => [ 'ok', "don't" ] } },
  );
  __PACKAGE__->set_primary_key('user');
  __PACKAGE__->add_unique_constraint('Entry Order' => [ 'order', 'Title' ]);
  __PACKAGE__->pg_index('Idx Order' => { columns => ['order'], include => ['user'] });
  __PACKAGE__->pg_check_constraint('Positive User' => '"user" > 0');
  __PACKAGE__->pg_rls({
    enable   => 1,
    policies => {
      'Everyone'  => { for => 'SELECT', roles => ['PUBLIC'], using => 'true' },
      'Only Self' => { for => 'UPDATE', roles => ['current_user'], using => 'true' },
    },
  });
}
T91::Install->register_class(Entry => 'T91::Install::Result::Entry');

SKIP: {
  my @db = PrivatePgDatabase->create('t91inst');
  my $probe = connect_to(@db);
  my ($has_uuid) = $probe->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'uuid-ossp'});
  $probe->disconnect;
  skip 'uuid-ossp is not available on the server', 9 unless $has_uuid;

  my $schema = T91::Install->connect(@db, { PrintError => 0, PrintWarn => 0 });
  ok eval { $schema->pg_deploy->install; 1 },
    'a table "order" with the columns "user" and "order", an apostrophe default and enum value installs'
    or do { diag $@; skip 'the install failed', 8 };

  my $dbh = $schema->storage->dbh;
  is_deeply $dbh->selectcol_arrayref(
      q{SELECT a.attname FROM pg_attribute a WHERE a.attrelid = '"order"'::regclass AND a.attnum > 0 ORDER BY a.attnum}),
    [qw(user order Title mood)], '... its columns are called what the declaration calls them';
  is_deeply $dbh->selectcol_arrayref(q{SELECT extname FROM pg_extension WHERE extname = 'uuid-ossp'}),
    ['uuid-ossp'], '... the extension uuid-ossp is there';
  is_deeply $dbh->selectcol_arrayref(
      q{SELECT e.enumlabel FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'order_mood_enum' ORDER BY e.enumsortorder}),
    [ 'ok', "don't" ], '... the enum has the value with the apostrophe';
  is_deeply $dbh->selectall_arrayref(
      q{SELECT policyname, roles::text FROM pg_policies WHERE tablename = 'order' ORDER BY policyname}),
    [ [ 'Everyone', '{public}' ], [ 'Only Self', "{$user}" ] ],
    '... PUBLIC and current_user in a policy are the roles they stand for';

  my $rs  = $schema->resultset('Entry');
  my $row = $rs->create({ user => 1, order => 'first', mood => "don't" });
  $row->discard_changes;
  is $row->get_column('Title'), "it's",  'the default with the apostrophe comes back from the server';
  is $row->get_column('mood'),  "don't", '... and so does the enum value';
  is $rs->search({ order => 'first' })->count, 1, 'a query finds the row by the column "order"';
  ok !eval { $rs->create({ user => 0, order => 'zero' }); 1 },
    'the CHECK constraint on "user" is in force';

  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. Deploy->diff / ->apply with Mixed-Case names, both directions (k110)
# ---------------------------------------------------------------------------
#
# Two versions of one schema, as a migration has them: the first brings the
# Mixed-Case schema, type, function, table, index and trigger into an empty
# database, the second adds a column, row level security and a policy to the
# table that is now there. Then the database is given objects no version
# declares, and the diff takes them away again.
#
# The schema is called "App.Data": Mixed-Case, and with a dot of its own. The
# model files its table under the key "App.Data.MixedCase", which split at a
# dot names a table "Data.MixedCase" in a schema "App" -- so this runs through
# only while every statement is written from the names, not from the key.
{
  package T91::PgSchema::AppData;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum('Mood' => [ 'ok', "don't" ]);
  __PACKAGE__->pg_function('Touch' => q{
    CREATE OR REPLACE FUNCTION "App.Data"."Touch"() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      RETURN NEW;
    END;
    $$
  });
}
for my $version (qw(V1 V2)) {
  my $schema_class = "T91::$version";
  my $result_class = "T91::${version}::Result::Entry";
  {
    no strict 'refs';
    @{"${schema_class}::ISA"} = ('DBIO::Schema');
    @{"${result_class}::ISA"} = ('DBIO::Core');
  }
  $schema_class->load_components('PostgreSQL');
  $schema_class->pg_schemas('App.Data');
  $schema_class->pg_schema_class('App.Data' => 'T91::PgSchema::AppData');

  $result_class->load_components('PostgreSQL::Result');
  $result_class->pg_schema('App.Data');
  $result_class->table('MixedCase');
  $result_class->add_columns(
    user  => { data_type => 'bigint', is_nullable => 0 },
    Title => { data_type => 'text',   is_nullable => 0, default_value => "it's" },
    ( $version eq 'V2' ? ( order => { data_type => 'text', is_nullable => 1 } ) : () ),
  );
  $result_class->set_primary_key('user');
  $result_class->pg_index('Idx Title' => { columns => [ 'Title', 'user' ] });
  $result_class->pg_trigger('Trg Touch' => {
    when => 'BEFORE', event => 'UPDATE', execute => '"App.Data"."Touch"()',
  });
  $result_class->pg_rls({
    enable   => 1,
    policies => { 'Own Rows' => { for => 'SELECT', using => '"user" > 0' } },
  }) if $version eq 'V2';

  $schema_class->register_class(Entry => $result_class);
}

{
  my @db  = PrivatePgDatabase->create('t91diff');
  my $v1  = T91::V1->connect(@db, { PrintError => 0, PrintWarn => 0 });
  my $v2  = T91::V2->connect(@db, { PrintError => 0, PrintWarn => 0 });
  my $dbh = $v2->storage->dbh;

  my $objects = sub {
    return {
      tables => $dbh->selectcol_arrayref(
        q{SELECT c.relname FROM pg_class c WHERE c.relnamespace = '"App.Data"'::regnamespace AND c.relkind = 'r' ORDER BY 1}),
      columns => $dbh->selectcol_arrayref(
        q{SELECT a.attname FROM pg_attribute a WHERE a.attrelid = '"App.Data"."MixedCase"'::regclass AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum}),
      indexes => $dbh->selectcol_arrayref(
        q{SELECT indexname FROM pg_indexes WHERE schemaname = 'App.Data' ORDER BY 1}),
      triggers => $dbh->selectcol_arrayref(
        q{SELECT t.tgname FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid WHERE c.relnamespace = '"App.Data"'::regnamespace AND NOT t.tgisinternal ORDER BY 1}),
      policies => $dbh->selectcol_arrayref(
        q{SELECT policyname FROM pg_policies WHERE schemaname = 'App.Data' ORDER BY 1}),
      rls => $dbh->selectcol_arrayref(
        q{SELECT c.relname FROM pg_class c WHERE c.relnamespace = '"App.Data"'::regnamespace AND c.relrowsecurity ORDER BY 1}),
      types => $dbh->selectcol_arrayref(
        q{SELECT t.typname FROM pg_type t WHERE t.typnamespace = '"App.Data"'::regnamespace AND t.typtype = 'e' ORDER BY 1}),
      functions => $dbh->selectcol_arrayref(
        q{SELECT p.proname FROM pg_proc p WHERE p.pronamespace = '"App.Data"'::regnamespace ORDER BY 1}),
    };
  };
  my %v1 = (
    tables    => ['MixedCase'],
    columns   => [qw(user Title)],
    indexes   => [ 'Idx Title', 'MixedCase_pkey' ],
    triggers  => ['Trg Touch'],
    policies  => [],
    rls       => [],
    types     => ['Mood'],
    functions => ['Touch'],
  );
  my %v2 = ( %v1, columns => [qw(user Title order)], policies => ['Own Rows'], rls => ['MixedCase'] );

  my $statements = sub { [ sort grep { /\S/ } split /\n/, $_[0]->as_sql ] };

  # --- create: an empty database is brought up by the diff alone ------------
  my $deploy = $v1->pg_deploy;
  my $create = $deploy->diff;
  note $create->as_sql;
  for my $statement (
    'CREATE SCHEMA "App.Data";',
    q{CREATE TYPE "App.Data"."Mood" AS ENUM ('ok', 'don''t');},
    q{CREATE TABLE "App.Data"."MixedCase" ("user" bigint NOT NULL, "Title" text NOT NULL DEFAULT 'it''s'::text);},
  ) {
    ok index($create->as_sql, $statement) >= 0, "create: the diff says $statement";
  }
  ok eval { $deploy->apply($create); 1 },
    'create: apply brings up the Mixed-Case schema, type, function, table, index and trigger'
    or diag $@;
  is_deeply $objects->(), \%v1, '... and they are there under their exact names';
  is_deeply $statements->($deploy->diff), [], '... and a second diff finds nothing left to do';

  # --- create, on the table that is there now: column, RLS, policy -----------
  $deploy = $v2->pg_deploy;
  my $extend = $deploy->diff;
  note $extend->as_sql;
  is_deeply $statements->($extend), [ sort
    'ALTER TABLE "App.Data"."MixedCase" ADD COLUMN "order" text;',
    'ALTER TABLE "App.Data"."MixedCase" ENABLE ROW LEVEL SECURITY;',
    'CREATE POLICY "Own Rows" ON "App.Data"."MixedCase" FOR SELECT USING (("user" > 0));',
  ], 'extend: a column called "order", row level security and a policy for the Mixed-Case table';
  ok eval { $deploy->apply($extend); 1 }, 'extend: apply adds them' or diag $@;
  is_deeply $objects->(), \%v2, '... and they are there';
  is_deeply $statements->($deploy->diff), [], '... and a second diff finds nothing left to do';

  # The queries, which always quote, reach what the diff created. pg_schema
  # qualifies the DDL only, so the session is told where to look -- and told
  # to forget it again: what the server reports for a trigger or a default
  # depends on the search path, and the diffs below compare such reports.
  $dbh->do('SET search_path TO "App.Data", public');
  my $row = $v2->resultset('Entry')->create({ user => 7, order => 'x' });
  $row->discard_changes;
  is $row->get_column('Title'), "it's", 'a row goes in and the apostrophe default comes back';
  $dbh->do('RESET search_path');

  # --- drop: whatever the schema does not declare goes again -----------------
  $dbh->do($_) for (
    'ALTER TABLE "App.Data"."MixedCase" ADD COLUMN "Extra Col" text',
    'CREATE INDEX "Extra Idx" ON "App.Data"."MixedCase" ("order", "Title")',
    'CREATE TRIGGER "Extra Trg" BEFORE INSERT ON "App.Data"."MixedCase" FOR EACH ROW EXECUTE FUNCTION "App.Data"."Touch"()',
    'CREATE POLICY "Extra Pol" ON "App.Data"."MixedCase" FOR DELETE USING (false)',
    q{CREATE TYPE "App.Data"."Extra Mood" AS ENUM ('o''b')},
    q{CREATE FUNCTION "App.Data"."Extra Fn"(a integer, "B" text) RETURNS integer LANGUAGE sql AS $$ SELECT 1 $$},
    'CREATE TABLE "App.Data"."Left Over" ("user" integer PRIMARY KEY, "Order" text)',
    'CREATE INDEX "Left Idx" ON "App.Data"."Left Over" ("Order")',
  );

  my $drop = $deploy->diff;
  note $drop->as_sql;
  is_deeply $statements->($drop), [ sort
    'ALTER TABLE "App.Data"."MixedCase" DROP COLUMN "Extra Col";',
    'DROP FUNCTION "App.Data"."Extra Fn"(a integer, "B" text);',
    'DROP INDEX "App.Data"."Extra Idx";',
    'DROP POLICY "Extra Pol" ON "App.Data"."MixedCase";',
    'DROP TABLE "App.Data"."Left Over";',
    'DROP TRIGGER "Extra Trg" ON "App.Data"."MixedCase";',
    'DROP TYPE "App.Data"."Extra Mood";',
  ], 'drop: the diff names each undeclared object exactly -- and the index with its schema';
  ok eval { $deploy->apply($drop, allow_destructive => 1); 1 },
    'drop: apply removes them; "App.Data" is not on the search path of the deploying session'
    or diag $@;
  is_deeply $objects->(), \%v2, '... and what the schema declares is what is left';
  is_deeply $statements->($deploy->diff), [], '... and a second diff finds nothing left to do';

  $_->storage->disconnect for $v1, $v2;
}

# ---------------------------------------------------------------------------
# 4. install, then diff, in one process
# ---------------------------------------------------------------------------
# install_ddl used to change the schema it read -- the generated enum type
# name was written into the column info -- so the second call, the diff's
# temporary deploy, left out the CREATE TYPE the first one had made.
{
  package T91::Twice;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package T91::Twice::Result::Task;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('Task List');
  __PACKAGE__->add_columns(
    id     => { data_type => 'bigint', is_nullable => 0 },
    status => { data_type => 'enum',   is_nullable => 0, extra => { list => [qw(new done)] }, default_value => 'new' },
  );
  __PACKAGE__->set_primary_key('id');
}
T91::Twice->register_class(Task => 'T91::Twice::Result::Task');

{
  my $schema = T91::Twice->connect(PrivatePgDatabase->create('t91twice'), { PrintError => 0, PrintWarn => 0 });
  my $deploy = $schema->pg_deploy;
  ok eval { $deploy->install; 1 }, 'install: a table "Task List" with a generated enum type' or diag $@;
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff in the same process deploys the temporary database -- the enum type included' or diag $@;
  ok $diff && !$diff->has_changes, '... and finds the installed database as declared'
    or diag $diff ? $diff->as_sql : $@;
  $schema->storage->disconnect;
}

done_testing;
