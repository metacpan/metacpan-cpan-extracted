use strict;
use warnings;

use Test::More;

my ($dsn) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

LiveServer->require_server;

# LIVE test for karr k153: what the introspection reads of a trigger's
# function and arguments (pg_trigger.tgfoid, tgargs) is the call a generated
# Result class redeploys, without a pattern over pg_get_triggerdef.
#
# Claim: the `execute` of a trigger entry is the function as the server names
# it and every argument as a string literal, whatever the argument holds -- a
# quote, a semicolon, the words of the clause itself, a long run of blanks --
# and the Result class generator hands it on as it is.

my $SCHEMA = 'dbio_k153_live';
my $BLANKS = ' ' x 16_000;

my $dbh = LiveServer->control_dbh;
$dbh->do(qq{DROP SCHEMA IF EXISTS $SCHEMA CASCADE});
$dbh->do(qq{CREATE SCHEMA $SCHEMA});

END {
  if ($dbh && $dbh->{Active}) {
    local $dbh->{RaiseError} = 0;
    $dbh->do(qq{DROP SCHEMA IF EXISTS $SCHEMA CASCADE});
  }
}

$dbh->do(qq{CREATE TABLE $SCHEMA.thing (id integer, name text)});
$dbh->do(qq{CREATE FUNCTION $SCHEMA.touch() RETURNS trigger LANGUAGE plpgsql AS \$\$ BEGIN RETURN NEW; END \$\$});
$dbh->do(qq{CREATE FUNCTION $SCHEMA."Odd Name"() RETURNS trigger LANGUAGE plpgsql AS \$\$ BEGIN RETURN NEW; END \$\$});
$dbh->do(qq{CREATE TRIGGER t_plain BEFORE INSERT ON $SCHEMA.thing FOR EACH ROW EXECUTE FUNCTION $SCHEMA.touch()});
$dbh->do(qq{CREATE TRIGGER t_odd BEFORE UPDATE ON $SCHEMA.thing FOR EACH ROW EXECUTE FUNCTION $SCHEMA."Odd Name"()});
$dbh->do(qq{CREATE TRIGGER t_args AFTER INSERT ON $SCHEMA.thing FOR EACH ROW EXECUTE FUNCTION $SCHEMA.touch('a', 'it''s', 'x;', 'EXECUTE FUNCTION g(1)', '')});
$dbh->do(qq{CREATE TRIGGER t_blanks AFTER DELETE ON $SCHEMA.thing FOR EACH ROW EXECUTE FUNCTION $SCHEMA.touch('$BLANKS')});

my $intro = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => [$SCHEMA]);
my $triggers = $intro->model->{triggers}{"$SCHEMA.thing"};

is $triggers->{t_plain}{execute}, "$SCHEMA.touch()", 'a function without arguments';
is $triggers->{t_odd}{execute}, qq{$SCHEMA."Odd Name"()}, 'a function name that needs quoting';
is $triggers->{t_args}{execute},
  qq{$SCHEMA.touch('a', 'it''s', 'x;', 'EXECUTE FUNCTION g(1)', '')},
  'arguments as string literals, a quote doubled, an empty one kept';
is $triggers->{t_blanks}{execute}, "$SCHEMA.touch('$BLANKS')", 'an argument of 16 000 blanks';

my %by_name = map { $_->[1] => $_->[2] }
  grep { $_->[0] eq 'pg_trigger' } $intro->result_class_extra_statements("$SCHEMA.thing");
is $by_name{t_args}{execute}, $triggers->{t_args}{execute},
  'the generator hands the call on as it is';

# the call is one the server reads back as the same trigger
$dbh->do(qq{DROP TRIGGER t_args ON $SCHEMA.thing});
$dbh->do(qq{CREATE TRIGGER t_args AFTER INSERT ON $SCHEMA.thing FOR EACH ROW EXECUTE FUNCTION } . $by_name{t_args}{execute});
my $again = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => [$SCHEMA]);
is $again->model->{triggers}{"$SCHEMA.thing"}{t_args}{execute}, $triggers->{t_args}{execute},
  'created again from that call, the trigger reads back the same';

done_testing;
