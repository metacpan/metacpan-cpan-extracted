use Test2::V0 '!meta', '!pass';
use lib 't/lib';

# PostgreSQL introspection follows the connection's search_path: every catalog
# query is scoped to the path's schemas, the first schema wins on name
# collisions, and quoted mixed-case identifiers survive (constraint and index
# metadata comes from oid joins / pg_get_constraintdef parsing with quote
# stripping, not regnamespace casts or indexdef regexes).

BEGIN {
    skip_all "DBD::Pg is required for these tests"
        unless eval { require DBD::Pg; 1 };
}

use DBIx::QuickORM::Test qw/psql/;

my $db = psql() or skip_all "Could not provision a PostgreSQL database";

{
    my $dbh = $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1);

    $dbh->do('CREATE SCHEMA app');
    $dbh->do('CREATE TABLE app.things (thing_id SERIAL PRIMARY KEY, label TEXT NOT NULL UNIQUE)');
    $dbh->do('CREATE TABLE app.widgets (widget_id SERIAL PRIMARY KEY, thing_id INTEGER REFERENCES app.things(thing_id))');
    $dbh->do('CREATE INDEX widgets_thing_idx ON app.widgets(thing_id)');

    $dbh->do('CREATE TABLE public."MixedCase" ("MyId" INTEGER PRIMARY KEY, "MyVal" TEXT, UNIQUE("MyVal"))');

    # The same table name in two schemas on the path; app comes first in the
    # search_path below so its version must win.
    $dbh->do('CREATE TABLE public.dupe (pub_col INTEGER)');
    $dbh->do('CREATE TABLE app.dupe (app_col INTEGER PRIMARY KEY)');

    $dbh->disconnect;
}

require DBIx::QuickORM;
my $con = DBIx::QuickORM->quick(
    connect => sub {
        my $dbh = $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1);
        $dbh->do('SET search_path TO app, public');
        return $dbh;
    },
);

my $schema = $con->schema;

subtest non_public_schema => sub {
    my $things = $schema->maybe_table('things');
    ok($things, "table in the app schema was introspected") or return;

    is([sort $things->column_names], [qw/label thing_id/], "all columns introspected");
    is($things->primary_key, ['thing_id'], "primary key introspected");
    ok($things->unique->{'label'}, "unique constraint introspected");
    ok($things->column('thing_id')->identity, "serial column marked identity");
    ok(!$things->column('label')->nullable, "NOT NULL introspected");

    my $widgets = $schema->table('widgets');
    my ($to_things) = grep { $_->other_table eq 'things' } @{$widgets->links};
    ok($to_things, "foreign key link introspected") or return;
    ok($to_things->unique, "widgets -> things link is one-to-one (points at the PK)");

    my ($to_widgets) = grep { $_->other_table eq 'widgets' } @{$things->links};
    ok($to_widgets, "reverse link present") or return;
    ok(!$to_widgets->unique, "things -> widgets link is one-to-many despite the plain index on widgets.thing_id");

    my ($plain_idx) = grep { $_->{name} eq 'widgets_thing_idx' } @{$widgets->indexes};
    ok($plain_idx, "plain index introspected") or return;
    is($plain_idx->{columns}, ['thing_id'], "index column introspected");
    ok(!$plain_idx->{unique}, "plain index is not unique");
};

subtest mixed_case_table => sub {
    my $mixed = $schema->maybe_table('MixedCase');
    ok($mixed, "mixed-case quoted table was introspected") or return;

    is([sort $mixed->column_names], [qw/MyId MyVal/], "mixed-case columns keep their case");
    is($mixed->primary_key, ['MyId'], "primary key keeps its case, quotes stripped");
    ok($mixed->unique->{'MyVal'}, "unique constraint keeps its case, quotes stripped");
    ok($mixed->unique->{'MyId'}, "primary key recorded as unique");

    my ($pk_idx) = grep { $_->{columns} && @{$_->{columns}} == 1 && $_->{columns}[0] eq 'MyId' } @{$mixed->indexes};
    ok($pk_idx, "index on the mixed-case PK column introspected") or return;
    ok($pk_idx->{unique}, "PK index introspected as unique");
};

subtest search_path_first_match_wins => sub {
    my $dupe = $schema->maybe_table('dupe');
    ok($dupe, "colliding table name introspected once") or return;

    is([$dupe->column_names], ['app_col'], "the app schema's table won (search_path order)");
    is($dupe->primary_key, ['app_col'], "constraints come from the winning schema's table");
};

done_testing;
