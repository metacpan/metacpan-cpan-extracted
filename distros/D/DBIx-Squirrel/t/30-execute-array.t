use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI qw(SQL_INTEGER);
use DBIx::Squirrel;

# execute_array, execute_for_fetch and bind_param_array, for every style
# of placeholder (roadmap 2026-0037), compared with plain DBI wherever it
# has an answer.

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A database handle of the class given, with an empty table.
sub dbh ($class = 'DBIx::Squirrel', %attrs) {
    my $dbh = $class->connect(@source[0 .. 2], {%{ $source[3] }, %attrs});
    $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, again INTEGER)');
    return $dbh;
}

# The table's rows, in order.
sub rows ($dbh) {
    return $dbh->selectall_arrayref('SELECT id, name, again FROM t ORDER BY id');
}

# Matches a message given at a line of this file.
sub at_line ($message, $line) {
    return qr( \A \Q$message\E\ at\ \Q${\ __FILE__ }\E\ line\ $line \. \n \z )x;
}

my $NAMED    = 'INSERT INTO t (id, name, again) VALUES (:id, :name, :id)';
my $NUMBERED = 'INSERT INTO t (id, name, again) VALUES ($1, $2, $1)';

subtest 'execute_array gives what plain DBI does, in every style' => sub {
    for my $case (
        'INSERT INTO t (id, name) VALUES (?, ?)',
        'INSERT INTO t (id, name) VALUES ($1, $2)',
        'INSERT INTO t (id, name) VALUES (?1, ?2)',
        'INSERT INTO t (id, name) VALUES (:1, :2)',
        'INSERT INTO t (id, name) VALUES (:id, :name)',
        'INSERT INTO t (id, name) VALUES ($id, $name)',
        $NAMED,
        $NUMBERED,
        # Names in the order each first appears, as DBD::SQLite takes them.
        ['INSERT INTO t (name, id) VALUES (:name, :id)', ['a', 'b'], [1, 2]],
    ) {
        my($sql, @arrays) = ref $case ? @$case : ($case, [1, 2], ['a', 'b']);
        my($dbi, $ours)   = (dbh('DBI'), dbh());
        my @want = $dbi->prepare($sql)->execute_array({}, @arrays);
        my @got  = $ours->prepare($sql)->execute_array({}, @arrays);
        is \@got,       \@want,        "$sql: what it returns, in list context";
        is rows($ours), rows($dbi),    "$sql: the rows";
        is scalar @{ rows($ours) }, 2, "$sql: two of them";
        my $count
            = dbh()->prepare($sql)->execute_array({}, map { [$_->[0]] } @arrays);
        is $count, 1, "$sql: how many, in scalar context";
    }
};

subtest 'values in order: by number, or as names first appear' => sub {
    my $dbh = dbh();
    $dbh->prepare('INSERT INTO t (again, name, id) VALUES (:id, :name, :id)')
        ->execute_array({}, [1], ['a']);
    $dbh->prepare('INSERT INTO t (name, id) VALUES ($2, $1)')
        ->execute_array({}, [2], ['b']);
    is rows($dbh), [[1, 'a', 1], [2, 'b', undef]],
        'each value where it belongs';
};

subtest 'execute_for_fetch takes arrays, and hashes for names' => sub {
    my $dbh  = dbh();
    my $sth  = $dbh->prepare($NAMED);
    my @rows = ([1, 'a'], {id => 2, name => 'b'}, {':id' => 3, '$name' => 'c'});
    my @status;
    is [$sth->execute_for_fetch(sub { shift @rows }, \@status)], [3, 3],
        'the tuples and rows changed, in list context';
    is \@status, [1, 1, 1], 'with the status of each';
    is rows($dbh), [[1, 'a', 1], [2, 'b', 2], [3, 'c', 3]], 'each row';

    @rows = ([4, 'd'], [5, 'e']);
    is scalar dbh()->prepare($NUMBERED)->execute_for_fetch(sub { shift @rows }),
        2,
        'numbered, from arrays';

    is dbh()->prepare($NAMED)->execute_for_fetch(sub { return }), '0E0',
        'no rows, as the DBI gives it';
};

subtest 'bind_param_array takes names' => sub {
    my $dbh = dbh();
    my $sth = $dbh->prepare($NAMED);
    ok $sth->bind_param_array(':id', [1, 2]), 'by name, with its sigil';
    ok $sth->bind_param_array('name', 'same'),
        'without, and a value for every row';
    is scalar $sth->execute_array({}), 2, 'executes for the longest array';
    is rows($dbh),                     [[1, 'same', 1], [2, 'same', 2]], 'the rows';

    $sth = $dbh->prepare($NUMBERED);
    ok $sth->bind_param_array(1,    [3]),   'by number';
    ok $sth->bind_param_array('$2', ['c']), 'with its sigil';
    $sth->execute_array({});
    is rows($dbh)->[-1], [3, 'c', 3], 'numbered';

    $sth = $dbh->prepare($NAMED);
    ok $sth->bind_param_array('id', [4], {TYPE => SQL_INTEGER}),
        'with attributes, bound to every use';
    $sth->bind_param_array('name', ['d']);
    $sth->execute_array({});
    is rows($dbh)->[-1], [4, 'd', 4], 'the row';

    my $line = __LINE__ + 1;
    like dies { $sth->bind_param_array('nope', [1]) },
        at_line('Expected a placeholder of the statement (nope)', $line),
        'croaks for a name the statement has not';
    like dies { $sth->bind_param_array(1, [1]) },
        qr( \A \QExpected a placeholder of the statement (1)\E )x,
        'or a number, for named placeholders';
    like dies { $sth->bind_param_array('id', {}) },
        qr( \A \QDBD::SQLite::st bind_param_array failed: Value for parameter id must be a scalar or an arrayref, not a HASH\E )x,
        "the DBI's message, for a value that's neither";
};

subtest 'ArrayTupleFetch and ArrayTupleStatus' => sub {
    my $dbh  = dbh();
    my $sth  = $dbh->prepare($NAMED);
    my @rows = ({id => 1, name => 'a'}, [2, 'b']);
    my @status;
    is scalar $sth->execute_array({
        ArrayTupleFetch => sub { shift @rows }, ArrayTupleStatus => \@status,
        }),
        2, 'from a code reference';
    is \@status, [1, 1], 'with the status of each';

    my $from = $dbh->prepare('SELECT 3, :n');
    $from->execute(n => 'c');
    is scalar $sth->execute_array({ArrayTupleFetch => $from}), 1,
        'from a statement handle';
    is rows($dbh), [[1, 'a', 1], [2, 'b', 2], [3, 'c', 3]], 'the rows';

    my $dbi  = dbh('DBI');
    my %want = (
        'not active' => do {
            my $done = $dbi->prepare('SELECT 1, 2');
            [$done, $dbh->prepare('SELECT 1, 2')];
        },
        'too many columns' => do {
            my($a, $b)
                = ($dbi->prepare('SELECT 1, 2, 3'), $dbh->prepare('SELECT 1, 2, 3'));
            $_->execute for $a, $b;
            [$a, $b];
        },
    );
    for my $case (sort keys %want) {
        my($plain, $ours) = @{ $want{$case} };
        my $dbi_sth = $dbi->prepare('INSERT INTO t (id, name) VALUES (?, ?)');
        my $want    = dies { $dbi_sth->execute_array({ArrayTupleFetch => $plain}) };
        my $got     = dies { $sth->execute_array({ArrayTupleFetch => $ours}) };
        is $got =~ s( \ at\ .* )()sxr, $want =~ s( \ at\ .* )()sxr,
            "$case: the DBI's message";
    }
    like dies { $sth->execute_array({ArrayTupleFetch => 'nope'}) },
        qr( \A \QDBD::SQLite::st execute_array failed: ArrayTupleFetch 'nope' is not a code ref or statement handle\E )x,
        'nor something else';
    like dies {
        $sth->execute_array({ArrayTupleFetch => sub { return }}, [1], ['a'])
    },
        qr( \QCan't use both ArrayTupleFetch and explicit bind values\E )x,
        'nor with arrays too';
    like dies { $sth->execute_array({ArrayTupleStatus => {}}) },
        qr( \QArrayTupleStatus attribute must be an arrayref\E )x,
        'a status that is not an array';
};

subtest "the DBI's counts, of placeholders, not their uses" => sub {
    my $dbh  = dbh();
    my $sth  = $dbh->prepare($NAMED);
    my $line = __LINE__ + 1;
    like dies { $sth->execute_array({}, [1], ['a'], [1]) },
        at_line(
            'DBD::SQLite::st execute_array failed: 3 bind values supplied but 2 expected',
            $line,
        ),
        'too many arrays, at the caller';
    $sth->bind_param_array('id', [1]);
    like dies { $sth->execute_array({}) },
        qr( \A \QDBD::SQLite::st execute_array failed: 1 bind values supplied but 2 expected\E )x,
        'too few bound';

    my $quiet = dbh('DBIx::Squirrel', RaiseError => 0);
    is $quiet->prepare($NAMED)->execute_array({}, [1]), undef,
        'without RaiseError, nothing is returned';
    like $quiet->errstr, qr( \Q1 bind values supplied but 2 expected\E )x,
        'and the error is set';
};

subtest 'a row of the wrong shape croaks' => sub {
    my $sth = dbh()->prepare($NAMED);
    my @rows;
    my $fetch = sub { shift @rows };

    @rows = ([1]);
    my $line = __LINE__ + 1;
    my $err  = dies { $sth->execute_for_fetch($fetch) };
    like $err, at_line('Expected 2 bind values, not 1', $line),
        'too few values, at the caller';

    @rows = ({id => 1});
    like dies { $sth->execute_for_fetch($fetch) },
        qr( \A \QExpected a value for each placeholder (none for name)\E )x,
        'a hash without a name';

    @rows = ({id => 1, name => 'a', nope => 2});
    like dies { $sth->execute_for_fetch($fetch) },
        qr( \A \QExpected a placeholder of the statement (nope)\E )x,
        'or with one the statement has not';

    my $not_a_row = qr(
        \A \QExpected a row of values: an array, or a hash for named placeholders\E
    )x;
    @rows = (bless {id => 1, name => 'a'}, 'Some::Class');
    like dies { $sth->execute_for_fetch($fetch) }, $not_a_row,
        'an object, not a plain hash';
    @rows = ('a');
    like dies { $sth->execute_for_fetch($fetch) }, $not_a_row,
        'a plain value';

    @rows = ({1 => 1, 2 => 'a'});
    $sth  = dbh()->prepare($NUMBERED);
    like dies { $sth->execute_for_fetch($fetch) }, $not_a_row,
        'a hash, for numbered placeholders';

    @rows = (bless [1, 'a'], 'Some::Class');
    is $sth->execute_for_fetch($fetch), 1,
        'but an object that is an array is one, as for the DBI';
};

subtest "a row the database refuses, in the status, as with the DBI" => sub {
    for my $sql ('INSERT INTO t (id, name) VALUES (?, ?)', $NAMED) {
        my $dbh = dbh('DBIx::Squirrel', RaiseError => 0);
        my $sth = $dbh->prepare($sql);
        my @status;
        is $sth->execute_array(
            {ArrayTupleStatus => \@status}, [1, 1, 2],
            ['a', 'b', 'c'],
            ),
            undef, "$sql: fails";
        like $dbh->errstr, qr( \Qexecuting 3 generated 1 errors\E )x,
            "$sql: with the DBI's message";
        is $status[0], 1, "$sql: the first row went in";
        like $status[1], [D(), qr( UNIQUE )x, D()], "$sql: the second, the error";
        is $status[2], 1, "$sql: the third went in";
    }
};

subtest 'a statement with a list placeholder croaks (D4)' => sub {
    my $dbh = dbh();
    $dbh->do('INSERT INTO t (id, name) VALUES (1, ?)', undef, 'a');
    my $sth
        = $dbh->iterate('SELECT * FROM t WHERE id IN (...:ids)', ids => [1])->sth;
    my $line = __LINE__ + 1;
    like dies { $sth->execute_array({}, [[1]]) },
        at_line(
            'Expected no list placeholder in a statement for rows of values (...:ids)',
            $line,
        ),
        'execute_array';
    like dies {
        $sth->execute_for_fetch(sub { return })
    },
        qr( \A \QExpected no list placeholder in a statement for rows of values (...:ids)\E )x,
        'execute_for_fetch';
    like dies { $sth->bind_param_array('ids', [[1]]) },
        qr( \A \QExpected no list placeholder in a statement for rows of values (...:ids)\E )x,
        'bind_param_array';
};

subtest 'the edges' => sub {
    my $dbh = dbh();
    is scalar $dbh->prepare($NAMED)->execute_array(undef, [1], ['a']), 1,
        'no attributes';
    my $sth = $dbh->prepare($NAMED);
    $sth->bind_param_array('id', [2], undef);
    $sth->bind_param_array('name', ['b']);
    is scalar $sth->execute_array({}), 1, 'attributes given as undef';
    like dies { $dbh->prepare($NAMED)->execute_array({}) },
        qr( \Q0 bind values supplied but 2 expected\E )x,
        'nothing bound';

    my $quiet = dbh('DBIx::Squirrel', RaiseError => 0);
    $sth = $quiet->prepare($NAMED);
    is $sth->execute_array({ArrayTupleFetch => 'nope'}), undef,
        'without RaiseError, nothing for a fetch that is neither';
    is $sth->execute_array({}, {}, ['a']), undef,
        'nor for a value that is neither';
    like $quiet->errstr, qr( \Qmust be a scalar or an arrayref, not a HASH\E )x,
        "with the DBI's message";
};

subtest 'afterwards' => sub {
    my $dbh = dbh();
    my $sth = $dbh->prepare($NAMED);
    $sth->execute_array({}, [1], ['a']);
    ok $sth->execute(id => 2, name => 'b'), 'execute takes names again';
    is rows($dbh)->[-1],               [2, 'b', 2], 'as before';
    is $sth->{private_ekorn}{InOrder}, undef,       'nothing left set';
};

subtest '? placeholders go to the DBI as they are' => sub {
    my $dbh = dbh();
    my $sth = $dbh->prepare('INSERT INTO t (id, name) VALUES (?, ?)');
    ok $sth->bind_param_array(1, [1, 2]), 'bind_param_array';
    ok $sth->bind_param_array(2, 'x'),    'a value for every row';
    is [sort keys %{ $sth->{ParamArrays} }], [1, 2],
        "kept in the DBI's ParamArrays";
    is scalar $sth->execute_array({}), 2, 'execute_array';
    my @rows = ([3, 'y']);
    is scalar $sth->execute_for_fetch(sub { shift @rows }), 1,
        'execute_for_fetch';
    is rows($dbh), [[1, 'x', undef], [2, 'x', undef], [3, 'y', undef]],
        'the rows';
};

done_testing;
