#!/usr/bin/perl -w

 use strict;
 use warnings;

 use Test::More tests => 23;
 use DBIx::Lite;

 my $dbix = DBIx::Lite->new(driver_name => 'Pg');

{
    my ($sql) = eval { $dbix->table('authors')->select('id')->select_sql };
    ok !$@, 'no exception thrown';
    if ($@) {
        diag $@;
    }
    is $sql, 'SELECT me.id FROM authors AS me', 'simple select';
}

{
    my ($sql) = $dbix->table('authors')->select_sql;
    is $sql, 'SELECT me.* FROM authors AS me', 'basic';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct->select_sql;
    is $sql, 'SELECT DISTINCT me.id FROM authors AS me', 'distinct';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct('name')->select_sql;
    is $sql, 'SELECT DISTINCT ON (name) me.id FROM authors AS me', 'distinct on';
}

{
    my ($sql) = $dbix->table('authors')->select('id')->distinct(\'lower(name)')->select_sql;
    is $sql, 'SELECT DISTINCT ON (lower(name)) me.id FROM authors AS me', 'distinct on with expression';
}

{
    my ($sql) = $dbix->table('authors')->table_alias('target')->select('id')->select_sql;
    is $sql, 'SELECT target.id FROM authors AS target', 'custom table alias';
}

{
    # Table names can be SQL expressions (e.g. unnest(CASE ... '{null}' ...)).
    # Joining must not interpolate them into a regex unescaped (Perl 5.42+ warns).
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    my $table = q{unnest(CASE WHEN me.arr <> '{}' THEN me.arr ELSE '{null}' END)};
    my ($sql) = $dbix->table($table)
        ->table_alias('_conn_id')
        ->left_join(['other' => 'o'], { '_conn_id' => 'o.id' })
        ->select(\'1')
        ->select_sql;
    unlike $warnings, qr/Unescaped left brace/,
        'join with brace-containing table name does not warn';
    like $sql, qr/unnest\(CASE/, 'select_sql still emits the expression table';
}

{
    # ARRAY[NULL]::integer[] embeds '[' / ']' — without quotemeta this is a
    # hard "Unmatched [" regex error (worse than the brace warning).
    my $err;
    my $table = q{unnest(CASE WHEN cardinality(me.arr) > 0 THEN me.arr ELSE ARRAY[NULL]::integer[] END)};
    my ($sql) = eval {
        $dbix->table($table)
            ->table_alias('_conn_id')
            ->left_join(['other' => 'o'], { '_conn_id' => 'o.id' })
            ->select(\'1')
            ->select_sql;
    };
    $err = $@;
    is $err, '', 'join with ARRAY[NULL]::integer[] table name does not die'
        or diag $err;
    like $sql // '', qr/ARRAY\[NULL\]::integer\[\]/,
        'select_sql still emits ARRAY[NULL] table expr';
}

{
    my ($sql) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->select('id')
        ->select_sql;
    is $sql, 'WITH t AS (SELECT 1 AS id) SELECT me.id FROM authors AS me', 'select with CTE';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id, 'Larry' AS name")
        ->insert_sql({ id => 1, name => 'Larry' });
    is $sql, q{WITH t AS (SELECT 1 AS id, 'Larry' AS name) INSERT INTO authors ( id, name) VALUES ( ?, ? )},
        'insert with CTE';
    is_deeply \@bind, [1, 'Larry'], 'insert with CTE bind values';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(target => \["SELECT * FROM authors WHERE id = ?", 42])
        ->from('target')
        ->insert_sql({
            name  => \["(SELECT me.name FROM authors AS me WHERE me.id = target.id)"],
            email => 'copy@example.com',
        });
    is $sql,
        q{WITH target AS (SELECT * FROM authors WHERE id = ?) INSERT INTO authors ( email, name) SELECT ?, (SELECT me.name FROM authors AS me WHERE me.id = target.id) FROM target},
        'insert with CTE and from uses SELECT';
    is_deeply \@bind, [42, 'copy@example.com'],
        'insert with CTE and from bind order';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->from('target')
        ->insert_sql({
            id   => 1,
            name => \"target.name",
        });
    is $sql,
        q{INSERT INTO authors ( id, name) SELECT ?, target.name FROM target},
        'insert from without CTE';
    is_deeply \@bind, [1], 'insert from without CTE binds';
}

{
    eval {
        $dbix->table('authors')->from('target')->insert_sql({});
    };
    like $@, qr/insert\(\) with from\(\) requires a non-empty hashref/,
        'insert with from and empty hash croaks';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->search({ id => 1 })
        ->update_sql({ name => 'Larry' });
    is $sql, 'WITH t AS (SELECT 1 AS id) UPDATE authors SET name = ? WHERE ( id = ? )',
        'update with CTE';
    is_deeply \@bind, ['Larry', 1], 'update with CTE bind values';
}

{
    my ($sql, @bind) = $dbix->table('authors')
        ->with(t => \"SELECT 1 AS id")
        ->search({ id => 1 })
        ->delete_sql;
    is $sql, 'WITH t AS (SELECT 1 AS id) DELETE FROM authors WHERE ( id = ? )',
        'delete with CTE';
    is_deeply \@bind, [1], 'delete with CTE bind values';
}

 __END__