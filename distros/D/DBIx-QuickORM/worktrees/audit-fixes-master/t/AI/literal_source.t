use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises DBIx::QuickORM::LiteralSource: the Role::Source interface it
# implements, construction from a plain string vs a scalar reference, and
# (where the SQL builder can use it) querying through a connection.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;
require DBIx::QuickORM::LiteralSource;

subtest construction => sub {
    # A plain string is wrapped in a scalar reference and blessed.
    my $str = DBIx::QuickORM::LiteralSource->new("SELECT * FROM users");
    isa_ok($str, ['DBIx::QuickORM::LiteralSource'], "constructed from a plain string");
    is($str->source_db_moniker, "SELECT * FROM users",
        "source_db_moniker returns the SQL verbatim when built from a string");

    # An existing scalar reference is copied, not blessed in place.
    my $sql = "SELECT 1 AS a";
    my $ref = DBIx::QuickORM::LiteralSource->new(\$sql);
    isa_ok($ref, ['DBIx::QuickORM::LiteralSource'], "constructed from a scalar reference");
    is($ref->source_db_moniker, "SELECT 1 AS a",
        "source_db_moniker returns the referenced SQL");
    ok(!ref($sql), "new() does not bless the caller's scalar ref in place");
    is($sql, "SELECT 1 AS a", "caller's variable is left untouched");

    # Non-scalar references are rejected.
    like(dies { DBIx::QuickORM::LiteralSource->new({}) },
        qr/is not a scalar reference/, "a hashref is rejected");
    like(dies { DBIx::QuickORM::LiteralSource->new([]) },
        qr/is not a scalar reference/, "an arrayref is rejected");

    # The subquery option wraps the SQL as a derived table.
    my $named = DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => 'x');
    is($named->source_db_moniker, "( SELECT 1 ) AS x",
        "subquery => 'x' wraps as a derived table aliased x");

    my $defaulted = DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => 1);
    is($defaulted->source_db_moniker, "( SELECT 1 ) AS subquery",
        "subquery => 1 uses the default alias");

    my $empty = DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => '');
    is($empty->source_db_moniker, "( SELECT 1 ) AS subquery",
        "subquery => '' uses the default alias, not an empty one");

    like(
        dies { DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => 0) },
        qr/not a valid identifier/,
        "subquery => 0 croaks instead of emitting an invalid 'AS 0'",
    );
};

subtest role_source_interface => sub {
    my $ls = DBIx::QuickORM::LiteralSource->new("SELECT * FROM users");

    ok($ls->DOES('DBIx::QuickORM::Role::Source'), "implements the Role::Source role");

    is($ls->source_orm_name, 'LITERAL', "source_orm_name is 'LITERAL'");
    is($ls->source_db_moniker, "SELECT * FROM users", "source_db_moniker is the raw SQL");

    ok(!$ls->cachable, "a literal source is not cachable");

    is($ls->fields_to_fetch, ['*'], "fields_to_fetch is ['*']");
    is($ls->fields_list_all, ['*'], "fields_list_all is ['*']");

    is($ls->field_affinity('anything'), 'string', "field_affinity is always 'string'");

    # The remaining metadata accessors carry nothing for a literal source.
    is($ls->primary_key,    undef, "no primary key");
    is($ls->row_class,      undef, "no row class");
    is($ls->field_type('x'), undef, "no field type");
    is($ls->fields_to_omit, undef, "no fields to omit");
    is($ls->has_field('x'), undef, "has_field reports nothing");
};

subtest query_through_connection => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/literal.sqlite";

    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE people (id INTEGER PRIMARY KEY, surname TEXT)');
        $dbh->do("INSERT INTO people (surname) VALUES ('smith'), ('jones')");
        $dbh->disconnect;
    }

    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

    # $con->source(\$sql) builds a LiteralSource.
    my $sql = "people";
    my $src = $con->source(\$sql);
    isa_ok($src, ['DBIx::QuickORM::LiteralSource'], "con->source(\\\$sql) builds a LiteralSource");

    # The SQL builder splices the moniker in after FROM, so a literal source
    # works as a FROM fragment (e.g. a table name). It is NOT a full
    # standalone SELECT statement.
    my @rows = $con->handle($src)->data_only->all;
    is(scalar(@rows), 2, "queried the literal (FROM-fragment) source");
    is(
        [sort map { $_->{surname} } @rows],
        ['jones', 'smith'],
        "rows came back from the literal source query",
    );

    # A full SELECT statement can be queried when wrapped as a subquery: the
    # builder emits "SELECT * FROM ( <sql> ) AS <alias>".
    my $sub = DBIx::QuickORM::LiteralSource->new(
        "SELECT surname FROM people WHERE surname = 'smith'",
        subquery => 'only_smith',
    );
    is(
        $sub->source_db_moniker,
        "( SELECT surname FROM people WHERE surname = 'smith' ) AS only_smith",
        "subquery moniker is wrapped as a derived table",
    );
    my @sub_rows = $con->handle($sub)->data_only->all;
    is(
        [map { $_->{surname} } @sub_rows],
        ['smith'],
        "queried a full statement via the subquery wrapping",
    );

    # Documented contract: handle() does NOT accept a scalar ref directly the
    # way source() does; you must build the source first. (See the POD for
    # Connection::handle and Handle's constructor args.)
    like(
        dies { $con->handle(\$sql) },
        qr/Not sure what to do with 'SCALAR/,
        "handle(\\\$sql) throws; build the source first via source(\\\$sql)",
    );
};

done_testing;
