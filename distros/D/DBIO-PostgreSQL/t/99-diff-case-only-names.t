use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Diff;

# karr k119 -- a name that differs from one in the database only in upper and
# lower case is not a new object.
#
# WHY it exists: PostgreSQL reads a name written without quotes in lower case.
# Until karr k110 the DDL wrote a declared UserAccount bare, so a database
# deployed back then holds useraccount. Since k110 the name is written
# exactly, the temporary database of Deploy->diff holds "UserAccount", and the
# diff -- which compares names as they are -- saw two tables:
#
#   CREATE TABLE public."UserAccount" (id bigint NOT NULL, "createdAt" text);
#   DROP TABLE public.useraccount;
#
# and for a column ADD COLUMN "createdAt" beside DROP COLUMN createdat. apply
# ran through, and the rows were gone. No diff may take the one spelling of a
# name away to put the other in its place: it does not know they are the same
# object, and it does not know they are not.
#
# What is held here, without a database (t/99-...-live.t holds the table and
# the column against a server, with a row that has to survive):
#
#  1. where the drop takes data, or the server refuses it, the diff is
#     refused: schema, table, materialized view, column, type, and an index a
#     constraint may stand on. The refusal names the kind of object, both
#     spellings, and the RENAME that makes the one into the other;
#  2. a schema is reported as a schema, not as every table in it;
#  3. nothing else is refused: a name the other side has as well, a name that
#     is another name, the same name somewhere else;
#  4. where dropping and creating loses nothing and runs -- view, plain index,
#     function, trigger, policy -- it stays what the diff does (measured on
#     PostgreSQL 18.6, see the card).

sub relation {
  my ($kind, $schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, table_name => $name, kind => $kind, %more });
}
sub table   { relation(r => @_) }
sub columns { [ map { { column_name => $_, data_type => 'integer' } } @_ ] }

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}
sub statements {
  my ($diff) = @_;
  return [ map { $_->as_sql } @{ $diff->operations } ];
}

# The refusal: no operation is built, and the message says which object, in
# both spellings, and how to make the one into the other.
sub refused_ok {
  my ($label, $source, $target, %want) = @_;
  my $diff = diff_of($source, $target);
  my $ops = eval { $diff->operations };
  my $error = $@;

  ok(!$ops, "$label: no operation is built")
    or diag join "\n", map { $_->as_sql } @$ops;
  like($error, qr/\Arefusing to diff: \Q$want{kind}\E /,
    "$label: refused, and as a $want{kind}");

  my ($head) = split /\n/, $error;
  like($head, qr/(?<![\w.])\Q$_\E(?![\w.])/, "$label: the first line names $_")
    for @{ $want{names} };
  like($error, qr/upper and lower case/, "$label: and gives the reason");
  like($error, qr/^  \Q$_\E$/m, "$label: the way out is $_")
    for @{ $want{rename} };
  like($error, qr/No statement was generated/, "$label: and says nothing was written");
  return $error;
}

# ---------------------------------------------------------------------------
# 1. Refused: table
# ---------------------------------------------------------------------------
my %stock = (
  schemas => { public => {} },
  tables  => { table(public => 'useraccount') },
  columns => { 'public.useraccount' => columns(qw( id createdat )) },
);

refused_ok('a table',
  \%stock,
  {
    schemas => { public => {} },
    tables  => { table(public => 'UserAccount') },
    columns => { 'public.UserAccount' => columns(qw( id createdAt )) },
  },
  kind   => 'table',
  names  => [qw( public.useraccount public.UserAccount )],
  rename => [ 'ALTER TABLE public.useraccount RENAME TO "UserAccount";' ],
);

# The other way round is the same question: the database has the quoted
# name, the target the folded one.
refused_ok('a table the database has in Mixed Case',
  { tables => { table(public => 'UserAccount') } },
  { tables => { table(public => 'useraccount') } },
  kind   => 'table',
  names  => [qw( public.UserAccount public.useraccount )],
  rename => [ 'ALTER TABLE public."UserAccount" RENAME TO useraccount;' ],
);

# Every such table at once: a schema written in Mixed Case has more than one,
# and a refusal per run would be a run per table.
{
  my $error = refused_ok('several tables',
    { tables => { table(public => 'useraccount'), table(shop => 'orderitem'), table(public => 'keep') } },
    { tables => { table(public => 'UserAccount'), table(shop => 'OrderItem'), table(public => 'keep') } },
    kind   => 'table',
    names  => [qw( public.useraccount public.UserAccount )],
    rename => [
      'ALTER TABLE public.useraccount RENAME TO "UserAccount";',
      'ALTER TABLE shop.orderitem RENAME TO "OrderItem";',
    ],
  );
  like($error, qr/shop\.orderitem\b.*\bshop\.OrderItem\b/, 'the second table is named in both spellings too');
  unlike($error, qr/\bkeep\b/, 'a table both sides have under one name is not mentioned');
}

# A partitioned and a foreign table are renamed like any other; the diff
# cannot create either, and "cannot create it" is not what there is to say.
refused_ok('a partitioned table',
  { tables => { relation(p => public => 'events') } },
  { tables => { relation(p => public => 'Events') } },
  kind   => 'partitioned table',
  names  => [qw( public.events public.Events )],
  rename => [ 'ALTER TABLE public.events RENAME TO "Events";' ],
);
refused_ok('a foreign table',
  { tables => { relation(f => public => 'remote') } },
  { tables => { relation(f => public => 'Remote') } },
  kind   => 'foreign table',
  names  => [qw( public.remote public.Remote )],
  rename => [ 'ALTER FOREIGN TABLE public.remote RENAME TO "Remote";' ],
);

# A materialized view holds data and indexes, and a changed one is refused
# for that already.
refused_ok('a materialized view',
  { tables => { relation(m => public => 'totals', view_definition => 'SELECT 1 AS n') } },
  { tables => { relation(m => public => 'Totals', view_definition => 'SELECT 1 AS n') } },
  kind   => 'materialized view',
  names  => [qw( public.totals public.Totals )],
  rename => [ 'ALTER MATERIALIZED VIEW public.totals RENAME TO "Totals";' ],
);

# ---------------------------------------------------------------------------
# 1. Refused: column
# ---------------------------------------------------------------------------
my %acct = ( schemas => { public => {} }, tables => { table(public => 'acct') } );

refused_ok('a column',
  { %acct, columns => { 'public.acct' => columns(qw( id createdat )) } },
  { %acct, columns => { 'public.acct' => columns(qw( id createdAt )) } },
  kind   => 'column',
  names  => [qw( public.acct.createdat public.acct.createdAt )],
  rename => [ 'ALTER TABLE public.acct RENAME COLUMN createdat TO "createdAt";' ],
);

refused_ok('columns of several tables',
  {
    tables  => { table(public => 'acct'), table(public => 'Order') },
    columns => { 'public.acct' => columns(qw( id createdat updatedat )), 'public.Order' => columns(qw( id userid )) },
  },
  {
    tables  => { table(public => 'acct'), table(public => 'Order') },
    columns => { 'public.acct' => columns(qw( id createdAt updatedAt )), 'public.Order' => columns(qw( id userId )) },
  },
  kind   => 'column',
  names  => [qw( public.Order.userid public.Order.userId )],
  rename => [
    'ALTER TABLE public."Order" RENAME COLUMN userid TO "userId";',
    'ALTER TABLE public.acct RENAME COLUMN createdat TO "createdAt";',
    'ALTER TABLE public.acct RENAME COLUMN updatedat TO "updatedAt";',
  ],
);

# ---------------------------------------------------------------------------
# 1. Refused: type
# ---------------------------------------------------------------------------
sub type {
  my ($kind, $schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, type_name => $name, type_kind => $kind, %more });
}

for my $case (
  [ enum      => values     => [qw( admin user )] ],
  [ composite => attributes => [ { name => 'street', type => 'text' } ] ],
  [ range     => subtype    => 'double precision' ],
) {
  my ($kind, @more) = @$case;
  refused_ok("a type ($kind)",
    { types => { type($kind, auth => 'role_type', @more) } },
    { types => { type($kind, auth => 'Role_Type', @more) } },
    kind   => 'type',
    names  => [qw( auth.role_type auth.Role_Type )],
    rename => [ 'ALTER TYPE auth.role_type RENAME TO "Role_Type";' ],
  );
}

# ---------------------------------------------------------------------------
# 1. Refused: an index a constraint may stand on
# ---------------------------------------------------------------------------
# The index of a primary key keeps its name when its table is renamed, so it
# is what the diff meets next once the table of the first case has been
# renamed by hand. DROP INDEX fails for it: the constraint requires it.
sub index_on {
  my ($schema, $table, $name, %more) = @_;
  return ($name => {
    schema_name => $schema, table_name => $table, index_name => $name,
    is_unique => 0, is_primary => 0,
    definition => sprintf('CREATE INDEX %s ON %s.%s USING btree (id)',
      map { DBIO::PostgreSQL::Util::quote_ident($_) } $name, $schema, $table),
    %more,
  });
}
my %renamed = ( tables => { table(public => 'UserAccount') } );

refused_ok('the index of a primary key',
  { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'useraccount_pkey', is_unique => 1, is_primary => 1) } } },
  { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'UserAccount_pkey', is_unique => 1, is_primary => 1) } } },
  kind   => 'index',
  names  => [qw( public.useraccount_pkey public.UserAccount_pkey )],
  rename => [ 'ALTER INDEX public.useraccount_pkey RENAME TO "UserAccount_pkey";' ],
);
# The model says which index a constraint stands behind (karr k121): a unique
# index that has one is refused as the primary key's is; the refusal used to
# guess at it from `is_unique`.
refused_ok('the index of a UNIQUE constraint',
  { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'useraccount_email_key', is_unique => 1, constraint_name => 'useraccount_email_key', constraint_type => 'u') } } },
  { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'UserAccount_email_key', is_unique => 1, constraint_name => 'UserAccount_email_key', constraint_type => 'u') } } },
  kind   => 'index',
  names  => [qw( public.useraccount_email_key public.UserAccount_email_key )],
  rename => [ 'ALTER INDEX public.useraccount_email_key RENAME TO "UserAccount_email_key";' ],
);
# ... and one that has none is dropped and created, as any index is: DROP INDEX
# takes it, and nothing is lost with it.
is_deeply(
  statements(diff_of(
    { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'useraccount_email_idx', is_unique => 1, constraint_name => undef, constraint_type => undef) } } },
    { %renamed, indexes => { 'public.UserAccount' => { index_on(public => 'UserAccount', 'UserAccount_email_idx', is_unique => 1, constraint_name => undef, constraint_type => undef) } } },
  )),
  [ 'CREATE INDEX "UserAccount_email_idx" ON public."UserAccount" USING btree (id);',
    'DROP INDEX public.useraccount_email_idx;' ],
  'a unique index no constraint stands on is created under the new spelling and the old one dropped');

# ---------------------------------------------------------------------------
# 2. A schema is a schema
# ---------------------------------------------------------------------------
# Every table of auth is, by its key, a table the target does not have, and
# every table of Auth one the database does not have. The answer is one
# rename of the schema, not one of each table -- and none of the tables is
# the same name in another spelling: users is users.
{
  my $error = refused_ok('a schema',
    {
      schemas => { public => {}, auth => {} },
      tables  => { table(auth => 'users'), table(auth => 'roles') },
      columns => { 'auth.users' => columns('id'), 'auth.roles' => columns('id') },
    },
    {
      schemas => { public => {}, Auth => {} },
      tables  => { table(Auth => 'users'), table(Auth => 'roles') },
      columns => { 'Auth.users' => columns('id'), 'Auth.roles' => columns('id') },
    },
    kind   => 'schema',
    names  => [qw( auth Auth )],
    rename => [ 'ALTER SCHEMA auth RENAME TO "Auth";' ],
  );
  unlike($error, qr/ALTER TABLE/, 'a schema in another spelling is not reported table by table');
}

# ---------------------------------------------------------------------------
# 3. Not refused
# ---------------------------------------------------------------------------
# The target has both spellings: they are two tables there, so the database
# is to have two.
is_deeply(
  statements(diff_of(
    { tables => { table(public => 'useraccount') }, columns => { 'public.useraccount' => columns('id') } },
    {
      tables  => { table(public => 'useraccount'), table(public => 'UserAccount') },
      columns => { 'public.useraccount' => columns('id'), 'public.UserAccount' => columns('id') },
    },
  )),
  [ 'CREATE TABLE public."UserAccount" (id integer);' ],
  'a table the target has in both spellings is created beside the one that is there');

# The database has both: nothing is created, so nothing can be the same
# object as the one that goes.
is_deeply(
  statements(diff_of(
    { tables => { table(public => 'useraccount'), table(public => 'UserAccount') } },
    { tables => { table(public => 'UserAccount') } },
  )),
  [ 'DROP TABLE public.useraccount;' ],
  'a table the database has in both spellings loses the one the target does not have');

# Another name is another table, as before.
is_deeply(
  statements(diff_of(
    { tables => { table(public => 'useraccount') }, columns => { 'public.useraccount' => columns('id') } },
    { tables => { table(public => 'user_account') }, columns => { 'public.user_account' => columns('id') } },
  )),
  [ 'CREATE TABLE public.user_account (id integer);', 'DROP TABLE public.useraccount;' ],
  'a table under a really different name is created and the old one dropped');

# The same letters in another schema are another table: tables are named
# within their schema.
is_deeply(
  statements(diff_of(
    { tables => { table(old => 'users') },  columns => { 'old.users' => columns('id') } },
    { tables => { table(new => 'Users') },  columns => { 'new.Users' => columns('id') } },
  )),
  [ 'CREATE TABLE new."Users" (id integer);', 'DROP TABLE old.users;' ],
  'a name that differs only in case from one in another schema is no reason to refuse');

# A table and a view: no rename makes the one into the other.
is_deeply(
  statements(diff_of(
    { tables => { table(public => 'report') } },
    { tables => { relation(v => public => 'Report', view_definition => 'SELECT 1 AS n') } },
  )),
  [ 'CREATE VIEW public."Report" AS SELECT 1 AS n;', 'DROP TABLE public.report;' ],
  'a table and a view whose names differ only in case are two relations');

# Columns: the same three.
is_deeply(
  statements(diff_of(
    { %acct, columns => { 'public.acct' => columns(qw( id createdat )) } },
    { %acct, columns => { 'public.acct' => columns(qw( id createdat createdAt )) } },
  )),
  [ 'ALTER TABLE public.acct ADD COLUMN "createdAt" integer;' ],
  'a column the target has in both spellings is added');
is_deeply(
  statements(diff_of(
    { %acct, columns => { 'public.acct' => columns(qw( id createdat createdAt )) } },
    { %acct, columns => { 'public.acct' => columns(qw( id createdAt )) } },
  )),
  [ 'ALTER TABLE public.acct DROP COLUMN createdat;' ],
  'a column the database has in both spellings loses the one the target does not have');
is_deeply(
  statements(diff_of(
    { %acct, columns => { 'public.acct' => columns(qw( id createdat )) } },
    { %acct, columns => { 'public.acct' => columns(qw( id created_at )) } },
  )),
  [ 'ALTER TABLE public.acct ADD COLUMN created_at integer;', 'ALTER TABLE public.acct DROP COLUMN createdat;' ],
  'a column under a really different name is added and the old one dropped');
is_deeply(
  statements(diff_of(
    {
      tables  => { table(public => 'a'), table(public => 'b') },
      columns => { 'public.a' => columns(qw( id note )), 'public.b' => columns(qw( id )) },
    },
    {
      tables  => { table(public => 'a'), table(public => 'b') },
      columns => { 'public.a' => columns(qw( id )), 'public.b' => columns(qw( id Note )) },
    },
  )),
  [ 'ALTER TABLE public.b ADD COLUMN "Note" integer;', 'ALTER TABLE public.a DROP COLUMN note;' ],
  'a column name that differs only in case from one of another table is no reason to refuse');

# Types and schemas: another name stays a create and a drop.
is_deeply(
  statements(diff_of(
    { types => { type(enum => auth => 'role_type', values => ['a']) } },
    { types => { type(enum => auth => 'role_kind', values => ['a']) } },
  )),
  [ q{CREATE TYPE auth.role_kind AS ENUM ('a');}, 'DROP TYPE auth.role_type;' ],
  'a type under a really different name is created and the old one dropped');
is_deeply(
  statements(diff_of({ schemas => { auth => {} } }, { schemas => { authn => {} } })),
  [ 'CREATE SCHEMA authn;', 'DROP SCHEMA auth;' ],
  'a schema under a really different name is created and the old one dropped');

# ---------------------------------------------------------------------------
# 4. Dropped and created, as before
# ---------------------------------------------------------------------------
# For these the two statements run on a server and lose nothing the model
# holds (measured; a view loses what every rebuilt view loses, the privileges
# granted on it). They are pinned so that a change to them is a decision.
my %t = ( tables => { table(public => 't') } );

is_deeply(
  statements(diff_of(
    { %t, indexes => { 'public.t' => { index_on(public => 't', 't_a_idx') } } },
    { %t, indexes => { 'public.t' => { index_on(public => 't', 'T_A_Idx') } } },
  )),
  [ 'CREATE INDEX "T_A_Idx" ON public.t USING btree (id);', 'DROP INDEX public.t_a_idx;' ],
  'an index that is not unique is created under the new name and dropped under the old');

is_deeply(
  statements(diff_of(
    { tables => { table(public => 't'), relation(v => public => 'active', view_definition => 'SELECT id FROM t') } },
    { tables => { table(public => 't'), relation(v => public => 'Active', view_definition => 'SELECT id FROM t') } },
  )),
  [ 'CREATE VIEW public."Active" AS SELECT id FROM t;', 'DROP VIEW public.active;' ],
  'a view is created under the new name and dropped under the old');

{
  my $def = sub { "CREATE OR REPLACE FUNCTION public.$_[0]() RETURNS trigger LANGUAGE plpgsql AS \$\$ BEGIN RETURN NEW; END \$\$" };
  my $fn = sub {
    my ($name, $written) = @_;
    return ("public.$name()" => {
      schema_name => 'public', function_name => $name, identity_args => '', definition => $def->($written),
    });
  };
  is_deeply(
    statements(diff_of({ functions => { $fn->('touch', 'touch') } }, { functions => { $fn->('Touch', '"Touch"') } })),
    [ $def->('"Touch"') . ';', 'DROP FUNCTION public.touch();' ],
    'a function is created under the new name and dropped under the old');
}

{
  my $trigger = sub {
    my ($name) = @_;
    return ('public.t' => { $name => {
      schema_name => 'public', table_name => 't', trigger_name => $name,
      definition => sprintf('CREATE TRIGGER %s BEFORE UPDATE ON public.t FOR EACH ROW EXECUTE FUNCTION touch()',
        DBIO::PostgreSQL::Util::quote_ident($name)),
    } });
  };
  is_deeply(
    statements(diff_of({ %t, triggers => { $trigger->('t_touch') } }, { %t, triggers => { $trigger->('T_Touch') } })),
    [ 'CREATE TRIGGER "T_Touch" BEFORE UPDATE ON public.t FOR EACH ROW EXECUTE FUNCTION touch();',
      'DROP TRIGGER t_touch ON public.t;' ],
    'a trigger is created under the new name and dropped under the old');
}

{
  my $policy = sub {
    my ($name) = @_;
    return ('public.t' => { $name => {
      schema_name => 'public', table_name => 't', policy_name => $name,
      command => 'ALL', permissive => 1, using_expr => '(a > 0)',
    } });
  };
  is_deeply(
    statements(diff_of({ %t, policies => { $policy->('own_rows') } }, { %t, policies => { $policy->('Own_Rows') } })),
    [ 'CREATE POLICY "Own_Rows" ON public.t USING ((a > 0));', 'DROP POLICY own_rows ON public.t;' ],
    'a policy is created under the new name and dropped under the old');
}

done_testing;
