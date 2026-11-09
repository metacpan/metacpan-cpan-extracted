use strict;
use warnings;

use Test::More;

use DBIO::Core ();
use DBIO::PostgreSQL::DDL;

# OFFLINE test for karr k115 / k117 (and the install side of k110): every name
# install_ddl writes is an identifier by the server's rule, every value a
# literal.
#
# WHY it exists: a schema with a column called "user" or "order" could not be
# deployed (syntax error), a Mixed-Case table or schema was created under its
# folded name -- which the queries, always quoting, then did not find -- and an
# apostrophe in a default, an enum value or a setting ended the literal early.
# Each case below was a statement the server refused or misread. Plain
# lower-case names must still come out bare: that is the same rule, and what
# every other DDL test in this directory expects.

{
  package QD::PgSchema::AppData;
  use base 'DBIO::PostgreSQL::PgSchema';
  __PACKAGE__->pg_enum('Mood' => [ 'ok', "don't", 'so so' ]);
  __PACKAGE__->pg_type('Addr' => { Street => 'text', order => 'integer' });
}
{
  package QD::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('AppData', 'plain');
  __PACKAGE__->pg_schema_class(AppData => 'QD::PgSchema::AppData');
  __PACKAGE__->pg_extensions('uuid-ossp', 'pgcrypto');
  __PACKAGE__->pg_settings({ 'myapp.greeting' => "it's me" });
}
{
  package QD::Schema::Result::Group;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('group');
  __PACKAGE__->add_columns(
    order => { data_type => 'bigint', is_nullable => 0 },
    name  => { data_type => 'text',   is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('order');
}
{
  package QD::Schema::Result::Entry;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('AppData');
  __PACKAGE__->table('MixedCase');
  __PACKAGE__->add_columns(
    user  => { data_type => 'bigint', is_nullable => 0 },
    order => { data_type => 'text',   is_nullable => 1 },
    Title => { data_type => 'text',   is_nullable => 0, default_value => "it's" },
    mood  => { data_type => 'enum',   is_nullable => 1, extra => { list => [ 'a', "o'b" ] } },
    stamp => { data_type => 'text',   is_nullable => 1, default_value => \q{'now'::text} },
    group => { data_type => 'bigint', is_nullable => 1 },
    plain => { data_type => 'text',   is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('user');
  __PACKAGE__->add_unique_constraint('Entry Order' => [ 'order', 'Title' ]);
  __PACKAGE__->pg_index('Idx Title' => {
    columns => [ 'Title', 'order' ],
    include => [ 'plain', 'group' ],
    where   => q{"Title" <> ''},
  });
  __PACKAGE__->pg_trigger('Trg Touch' => {
    when => 'BEFORE', event => 'UPDATE', execute => 'touch()',
  });
  __PACKAGE__->pg_rls({
    enable   => 1,
    force    => 1,
    policies => {
      'Own Rows' => { for => 'SELECT', roles => ['PUBLIC'], using => 'true' },
      by_role    => { roles => [ 'AppRole', 'current_user', 'plain_role' ], using => 'true' },
    },
  });
  __PACKAGE__->pg_check_constraint('Positive User' => '"user" > 0');
  __PACKAGE__->pg_fk_constraints_from_rels(1);
  __PACKAGE__->belongs_to(
    group_rel => 'QD::Schema::Result::Group', { 'foreign.order' => 'self.group' },
  );
}
{
  # table('schema.table') without pg_schema: the idiom t/10 and t/16 use.
  package QD::Schema::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('dbio_deploy_test.dbio_deploy_widget');
  __PACKAGE__->add_columns(
    id     => { data_type => 'bigint', is_nullable => 0 },
    status => { data_type => 'enum',   is_nullable => 1, extra => { list => [qw(new done)] } },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index(widget_status_idx => { columns => ['status'] });
}
{
  package QD::Schema::Result::TenantOrder;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('Tenant.Orders');
  __PACKAGE__->add_columns(id => { data_type => 'bigint', is_nullable => 0 });
  __PACKAGE__->set_primary_key('id');
}
{
  package QD::Schema::Result::EntryView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('AppData');
  __PACKAGE__->table('Entry View');
  __PACKAGE__->add_columns(user => { data_type => 'bigint' });
  __PACKAGE__->result_source_instance->view_definition('SELECT "user" FROM "AppData"."MixedCase"');
}

QD::Schema->register_class($_ => "QD::Schema::Result::$_")
  for qw(Group Entry Widget TenantOrder EntryView);

my $sql = DBIO::PostgreSQL::DDL->install_ddl('QD::Schema');
note $sql;

sub has_stmt {
  my ($fragment, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  ok index($sql, $fragment) >= 0, $name or diag "missing: $fragment";
}

# --- k115: reserved words as column, table and key names --------------------

has_stmt qq{CREATE TABLE "group" (\n  "order" bigint NOT NULL,\n  name text,\n  PRIMARY KEY ("order")\n);},
  'a table and a column that are reserved words deploy quoted, a plain column bare';
has_stmt qq{  "user" bigint NOT NULL,\n  "order" text,}, 'the columns "user" and "order" are quoted';
has_stmt qq{  PRIMARY KEY ("user")},                     '... in the PRIMARY KEY list too';
has_stmt q{CONSTRAINT "Entry Order" UNIQUE ("order", "Title")},
  '... and in a UNIQUE constraint, whose own name is quoted';
unlike $sql, qr/^\s+(?:user|order|group) /m, 'no reserved word starts a column definition bare';

# --- the install side of k110: Mixed-Case schema and table ------------------

has_stmt 'CREATE SCHEMA IF NOT EXISTS "AppData";', 'a Mixed-Case schema is created under its exact name';
has_stmt 'CREATE SCHEMA IF NOT EXISTS plain;',     '... a plain one bare';
has_stmt 'CREATE TABLE "AppData"."MixedCase" (',   'a Mixed-Case table in a Mixed-Case schema: each part quoted';
unlike $sql, qr/AppData\.MixedCase/, 'the raw schema.table pair appears nowhere';

has_stmt q{CREATE INDEX "Idx Title" ON "AppData"."MixedCase" ("Title", "order") INCLUDE (plain, "group") WHERE "Title" <> '';},
  'an index: its name, its table, key and INCLUDE columns are names; the predicate is written as given';
has_stmt 'CREATE TRIGGER "Trg Touch" BEFORE UPDATE ON "AppData"."MixedCase" FOR EACH ROW EXECUTE FUNCTION touch();',
  'a trigger: name and table quoted, timing, event and function as given';
has_stmt 'ALTER TABLE "AppData"."MixedCase" ENABLE ROW LEVEL SECURITY;', 'ENABLE ROW LEVEL SECURITY names the table';
has_stmt 'ALTER TABLE "AppData"."MixedCase" FORCE ROW LEVEL SECURITY;',  '... and so does FORCE';
has_stmt 'ALTER TABLE "AppData"."MixedCase" ADD CONSTRAINT "Positive User" CHECK ("user" > 0);',
  'a CHECK constraint: name quoted, expression as given';
has_stmt 'ALTER TABLE "AppData"."MixedCase" ADD CONSTRAINT "MixedCase_group_fkey" FOREIGN KEY ("group") REFERENCES "group" ("order");',
  'a FOREIGN KEY: both tables, both column lists and the constraint name';
has_stmt 'CREATE VIEW "AppData"."Entry View" AS SELECT "user" FROM "AppData"."MixedCase";',
  'a view is created under its exact name, its definition as given';

# --- policy roles: names, except the key words that stand for a role --------

has_stmt 'CREATE POLICY "Own Rows" ON "AppData"."MixedCase" FOR SELECT TO PUBLIC USING (true);',
  'PUBLIC stays a key word -- TO "PUBLIC" would name a role called PUBLIC';
has_stmt 'CREATE POLICY by_role ON "AppData"."MixedCase" TO "AppRole", current_user, plain_role USING (true);',
  'a Mixed-Case role is quoted, current_user and a plain role are not';

# --- types ------------------------------------------------------------------

has_stmt q{CREATE TYPE "AppData"."Mood" AS ENUM ('ok', 'don''t', 'so so');},
  'k117: an apostrophe in a PgSchema enum value is doubled; the type name is quoted';
has_stmt qq{CREATE TYPE "AppData"."Addr" AS (\n  "Street" text,\n  "order" integer\n);},
  'composite type: name and attribute names quoted, attribute types as given';

# --- k117: literals ---------------------------------------------------------

has_stmt q{  "Title" text NOT NULL DEFAULT 'it''s',},  'an apostrophe in a string default is doubled';
has_stmt q{  stamp text DEFAULT 'now'::text,},         'a scalar-ref default is SQL and is written as given';
has_stmt q{current_database(), 'myapp.greeting', 'it''s me');},
  'an apostrophe in a pg_settings value is doubled';
unlike $sql, qr/'it's|'o'b'|'don't'/, 'no literal is cut short by its own apostrophe';

# --- extensions -------------------------------------------------------------

has_stmt q{CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;}, q{an extension name that needs quotes gets them (WITH SCHEMA public, karr k141)};
has_stmt q{CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;}, q{... one that does not is bare, by the same rule};

# --- the generated enum type: one name in CREATE TYPE and in the column -----

for my $case (
  [ 'a Mixed-Case table in a pg_schema', '"AppData"."MixedCase_mood_enum"', q{('a', 'o''b')}, 'mood' ],
  [ "table('schema.table')", 'dbio_deploy_test.dbio_deploy_widget_status_enum', q{('new', 'done')}, 'status' ],
) {
  my ($what, $type, $values, $column) = @$case;
  has_stmt "CREATE TYPE $type AS ENUM $values;", "$what: the generated enum type is created as $type";
  has_stmt "  $column $type", "... and the column is of exactly that type";
}

# --- table('schema.table'): the DDL names the relation the queries name -----

# The SQL maker splits a source name at the name separator and quotes each
# part. The DDL has to arrive at the same relation: "a.b" as ONE identifier
# would create a table the queries never find.
my $schema = QD::Schema->connect('dbi:Pg:dbname=never_connected', '', '');

sub name_parts {
  my ($sql_name) = @_;
  my @parts;
  while ($sql_name =~ /\G(?:"((?:[^"]|"")*)"|([^".]+))(?:\.|\z)/gc) {
    my ($quoted, $bare) = ($1, $2);
    if (defined $quoted) { $quoted =~ s/""/"/g; push @parts, $quoted }
    else                 { push @parts, lc $bare }
  }
  return \@parts;
}

my @created = $sql =~ /^CREATE TABLE (.+) \($/mg;

for my $source (qw(Widget TenantOrder Group Entry)) {
  my ($from) = ${ $schema->resultset($source)->as_query }->[0] =~ /FROM (\S+) "me"/;
  my @query  = @{ name_parts($from) };
  # pg_schema qualifies the DDL only; the query leaves the schema to the
  # search path. So the query's parts must be the tail of the DDL's.
  my @match = grep {
    my @ddl = @{ name_parts($_) };
    @ddl >= @query && "@ddl[ $#ddl - $#query .. $#ddl ]" eq "@query";
  } @created;
  is scalar @match, 1, "$source: exactly one CREATE TABLE names the relation the query reads ($from)"
    or diag "created: @created";
}

has_stmt 'CREATE TABLE dbio_deploy_test.dbio_deploy_widget (',
  "table('schema.table') is schema and table, each for itself";
has_stmt 'CREATE INDEX widget_status_idx ON dbio_deploy_test.dbio_deploy_widget (status);',
  '... in an index on it as well';
has_stmt 'CREATE TABLE "Tenant"."Orders" (', '... and each part keeps its case';
unlike $sql, qr/"dbio_deploy_test\.dbio_deploy_widget|"Tenant\.Orders/,
  'a dotted source name is never quoted as one identifier';

# --- install_ddl reads the schema, it does not change it --------------------

# It used to write the generated type name back into the source's column
# info, so a second call found the column "already typed" and left out the
# CREATE TYPE: install, then diff in one process, deployed the temporary
# database without the type.
is(DBIO::PostgreSQL::DDL->install_ddl('QD::Schema'), $sql,
  'a second install_ddl returns the same DDL');
for my $case ([ Entry => 'mood' ], [ Widget => 'status' ]) {
  my ($source, $column) = @$case;
  ok !exists QD::Schema->source($source)->column_info($column)->{pg_enum_type},
    "$source.$column: no pg_enum_type was written into the column info";
}

done_testing;
