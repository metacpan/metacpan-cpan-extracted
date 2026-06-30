use Test2::V0 '!meta', '!pass';
use File::Temp qw/tempdir/;
use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::LiteralSource;

# Regression coverage for CVE-2026-13766: identifiers reaching the SQL string
# (order_by, where-clause keys, field/returning lists, upsert column keys, join
# aliases, count-distinct columns) must be quoted so an attacker-influenceable
# name cannot break out of its identifier slot into raw SQL. Values were always
# placeholder-bound and are not the concern here.

my $dir    = tempdir(CLEANUP => 1);
my $dbfile = "$dir/sqli.db";

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, secret TEXT)');
    $dbh->do("INSERT INTO users (id, name, secret) VALUES (1,'alice','public'),(2,'bob','public'),(3,'admin','SECRET')");

    # Reserved-word column names: invalid SQL unless quoted at every use.
    $dbh->do('CREATE TABLE widgets (id INTEGER PRIMARY KEY, "order" TEXT, "select" TEXT)');
    $dbh->do(qq{INSERT INTO widgets (id, "order", "select") VALUES (1, 'a', 'b')});

    # Reserved-word PRIMARY KEY column, to exercise COUNT(DISTINCT ...).
    $dbh->do('CREATE TABLE evt ("order" INTEGER PRIMARY KEY, note TEXT)');
    $dbh->do(qq{INSERT INTO evt ("order", note) VALUES (1,'x'),(2,'y')});

    # A second table for a cross join.
    $dbh->do('CREATE TABLE tags (id INTEGER PRIMARY KEY, label TEXT)');
    $dbh->do("INSERT INTO tags (id, label) VALUES (1,'a'),(2,'b')");
    $dbh->disconnect;
}

db mydb => sub {
    dialect 'SQLite';
    db_name 'main';
    connect sub { DBI->connect("dbi:SQLite:dbname=$dbfile", '', '', {RaiseError => 1, PrintError => 0}) };
};

orm my_orm => sub {
    db 'mydb';
    autofill;
};

my $con = orm('my_orm')->connect;

# The blind-boolean order_by exfiltration from the CVE proof-of-concept: an
# attacker who only controls the sort column tries to read a never-selected
# column by making the row order depend on a sub-select over it.
subtest order_by_injection_is_inert => sub {
    my $probe = sub {
        my ($like) = @_;
        my $payload = "(CASE WHEN (SELECT secret FROM users WHERE name='admin') LIKE '$like' THEN id ELSE -id END)";
        my @rows = $con->handle('users')->fields(['id', 'name'])->order_by($payload)->all;
        return join(',', map { $_->field('id') } @rows);
    };

    my ($true_order, $false_order);
    my $ran = eval { $true_order = $probe->('S%'); $false_order = $probe->('Z%'); 1 };

    if ($ran) {
        # Quoted, the payload is a dead/inert identifier, so both probes order
        # the same way -- the sub-select never runs, so nothing leaks.
        is($true_order, $false_order,
            "order_by payload cannot make row order depend on the secret (no blind SQLi)");
    }
    else {
        # Or the database rejects the quoted identifier outright -- also safe.
        ok(1, "order_by payload rejected by the database (no SQLi): $@");
    }
};

# Identifier positions come out quoted in the generated SQL, so a crafted name
# is one dead identifier rather than executable SQL.
subtest identifiers_are_quoted => sub {
    my $builder = $con->default_sql_builder;
    my $source  = $con->handle('users')->source;
    my $payload = "id) OR (1=1";

    my $by_order = $builder->qorm_select(source => $source, fields => ['id'], order_by => $payload);
    like($by_order->{statement},   qr/"id\) OR \(1=1"/, "malicious order_by becomes a single quoted identifier");
    unlike($by_order->{statement}, qr/ORDER BY id\) OR \(1=1/, "malicious order_by is not emitted as raw SQL");

    my $by_where = $builder->qorm_select(source => $source, fields => ['id'], where => {$payload => 1});
    like($by_where->{statement}, qr/"id\) OR \(1=1"/, "malicious where key becomes a single quoted identifier");

    my $by_field = $builder->qorm_select(source => $source, fields => [$payload]);
    like($by_field->{statement}, qr/"id\) OR \(1=1"/, "malicious field name becomes a single quoted identifier");
};

# Upsert builds its conflict SET clause by hand, after SQL::Abstract has run, so
# it must quote its own identifiers. A reserved-word column proves it does.
subtest upsert_reserved_word_columns => sub {
    my $h = $con->handle('widgets');
    my $row;
    ok(lives { $row = $h->upsert({id => 1, order => 'A', select => 'B'}) },
        "upsert with reserved-word columns produces valid SQL")
        or note $@;
    is($row->field('order'),  'A', "reserved-word column 'order' updated");
    is($row->field('select'), 'B', "reserved-word column 'select' updated");
};

# COUNT(DISTINCT <pk>) interpolates the primary-key column by hand; a
# reserved-word PK must be quoted.
subtest count_distinct_reserved_pk => sub {
    my $n;
    ok(lives { $n = $con->handle('evt')->distinct->count },
        "count(distinct) over a reserved-word primary key produces valid SQL")
        or note $@;
    is($n, 2, "distinct count over the reserved-word PK is correct");
};

# A join alias is caller-supplied and interpolated into the FROM/ON SQL, so it
# must be quoted. An alias that requires quoting (contains a space) proves it.
subtest join_alias_is_quoted => sub {
    my $h       = $con->handle('users')->cross_join('tags', as => 'odd alias');
    my $moniker = ${$h->source->source_db_moniker};
    like($moniker, qr/AS "odd alias"/, "join alias is quoted in the FROM clause");

    my @rows;
    ok(lives { @rows = $h->data_only->all }, "the quoted-alias join runs") or note $@;
    is(scalar(@rows), 6, "cross join yields the full cartesian product (3 x 2)");
};

# The quote_char change would corrupt a literal-source subquery FROM target
# ('FROM "( SELECT ... )"') unless the moniker is emitted as literal SQL.
subtest literal_source_subquery_through_connection => sub {
    my $sub = DBIx::QuickORM::LiteralSource->new(
        "SELECT name FROM users WHERE name = 'admin'",
        subquery => 'only_admin',
    );
    my @rows;
    ok(lives { @rows = $con->handle($sub)->data_only->all },
        "a literal-source subquery still queries through the builder")
        or note $@;
    is([map { $_->{name} } @rows], ['admin'], "subquery returned the expected row");
};

# The literal-source subquery alias has no dbh to quote it, so a non-identifier
# alias is rejected rather than allowed to break out into the SQL.
subtest literal_source_bad_alias_croaks => sub {
    like(
        dies { DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => 'bad) AS x; DROP') },
        qr/is not a valid identifier/,
        "a non-identifier subquery alias croaks",
    );
    ok(lives { DBIx::QuickORM::LiteralSource->new("SELECT 1", subquery => 'good_alias') },
        "a plain-identifier subquery alias is accepted");
};

done_testing;
