use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A database handle of each kind, each with the same table and rows.
my %h = (
    dbi      => DBI->connect(@source),
    squirrel => DBIx::Squirrel->connect(@source),
);
for my $h (values %h) {
    $h->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $h->do('INSERT INTO artist (name) VALUES (?)', undef, $_)
        for qw(Abba Blur Cream Doors Eagles);
}
my($dbh, $dbi) = @h{qw(squirrel dbi)};

# The names of the artists a statement selects, given its bind values.
sub names ($statement, @values) {
    return $dbh->selectcol_arrayref($statement, undef, @values);
}

# A pattern matching a message raised at a line of this file.
sub at_line ($message, $line) {
    return qr( \A \Q$message\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )x;
}

subtest 'a list placeholder in each style gives the rows the DBI gives' => sub {
    my $want = $dbi->selectcol_arrayref(
        'SELECT name FROM artist WHERE id IN (?, ?, ?) ORDER BY id',
        undef, 1, 3, 5,
    );
    my @ids = (1, 3, 5);
    for my $case (
        ['...?',    [@ids]],
        ['...?1',   [@ids]],
        ['...:1',   [@ids]],
        ['...$1',   [@ids]],
        ['...:ids', ids => [@ids]],
        ['...$ids', ids => [@ids]],
        ['...:ids', {ids => [@ids]}],
    ) {
        my($p, @values) = @$case;
        is names("SELECT name FROM artist WHERE id IN ($p) ORDER BY id", @values),
            $want, $p;
    }
};

subtest 'a list of one value' => sub {
    is names('SELECT name FROM artist WHERE id IN (...:ids)', ids => [2]),
        ['Blur'], 'is a list';
};

subtest 'the statement the DBI sees' => sub {
    my $it = $dbh->iterate(
        q{SELECT '...:x', name FROM artist /* ...:y */ WHERE id IN (...:ids)},
        ids => [1, 2, 3],
    );
    is $it->sth->{Statement},
        q{SELECT '...:x', name FROM artist /* ...:y */ WHERE id IN (?, ?, ?)},
        'a "?" for each value, and "..." outside SQL left as it is';
    is $it->sth->{NUM_OF_PARAMS}, 3, 'binding each value';
};

subtest 'with other placeholders' => sub {
    is names(
        'SELECT name FROM artist WHERE id > ? AND id IN (...?) AND id < ? ORDER BY id',
        1, [1, 2, 3, 4, 5], 5,
        ),
        [qw(Blur Cream Doors)], '? on either side';
    is names(
        'SELECT name FROM artist WHERE id IN (...?) AND name <> ? ORDER BY id',
        [[2, 3], 'Blur'],
        ),
        ['Cream'], 'in an array reference, taking more than one value';
    is names(
        'SELECT name FROM artist WHERE name <> $2 AND id IN (...$1) ORDER BY id',
        [2, 3], 'Cream',
        ),
        ['Blur'], 'numbered, out of order';
    is names(
        'SELECT name FROM artist WHERE name <> :name AND id IN (...:ids) ORDER BY id',
        name => 'Abba', ids => [1, 4],
        ),
        ['Doors'], 'named';
};

subtest 'a list used twice' => sub {
    my $sql
        = 'SELECT name FROM artist WHERE id IN (%s) OR CAST(id + 1 AS TEXT) IN (%s)';
    is names(sprintf($sql, ('...:ids') x 2), ids => [3, 5]),
        $dbi->selectcol_arrayref(sprintf($sql, ('?, ?') x 2), undef, 3, 5, 3, 5),
        'takes its values in both places';
};

subtest 'each method that prepares a statement with its values' => sub {
    my $dbi_sql = 'SELECT id, name FROM artist WHERE id IN (?, ?) ORDER BY id';
    my $sql     = 'SELECT id, name FROM artist WHERE id IN (...:ids) ORDER BY id';
    my @ids     = (2, 4);
    for my $method (qw(
        selectrow_array    selectrow_arrayref selectrow_hashref
        selectall_arrayref selectcol_arrayref selectall_array))
    {
        is [$dbh->$method($sql, ids => [@ids])],
            [$dbi->$method($dbi_sql, undef, @ids)], $method;
    }
    is $dbh->selectall_hashref($sql, 'id', ids => [@ids]),
        $dbi->selectall_hashref($dbi_sql, 'id', undef, @ids), 'selectall_hashref';
    is [$dbh->iterate($sql, ids => [@ids], sub ($row) { $row->[1] })->all],
        [qw(Blur Doors)], 'iterate';
    is [map { $_->name }
            $dbh->results($sql, {ekorn_slice => {}}, ids => [@ids])->all],
        [qw(Blur Doors)], 'results, with attributes';
    is [$dbh->iterate($sql, ids => [@ids])->all],
        $dbi->selectall_arrayref($dbi_sql, undef, @ids), 'iterate, without stages';
    is $dbh->do(
        'UPDATE artist SET name = upper(name) WHERE id IN (...:ids)',
        undef, ids => [@ids],
        ),
        2, 'do, counting the rows changed';
    is names(
        'SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id',
        ids => [@ids],
        ),
        [qw(BLUR DOORS)], 'and changing them';
    $dbh->do('UPDATE artist SET name = ? WHERE id = ?', undef, @$_)
        for [Blur => 2], [Doors => 4];
};

subtest 'prepare and prepare_cached, without the values' => sub {
    my $sql  = 'SELECT name FROM artist WHERE id IN (...:ids)';
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->prepare($sql) };
    like $err,
        at_line(
            'Expected bind values with a statement taking a list (...:ids)',
            $line,
        ),
        'prepare croaks, at the caller';
    $line = __LINE__ + 1;
    $err  = dies { $dbh->prepare_cached('SELECT ...?, ...?') };
    like $err, at_line(
        'Expected bind values with a statement taking a list (...? at 1, ...? at 2)',
        $line,
        ),
        'so does prepare_cached, naming each ? by its position';
};

subtest 'the values a list takes' => sub {
    my $sql = 'SELECT name FROM artist WHERE id IN (...:ids)';
    for my $case (
        [[], 'Expected at least one value in a list (...:ids)',       'an empty list'],
        [1,  'Expected a reference to an ARRAY for a list (...:ids)', 'a value'],
        [undef, 'Expected a reference to an ARRAY for a list (...:ids)', 'undef'],
        [
            {a => 1}, 'Expected a reference to an ARRAY for a list (...:ids)',
            'a reference to a HASH',
        ],
        [[1, [2]], 'Expected plain values in a list (...:ids)', 'a list in a list'],
    ) {
        my($list, $message, $name) = @$case;
        my $err = dies { names($sql, ids => $list) };
        like $err, qr( \A \Q$message\E \ at\ )x, "$name croaks";
    }
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->selectall_arrayref($sql, ids => []) };
    like $err,
        at_line('Expected at least one value in a list (...:ids)', $line),
        'at the caller';

    $err
        = dies { names('SELECT name FROM artist WHERE id IN (...?)', [[1, 2]]) };
    like $err, qr( \A \QExpected plain values in a list (...? at 1)\E )x,
        'a list in an array reference, to a statement taking one value';
    $err = dies { names('SELECT name FROM artist WHERE id IN (...:ids)') };
    like $err,
        qr( \A \QExpected a value for each placeholder (none for ids)\E )x,
        'no value at all';
};

subtest 'a placeholder takes a list everywhere or nowhere' => sub {
    my $sql  = 'SELECT :a, :b WHERE 1 IN (...:a) OR 2 IN (...:b)';
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->selectall_arrayref($sql, a => [1], b => [2]) };
    like $err,
        at_line(
            'Expected a placeholder to take a list everywhere or nowhere (:a, :b)',
            $line,
        ),
        'croaks, naming each';
    my $message
        = 'Expected a placeholder to take a list everywhere or nowhere ($1)';
    like dies { $dbh->prepare('SELECT $1 WHERE 1 IN (...$1)') },
        qr( \A \Q$message\E )x, 'even before the values';
};

subtest 'the statement handle of a list' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id',
        ids => [1, 2],
    );
    my $sth = $it->sth;
    $sth->execute(ids => [3, 4]);
    is $sth->fetchall_arrayref, [['Cream'], ['Doors']],
        'executes again with as many values';
    $sth->bind(ids => [5, 1]);
    $sth->execute;
    is $sth->fetchall_arrayref, [['Abba'], ['Eagles']], 'binds them';
    ok $sth->bind_param(':ids', [2, 3]), 'binds them one by one';
    $sth->execute;
    is $sth->fetchall_arrayref, [['Blur'], ['Cream']], 'with bind_param';
    my $line = __LINE__ + 1;
    my $err  = dies { $sth->execute(ids => [1, 2, 3]) };
    like $err,
        at_line('Expected 2 values in a list, as prepared, not 3 (...:ids)', $line),
        'croaks given another number of them';
    like dies { $sth->bind_param('ids', 1) },
        qr( \A \QExpected a reference to an ARRAY for a list (...:ids)\E )x,
        'or a value for the list';
};

subtest 'an iterator prepares again for a list of another length' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id',
        ids => [1, 2],
        sub ($row) { $row->[0] },
    );
    is [$it->all], [qw(Abba Blur)], 'the first list';
    my $first = $it->sth;
    is [$it->reset(ids => [3, 4])->all], [qw(Cream Doors)], 'as many again';
    ref_is $it->sth, $first, 'on the same statement handle';
    is [$it->reset(ids => [5, 4, 3])->all], [qw(Cream Doors Eagles)], 'more';
    ref_is_not $it->sth, $first, 'on a new statement handle';
    is $it->sth->{Statement},
        'SELECT name FROM artist WHERE id IN (?, ?, ?) ORDER BY id',
        'prepared for them';
    is [$it->reset->all], [qw(Cream Doors Eagles)],
        'and keeps them, as the values given last';
    is $it->reset(ids => [1])->single, 'Abba', 'single';

    my $results = $dbh->results(
        'SELECT name FROM artist WHERE id IN (...?) ORDER BY id', [1, 2],
    );
    is [map { $_->name } $results->all], [qw(Abba Blur)], 'results';
    is [map { $_->name } $results->reset([5])->all], ['Eagles'],
        'results, prepared again';

    like dies { $it->reset(ids => []) },
        qr( \A \QExpected at least one value in a list (...:ids)\E )x,
        'croaking at an empty list';
};

subtest 'the statement handle of a list, iterated without values' => sub {
    my $sth = $dbh->iterate(
        'SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id',
        ids => [4, 5],
    )->sth;
    $sth->execute(ids => [1, 2]);
    $sth->finish;
    my @names = $sth->iterate(sub ($row) {
        $row->[0];
    })->all;
    is \@names, [qw(Abba Blur)], 'executes with the values bound last';
};

subtest 'a statement that cannot be prepared' => sub {
    my $quiet = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    my $sql = 'SELEC 1 WHERE 1 IN (...:ids)';
    is $quiet->selectall_arrayref($sql, ids => [1]), undef,
        'the select methods return what the DBI returns, without RaiseError';
    is $quiet->do($sql, undef, ids => [1]), undef, 'so does do';
    my $line = __LINE__ + 1;
    my $err  = dies { $quiet->iterate($sql, ids => [1]) };
    like $err, qr( \A DBD::SQLite::db\ prepare\ failed:\ .*syntax\ error
        .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )xs,
        'iterate croaks, as prepare does';

    # More values than SQLite takes in one statement.
    my $it = $quiet->iterate(q{SELECT 1 WHERE '1' IN (...?)}, [1]);
    is [$it->all], [[1]], 'a list SQLite takes';
    $line = __LINE__ + 1;
    $err  = dies { $it->reset([1 .. 40_000]) };
    like $err,
        qr( \A DBD::SQLite::db\ prepare\ failed:\ too\ many\ SQL\ variables
        .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )xs,
        'and a list too long for it croaks, when an iterator prepares again';
};

subtest 'a single array reference' => sub {

    # No other driver here, so a hash stands in for the statement handle:
    # _unwrap reads only its driver, and what prepare kept.
    my sub sth ($driver, $binds, $lists = undef) {
        return {
            Database      => {Driver => {Name => $driver}},
            private_ekorn => {Binds  => $binds, Lists => $lists},
        };
    }
    my $unwrap = \&DBIx::Squirrel::st::_unwrap;    ## no critic (Variables::ProtectPrivateVars)
    my $array  = [1, 2];
    is [$unwrap->(sth('ODBC', {1 => [1, 2]}, {1 => '...?1'}), $array)],
        [$array],
        'is the list, to a statement taking one value, a list';
    is [$unwrap->(sth('ODBC', {1 => [1], 2 => [2]}, {1 => '...?1'}), $array)],
        [1, 2], 'stands for its values, to one taking two';
    is [$unwrap->(sth('ODBC', {1 => [1, 2]}), $array)], [1, 2],
        'as it does without a list';
};

done_testing;
