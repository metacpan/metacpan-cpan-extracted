use Test2::V0 '!meta', '!pass';
use lib 't/lib';

# PostgreSQL types the generic driver catalog does not list are resolved from
# pg_type during introspection:
#  - an enum (a user-defined type, reported as data_type 'USER-DEFINED') maps to
#    string affinity, and a domain inherits its base type's affinity;
#  - built-in scalar types the name-map lacks -- ranges, network, geometric --
#    also resolve to string (they come back from DBD::Pg as scalar strings), so
#    they no longer trip the "unrecognized type" warning;
#  - an array is deliberately left to warn: DBD::Pg expands it to an arrayref,
#    which string affinity's eq cannot compare, so it needs a proper Type.

BEGIN {
    skip_all "DBD::Pg is required for these tests"
        unless eval { require DBD::Pg; 1 };
}

use DBIx::QuickORM::Test qw/psql/;

my $db = psql() or skip_all "Could not provision a PostgreSQL database";

{
    my $dbh = $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1);
    $dbh->do("CREATE TYPE color AS ENUM ('red','green','blue')");
    $dbh->do("CREATE DOMAIN positive_int AS INTEGER");
    $dbh->do(<<'    EOT');
        CREATE TABLE swatches (
            id    SERIAL PRIMARY KEY,
            shade color        NOT NULL DEFAULT 'red',
            rank  positive_int,
            label TEXT,
            net   inet,
            spot  point,
            span  int4range,
            tags  integer[]
        )
    EOT
    $dbh->disconnect;
}

require DBIx::QuickORM;

my @warnings;
my $con;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $con = DBIx::QuickORM->quick(
        connect => sub { $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1) },
    );
    # Force introspection while the warning trap is in place.
    $con->schema;
}

my $s = $con->schema->table('swatches');

is($s->column('shade')->affinity, 'string',  "enum column resolves to string affinity");
is(${$s->column('shade')->type},  'color',   "enum column keeps its database type name");
is($s->column('rank')->affinity,  'numeric', "domain-over-integer column resolves to numeric affinity");
is($s->column('label')->affinity, 'string',  "plain text column resolves to string affinity");
is($s->column('net')->affinity,   'string',  "inet (network) column resolves to string affinity");
is($s->column('spot')->affinity,  'string',  "point (geometric) column resolves to string affinity");
is($s->column('span')->affinity,  'string',  "int4range (range) column resolves to string affinity");

my @type_warnings = grep { /does not recognize the database type/ } @warnings;

my @scalar_warned = grep { /'(?:color|inet|point|int4range)'/ } @type_warnings;
is(\@scalar_warned, [], "enum/domain/range/network/geometric types resolve without a warning")
    or diag("unexpected warnings: @scalar_warned");

ok((grep { /'_int4'/ } @type_warnings),
    "an array column still warns (DBD::Pg returns an arrayref; it needs a Type)")
    or diag("array warning missing; got: @type_warnings");

done_testing;
