use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;

# OFFLINE test for karr k110 (with k117's literals on the diff side): the
# statements a diff emits name every object by the server's rule, from the
# object's own names -- not from the model's "schema.table" hash key.
#
# WHY it exists: the diff classes wrote the key as SQL text. A Mixed-Case
# table came out as DROP TABLE public.MixedCase, which PostgreSQL folds to
# mixedcase and does not find, so apply died on the first such object
# (downstream: AGE's label tables "Person", "KNOWS"). And a key is no name:
# split at its dot it is wrong as soon as a schema or a table has a dot of
# its own, which is why the names below do.

my $SCHEMA = 'My.Schema';
my $TABLE  = 'Mixed.Case';
my $KEY    = "$SCHEMA.$TABLE";              # what Introspect files it under
my $SQL    = '"My.Schema"."Mixed.Case"';    # what the server calls it

my %table = ( schema_name => $SCHEMA, table_name => $TABLE, kind => 'r' );
my %on    = ( schema_name => $SCHEMA, table_name => $TABLE );

sub ops_sql { [ map { split /\n/, $_->as_sql } @_ ] }

# --- Diff::Schema -----------------------------------------------------------

is_deeply ops_sql(DBIO::PostgreSQL::Diff::Schema->diff(
    { 'Old.One' => {}, user => {} }, { 'Auth' => {}, plain => {} })),
  [ 'CREATE SCHEMA "Auth";', 'CREATE SCHEMA plain;',
    'DROP SCHEMA "Old.One";', 'DROP SCHEMA "user";' ],
  'schema: Mixed-Case, dotted and reserved names quoted, a plain one bare';

# --- Diff::Table ------------------------------------------------------------

my @columns = (
  { column_name => 'user',  data_type => 'integer', not_null => 1 },
  { column_name => 'Order', data_type => 'text',    not_null => 0, default_value => q{'it''s'::text} },
  { column_name => 'plain', data_type => 'text',    not_null => 0 },
);

my ($create) = DBIO::PostgreSQL::Diff::Table->diff({}, { $KEY => {%table} }, {}, { $KEY => \@columns });
is $create->as_sql,
  qq{CREATE TABLE $SQL ("user" integer NOT NULL, "Order" text DEFAULT 'it''s'::text, plain text);},
  'table create: schema, table and column names quoted, a server-rendered default as given';
is $create->qualified_name, $KEY, '... while qualified_name stays the readable name';
is $create->summary, "  +table: $KEY", '... and so does the summary';

my ($drop) = DBIO::PostgreSQL::Diff::Table->diff({ $KEY => {%table} }, {});
is $drop->as_sql, "DROP TABLE $SQL;", 'table drop';

my ($k110) = DBIO::PostgreSQL::Diff::Table->diff(
  { 'public.MixedCase' => { schema_name => 'public', table_name => 'MixedCase' } }, {});
is $k110->as_sql, 'DROP TABLE public."MixedCase";',
  'k110 as reported: DROP TABLE public."MixedCase", not public.MixedCase';

# --- Diff::Column -----------------------------------------------------------

my @col_ops = DBIO::PostgreSQL::Diff::Column->diff(
  { $KEY => [
      { column_name => 'Old Col', data_type => 'text', not_null => 0 },
      { column_name => 'order',   data_type => 'integer', not_null => 0, default_value => '0' },
      { column_name => 'Rank',    data_type => 'integer', not_null => 0 },
      { column_name => 'Mood',    data_type => 'text',    not_null => 0 },
  ] },
  { $KEY => [
      { column_name => 'order', data_type => 'bigint', not_null => 1, default_value => '1' },
      { column_name => 'Rank',  data_type => 'integer', not_null => 0, identity => 'a' },
      { column_name => 'Mood',  data_type => 'enum', pg_enum_type => '"My.Schema"."Mood"', not_null => 0 },
      { column_name => 'user',  data_type => 'text', not_null => 1, default_value => q{'x'::text} },
  ] },
  { $KEY => {%table} }, { $KEY => {%table} },
);
is_deeply ops_sql(@col_ops), [
  qq{ALTER TABLE $SQL ADD COLUMN "user" text NOT NULL DEFAULT 'x'::text;},
  qq{ALTER TABLE $SQL DROP COLUMN "Old Col";},
  qq{ALTER TABLE $SQL ALTER COLUMN "Mood" TYPE "My.Schema"."Mood" USING "Mood"::text::"My.Schema"."Mood";},
  qq{ALTER TABLE $SQL ALTER COLUMN "Rank" ADD GENERATED ALWAYS AS IDENTITY;},
  qq{ALTER TABLE $SQL ALTER COLUMN "order" TYPE bigint;},
  qq{ALTER TABLE $SQL ALTER COLUMN "order" SET NOT NULL;},
  qq{ALTER TABLE $SQL ALTER COLUMN "order" SET DEFAULT 1;},
], 'column add / drop / alter: table and column quoted everywhere, the USING cast included';
is $col_ops[0]->table_key, $KEY, '... the op still carries the model key';
is_deeply [ $col_ops[0]->schema_name, $col_ops[0]->table_name ], [ $SCHEMA, $TABLE ],
  '... and now the names it stands for, each for itself';
like $col_ops[0]->summary, qr/\Q+column: $KEY.user\E/, '... the summary stays readable';

# --- Diff::Index ------------------------------------------------------------

my $server_def = qq{CREATE INDEX "Idx One" ON $SQL USING btree ("Order", plain)};
my @idx_ops = DBIO::PostgreSQL::Diff::Index->diff(
  { $KEY => { 'Old Idx' => { index_name => 'Old Idx', %on, columns => ['plain'] } } },
  { $KEY => {
      'Idx One' => { index_name => 'Idx One', %on, definition => $server_def, columns => [ 'Order', 'plain' ] },
  } },
  { $KEY => {%table} }, { $KEY => {%table} },
);
is_deeply ops_sql(@idx_ops), [
  "$server_def;",
  q{DROP INDEX "My.Schema"."Old Idx";},
], 'index: a definition from the server as given; the drop names the schema';

# An index without a definition is not the diff's to create (karr k120,
# t/100-diff-no-statement.t), and not written from its columns by hand either
# (karr k143): no name is quoted into a statement that does not exist.
eval { DBIO::PostgreSQL::Diff::Index->new(
    action => 'create', table_key => $KEY, %on, index_name => 'Idx Two',
    index_info => { index_name => 'Idx Two', %on, columns => [ 'user', 'plain' ] },
  )->as_sql };
like $@, qr/no definition/, 'index: without a definition there is no statement, whatever the columns';

# An index is found by schema and name. Unqualified, DROP INDEX only looks
# along the search path -- and an index in any other schema "does not exist".
my ($auth_drop) = DBIO::PostgreSQL::Diff::Index->diff(
  { 'auth.users' => { users_email_idx => { index_name => 'users_email_idx',
      schema_name => 'auth', table_name => 'users', columns => ['email'] } } },
  {},
);
is $auth_drop->as_sql, 'DROP INDEX auth.users_email_idx;',
  'index drop is schema-qualified, so it finds an index outside the search path';

# Index names are unique per schema, not per database. Every tenant schema of
# a multi-tenant layout has the same ones.
{
  my $idx = sub {
    my ($schema, $cols) = @_;
    return { orders_created_idx => {
      index_name  => 'orders_created_idx',
      schema_name => $schema, table_name => 'orders',
      definition  => "CREATE INDEX orders_created_idx ON $schema.orders USING btree ($cols)",
      columns     => [ split /, /, $cols ],
    } };
  };
  my %tenants = map { ("$_.orders" => { schema_name => $_, table_name => 'orders' }) } qw(tenant_a tenant_b);

  my @same = DBIO::PostgreSQL::Diff::Index->diff(
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created') },
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created') },
    \%tenants, \%tenants,
  );
  is_deeply ops_sql(@same), [], 'two schemas with an index of the same name: nothing to do when nothing changed';

  my @gone = DBIO::PostgreSQL::Diff::Index->diff(
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created') },
    { 'tenant_a.orders' => $idx->('tenant_a', 'created') },
    \%tenants, \%tenants,
  );
  is_deeply ops_sql(@gone), [ 'DROP INDEX tenant_b.orders_created_idx;' ],
    '... dropped in one of them: exactly that one is dropped';

  my @changed = DBIO::PostgreSQL::Diff::Index->diff(
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created') },
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created, id') },
    \%tenants, \%tenants,
  );
  is_deeply ops_sql(@changed), [
    'DROP INDEX tenant_b.orders_created_idx;',
    'CREATE INDEX orders_created_idx ON tenant_b.orders USING btree (created, id);',
  ], '... changed in one of them: that one is recreated, the other left alone';

  my @added = DBIO::PostgreSQL::Diff::Index->diff(
    { 'tenant_a.orders' => $idx->('tenant_a', 'created') },
    { 'tenant_a.orders' => $idx->('tenant_a', 'created'), 'tenant_b.orders' => $idx->('tenant_b', 'created') },
    \%tenants, \%tenants,
  );
  is_deeply ops_sql(@added), [ 'CREATE INDEX orders_created_idx ON tenant_b.orders USING btree (created);' ],
    '... new in one of them: created there although the name already exists elsewhere';
}

# --- Diff::Trigger ----------------------------------------------------------

my $trg_def = qq{CREATE TRIGGER "Trg One" BEFORE UPDATE ON $SQL FOR EACH ROW EXECUTE FUNCTION "My.Schema".trg()};
my @trg_ops = DBIO::PostgreSQL::Diff::Trigger->diff(
  { $KEY => { 'Old Trg' => { trigger_name => 'Old Trg', %on, definition => 'x' } } },
  { $KEY => { 'Trg One' => { trigger_name => 'Trg One', %on, definition => $trg_def } } },
);
is_deeply ops_sql(@trg_ops), [ "$trg_def;", qq{DROP TRIGGER "Old Trg" ON $SQL;} ],
  'trigger: a definition from the server as given; the drop quotes trigger and table';

my ($k110_trg) = DBIO::PostgreSQL::Diff::Trigger->diff(
  { 'public.MixedCase' => { t => { trigger_name => 't', schema_name => 'public', table_name => 'MixedCase' } } }, {});
is $k110_trg->as_sql, 'DROP TRIGGER t ON public."MixedCase";', 'k110 as reported: DROP TRIGGER ... ON public."MixedCase"';

# --- Diff::Policy -----------------------------------------------------------

my @pol_ops = DBIO::PostgreSQL::Diff::Policy->diff(
  { $KEY => { 'Old Pol' => { policy_name => 'Old Pol', %on } } },
  { $KEY => { 'Own Rows' => { policy_name => 'Own Rows', %on, command => 'SELECT', using_expr => '("user" > 0)' } } },
  { $KEY => { %table, rls_enabled => 0 }, 'public.Other' => { schema_name => 'public', table_name => 'Other', rls_enabled => 1 } },
  { $KEY => { %table, rls_enabled => 1 }, 'public.Other' => { schema_name => 'public', table_name => 'Other', rls_enabled => 0 } },
);
is_deeply ops_sql(@pol_ops), [
  qq{ALTER TABLE $SQL ENABLE ROW LEVEL SECURITY;},
  q{ALTER TABLE public."Other" DISABLE ROW LEVEL SECURITY;},
  qq{CREATE POLICY "Own Rows" ON $SQL FOR SELECT USING (("user" > 0));},
  qq{DROP POLICY "Old Pol" ON $SQL;},
], 'policy: ENABLE / DISABLE / CREATE / DROP quote policy and table, the expression as given';

# --- Diff::Type -------------------------------------------------------------

my %type = ( schema_name => $SCHEMA );
my @type_ops = DBIO::PostgreSQL::Diff::Type->diff(
  {
    "$SCHEMA.Mood" => { %type, type_name => 'Mood', type_kind => 'enum', values => ['ok'] },
    "$SCHEMA.Gone" => { %type, type_name => 'Gone', type_kind => 'enum', values => ['x'] },
  },
  {
    "$SCHEMA.Mood"  => { %type, type_name => 'Mood', type_kind => 'enum', values => [ 'ok', "don't" ] },
    "$SCHEMA.Level" => { %type, type_name => 'Level', type_kind => 'enum', values => [ 'a', "o'b" ] },
    "$SCHEMA.Addr"  => { %type, type_name => 'Addr', type_kind => 'composite',
                         attributes => [ { name => 'Street', type => 'text' }, { name => 'order', type => 'integer' } ] },
    "$SCHEMA.Span"  => { %type, type_name => 'Span', type_kind => 'range', subtype => 'double precision' },
  },
);
is_deeply ops_sql(@type_ops), [
  q{CREATE TYPE "My.Schema"."Addr" AS (},
  q{  "Street" text,},
  q{  "order" integer},
  q{);},
  q{CREATE TYPE "My.Schema"."Level" AS ENUM ('a', 'o''b');},
  q{ALTER TYPE "My.Schema"."Mood" ADD VALUE 'don''t';},
  q{CREATE TYPE "My.Schema"."Span" AS RANGE (SUBTYPE = double precision);},
  q{DROP TYPE "My.Schema"."Gone";},
], 'type: create (enum, composite, range), add value and drop -- names quoted, values as literals';
is $type_ops[0]->type_key, "$SCHEMA.Addr", '... the op still carries the model key';

# --- Diff::Function ---------------------------------------------------------

my $fn_key = qq{$SCHEMA.Fn One(a integer, "B" text)};
my ($fn_drop) = DBIO::PostgreSQL::Diff::Function->diff(
  { $fn_key => { schema_name => $SCHEMA, function_name => 'Fn One', identity_args => 'a integer, "B" text' } }, {});
is $fn_drop->as_sql, q{DROP FUNCTION "My.Schema"."Fn One"(a integer, "B" text);},
  'function drop: schema and name quoted, the identity arguments as the server gives them';
is $fn_drop->summary, "  -function: $fn_key", '... the summary stays the readable key';

my ($fn_noargs) = DBIO::PostgreSQL::Diff::Function->diff(
  { 'auth.touch()' => { schema_name => 'auth', function_name => 'touch', identity_args => '' } }, {});
is $fn_noargs->as_sql, 'DROP FUNCTION auth.touch();', '... a plain one comes out as before';

# --- Diff::Extension --------------------------------------------------------

is_deeply ops_sql(DBIO::PostgreSQL::Diff::Extension->diff(
    { 'old-ext' => { version => '1' }, 'uuid-ossp' => { version => '1.0' }, pgcrypto => { version => '1.3' } },
    { 'uuid-ossp' => { version => "1.1'x" }, pgcrypto => { version => '1.4' }, 'Post-GIS' => { version => '3' } })),
  [ q{CREATE EXTENSION IF NOT EXISTS "Post-GIS";},
    q{ALTER EXTENSION pgcrypto UPDATE TO '1.4';},
    q{ALTER EXTENSION "uuid-ossp" UPDATE TO '1.1''x';},
    q{DROP EXTENSION "old-ext";} ],
  'extension: uuid-ossp and its like are quoted, the version is a literal';

# --- the way back from a key ------------------------------------------------

# The names come from an entry that carries them. Only a model built by hand
# without them is read from its key, split at the first dot -- right whenever
# the schema name has no dot, which is every key the older tests build.
{
  my $names = sub { [ DBIO::PostgreSQL::Introspect->key_names(@_) ] };
  is_deeply $names->($KEY, table_name => {%on}), [ $SCHEMA, $TABLE ],
    'key_names: the names of the entry, whatever the key looks like';
  is_deeply $names->($KEY, table_name => undef, 1, {}, { schema_name => $SCHEMA }, {%on}), [ $SCHEMA, $TABLE ],
    '... entries that are no hashref or lack a name are passed over';
  is_deeply $names->("$SCHEMA.Mood", type_name => { schema_name => $SCHEMA, type_name => 'Mood', table_name => 'x' }),
    [ $SCHEMA, 'Mood' ], '... the field asked for decides, not another name the entry happens to have';
  is_deeply $names->('auth.users', 'table_name'), [ 'auth', 'users' ],
    '... no entry at all: the key, split at its first dot';
  is_deeply $names->('users', 'table_name'), ['users'], '... a key without a dot is the one name it is';

  my $by_hand = DBIO::PostgreSQL::Diff::Column->new(
    action => 'drop', table_key => 'auth.users', column_name => 'order');
  is $by_hand->as_sql, 'ALTER TABLE auth.users DROP COLUMN "order";',
    'an operation built by hand with a table_key alone still renders';
  is(DBIO::PostgreSQL::Diff::Index->new(
      action => 'drop', table_key => 'users', index_name => 'Idx', index_info => {})->as_sql,
    'DROP INDEX "Idx";', '... and an index drop under a key without a schema names the index alone');
}

# --- the whole diff, as Deploy drives it ------------------------------------

# Diff.pm hands Diff::Trigger no table list, and none is needed: every entry
# Introspect files under a table key carries that table's names.
{
  my $model = sub {
    my (%with) = @_;
    return {
      schemas  => { $SCHEMA => {} },
      tables   => { $KEY => {%table} },
      columns  => { $KEY => [ { column_name => 'user', data_type => 'integer', not_null => 1 } ] },
      indexes  => {}, triggers => {}, policies => {},
      %with,
    };
  };
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => $model->(
      indexes  => { $KEY => { 'Old Idx' => { index_name => 'Old Idx', %on, definition => 'x' } } },
      triggers => { $KEY => { 'Old Trg' => { trigger_name => 'Old Trg', %on, definition => 'x' } } },
      policies => { $KEY => { 'Old Pol' => { policy_name => 'Old Pol', %on } } },
    ),
    target => $model->(),
  );
  # Drops come in the reverse of the order of dependency (karr k109, t/92).
  is $diff->as_sql, join("\n",
    qq{DROP POLICY "Old Pol" ON $SQL;},
    qq{DROP TRIGGER "Old Trg" ON $SQL;},
    q{DROP INDEX "My.Schema"."Old Idx";},
  ), 'a whole diff: index, trigger and policy of a table with dots in schema and name';
}

# --- target_from_compiled: the definition the server would report -----------

# Diff::Index compares definition strings, so the synthesized one has to be
# pg_get_indexdef's character for character -- and the server quotes there
# by the same rule. Measured on PostgreSQL 18.6:
#   CREATE UNIQUE INDEX order_pkey ON public."order" USING btree ("user")
#   CREATE UNIQUE INDEX "MixedCase_pkey" ON public."MixedCase" USING btree (id)
{
  my $target = DBIO::PostgreSQL::Diff->target_from_compiled({ tables => {
    order => { columns => [
      { column_name => 'user',  native_type => 'integer', is_pk => 1, not_null => 1 },
      { column_name => 'Title', native_type => 'text', default => "it's" },
    ] },
    MixedCase => { columns => [ { column_name => 'id', native_type => 'integer', is_pk => 1, not_null => 1 } ] },
    plain => { columns => [ { column_name => 'id', native_type => 'integer', is_pk => 1, not_null => 1 } ] },
  } });
  is $target->{indexes}{'public.order'}{order_pkey}{definition},
    'CREATE UNIQUE INDEX order_pkey ON public."order" USING btree ("user")',
    'target_from_compiled: reserved table and column names as pg_get_indexdef writes them';
  is $target->{indexes}{'public.MixedCase'}{MixedCase_pkey}{definition},
    'CREATE UNIQUE INDEX "MixedCase_pkey" ON public."MixedCase" USING btree (id)',
    '... a Mixed-Case table, and the index name derived from it';
  is $target->{indexes}{'public.plain'}{plain_pkey}{definition},
    'CREATE UNIQUE INDEX plain_pkey ON public.plain USING btree (id)',
    '... a plain one unchanged';
  is $target->{columns}{'public.order'}[1]{default_value}, q{'it''s'::text},
    q{... and a string default as pg_get_expr writes it: 'it''s'::text};
  is_deeply [ @{ $target->{indexes}{'public.order'}{order_pkey} }{qw(schema_name table_name)} ],
    [ 'public', 'order' ], '... the index entry names its table like an introspected one';
}

done_testing;
