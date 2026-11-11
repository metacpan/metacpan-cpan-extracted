use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use Sub::Util qw();

# An in-memory SQLite database lasts as long as its handle, which
# connect_cached keeps, so each use of music sees the same one.
use DBIx::Squirrel::Sugar database => {
    music => [
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    ],
};

# Statements on music, defined before music has its table.
use DBIx::Squirrel::Sugar statement => {
    artist_names => [
        music => 'SELECT name FROM artist ORDER BY id',
        sub ($row) { $row->[0] },
    ],
    artist        => [music => 'SELECT id, name FROM artist WHERE id = :id'],
    rename_artist => [music => 'UPDATE artist SET name = :name WHERE id = :id'],
    named         => [
        music => 'SELECT id, name FROM artist ORDER BY id',
        {ekorn_slice => {}}, sub ($row) { $row->{name} },
    ],
};

music 'CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)';
music 'INSERT INTO artist (name) VALUES (?)', $_ for qw(Abba Blur Cream);

subtest 'defined on use' => sub {
    isa_ok music, ['DBIx::Squirrel::db'], 'music, called with nothing';
    ref_is music,             music, 'the same handle each time';
    ref_is database('music'), music, 'database gives it too';
    ok main->can('database'), 'database is imported';
    is Sub::Util::subname(\&music), 'main::music', 'named, for stack traces';
    is Sub::Util::subname(\&database), 'DBIx::Squirrel::Sugar::database',
        'leaving the name of one imported';
};

subtest 'the functions alone, on use' => sub {

    package Functions::Only {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Sugar qw(database statement);
    }
    ok Functions::Only->can('database') && Functions::Only->can('statement'),
        'database and statement';
};

subtest 'a statement that cannot be executed, without RaiseError' => sub {
    database(
        quiet => 'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    quiet('CREATE TABLE u (x INTEGER UNIQUE)');
    quiet('INSERT INTO u VALUES (1)');
    is [quiet('INSERT INTO u VALUES (?)', 1)], [], 'gives nothing';
    statement(insert_u => quiet => 'INSERT INTO u VALUES (?)');
    is [insert_u(1)], [],  'as a statement of its own';
    is quiet()->err,  T(), 'and the handle says why';
};

subtest 'a statement, executed' => sub {
    my $sth = music 'SELECT name FROM artist WHERE id = ?', 2;
    isa_ok $sth, ['DBIx::Squirrel::st'], 'the statement handle';
    is $sth->fetchrow_arrayref, ['Blur'], 'executed with the bind values';
    $sth = music 'SELECT name FROM artist WHERE id = :id', id => 3;
    is $sth->fetchrow_arrayref, ['Cream'], 'in any placeholder style';
    is music('UPDATE artist SET name = name WHERE id <= ?', 2)->rows, 2,
        'and one that changes rows';
};

subtest 'through stages' => sub {
    my $sql = 'SELECT id, name FROM artist ORDER BY id';
    is [music $sql, sub ($row) { $row->[1] }], [qw(Abba Blur Cream)],
        'the results';
    is scalar(music $sql, sub ($row) { $row->[0] > 1 ? $row : () }), 2,
        'or how many in scalar context';
    is [music $sql, {ekorn_slice => {}}, sub ($row) { $row->{name} }],
        [qw(Abba Blur Cream)], 'with attributes';
    is [music 'SELECT name FROM artist WHERE id > ?', 1, sub { $_->[0] }],
        [qw(Blur Cream)], 'and bind values';
};

subtest 'a statement handle' => sub {
    my $sth = music->prepare('SELECT name FROM artist WHERE id = ?');
    ref_is music($sth, 1), $sth, 'executed itself';
    is $sth->fetchrow_arrayref,                   ['Abba'],  'with the bind values';
    is [music $sth, 3, sub ($row) { $row->[0] }], ['Cream'], 'or iterated';
};

subtest 'defined as the program runs' => sub {
    my $function = database(
        archive => 'dbi:SQLite:dbname=:memory:',
        '', '', {RaiseError => 1, PrintError => 0, ShowErrorStatement => 1},
    );
    ok main->can('archive'), 'gives the package its function';
    ref_is $function, \&archive, 'and returns it';
    isa_ok archive(), ['DBIx::Squirrel::db'], 'which gives the handle';
    ref_is_not archive(), music,
        'of its own database, as its attributes differ';
};

subtest 'connected when first used' => sub {
    my $source = 'dbi:SQLite:dbname=/nonexistent/directory/x.db';
    ok lives { database(nowhere => $source, '', '', {PrintError => 0}) },
        'not when defined';
    my $line = __LINE__ + 1;
    like dies { nowhere() },
        qr( \A DBIx::Squirrel\ connect\( .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )xs,
        'croaking at the caller when it fails';
};

subtest 'defined with a handle' => sub {
    my $original = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    );
    database(copy => $original);
    my $copy = copy();
    isa_ok $copy, ['DBIx::Squirrel::db'], 'a clone';
    ref_is_not $copy, $original, 'not the handle itself';
    ref_is copy(), $copy, 'kept';
};

subtest 'the handle kept, and pinged only after a failure' => sub {
    database(kept => 'dbi:SQLite:dbname=:memory:', '', '', {PrintError => 0});
    my $pings = 0;
    my $ping  = DBIx::Squirrel::db->can('ping');
    my $mock  = mock 'DBIx::Squirrel::db' =>
        (override => [ping => sub ($self) { $pings++; $self->$ping }]);
    my $dbh = kept();
    kept('SELECT 1') for 1 .. 3;
    ref_is kept(), $dbh, 'the same handle each time';
    is $pings, 0, 'without a ping';

    like dies { kept('SELEC 1') }, qr( syntax\ error )x, 'a call that fails';
    ref_is kept(), $dbh, 'kept after a failure, if it answers';
    is $pings, 1, 'pinged';
    like kept()->errstr, qr( syntax\ error )x, 'leaving the error to be read';
    kept('SELECT 1');
    my $after = $pings;
    kept();
    is $pings, $after, 'and not pinged once a call succeeds';

    $dbh->disconnect;
    my $new = kept();
    ref_is_not $new, $dbh, 'connected again once disconnected';
    ok $new->{Active}, 'with a new connection';
};

subtest 'connected again when the connection has gone' => sub {
    database(gone => 'dbi:SQLite:dbname=:memory:', '', '', {PrintError => 0});
    my $dbh = gone();
    $dbh->set_err(1, 'the server has gone away');
    my $mock
        = mock 'DBIx::Squirrel::db' => (override => [ping => sub ($self) { 0 }]);
    my $new = gone();
    ref_is_not $new, $dbh, 'when its last call failed, and it does not answer';
    ref_is gone(), $new, 'and kept';
};

subtest 'statements, defined on use' => sub {
    is [artist_names], [qw(Abba Blur Cream)], 'the results, through its stages';
    is scalar(artist_names), 3,               'or how many in scalar context';
    is [artist_names sub ($name) { lc $name }], [qw(abba blur cream)],
        'with stages added for a call';
    is [artist_names], [qw(Abba Blur Cream)], 'and for that call only';
    is [named],        [qw(Abba Blur Cream)], 'with attributes';
    ok main->can('statement'), 'statement is imported';
};

subtest 'a statement without stages' => sub {
    my $sth = artist id => 2;
    isa_ok $sth, ['DBIx::Squirrel::st'], 'gives the statement handle';
    is $sth->fetchrow_arrayref, [2, 'Blur'], 'executed with the bind values';
    $sth->fetchall_arrayref;
    ref_is artist(id => 3), $sth, 'prepared once';
    is rename_artist(name => 'ABBA', id => 1)->rows, 1,
        'and one that changes rows';
    rename_artist(name => 'Abba', id => 1);

    my $active = artist id => 1;
    my $again  = artist id => 2;
    ref_is_not $again, $active, 'prepared again while the first is active';
    is $active->fetchrow_arrayref, [1, 'Abba'], 'which is left as it was';
    is $again->fetchrow_arrayref,  [2, 'Blur'], 'for the call after';
};

subtest 'a stage calling its own statement' => sub {
    music 'CREATE TABLE n (id INTEGER PRIMARY KEY)';
    music 'INSERT INTO n VALUES (?)', $_ for 1 .. 150;
    statement(
        ns_upto => music => 'SELECT id FROM n WHERE id <= ? ORDER BY id',
        sub ($row) { $row->[0] },
    );

    # A few rows are fetched at once, so the first call's handle is done
    # while its iterator hands them out; more than a batch, and it's
    # still fetching.
    for my $n (3, 150) {
        is [ns_upto($n, sub ($id) { [$id, scalar ns_upto($id)] })],
            [map { [$_, $_] } 1 .. $n], "has a statement handle of its own ($n rows)";
    }
};

subtest 'a list placeholder' => sub {
    my $sql = 'SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id';
    is music($sql, ids => [1, 3])->fetchall_arrayref, [['Abba'], ['Cream']],
        'through the database, executed';
    is [music $sql, ids => [2, 3], sub ($row) { $row->[0] }], [qw(Blur Cream)],
        'or through stages';
    statement(
        artists_by_id => music => $sql,
        sub ($row) { $row->[0] },
    );
    is [artists_by_id(ids => [3])], ['Cream'], 'as a statement';
    is [artists_by_id(ids => [1, 2, 3])], [qw(Abba Blur Cream)],
        'prepared for each list';

    database(
        hushed => 'dbi:SQLite:dbname=:memory:',
        '', '', {RaiseError => 0, PrintError => 0},
    );
    statement(broken => hushed => 'SELEC 1 WHERE 1 IN (...?)');
    my $line = __LINE__ + 1;
    like dies { broken([1]) },
        qr( \A DBD::SQLite::db\ prepare_cached\ failed: .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )xs,
        "croaking when it can't be prepared, as a statement";
    $line = __LINE__ + 1;
    like dies { hushed('SELEC 1 WHERE 1 IN (...?)', [1]) },
        qr( \A DBD::SQLite::db\ prepare\ failed: .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )xs,
        'or through the database';
};

subtest 'statements defined as the program runs' => sub {
    my $function = statement(
        count_of => later => 'SELECT COUNT(*) FROM t',
        sub ($row) { $row->[0] },
    );
    ref_is $function, \&count_of,
        'gives the package its function, and returns it';
    my $expected = 'Expected a database defined as later';
    my $line     = __LINE__ + 1;
    like dies { count_of() },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'and its database is looked for when it runs';
    database(
        later => 'dbi:SQLite:dbname=:memory:',
        '', '', {RaiseError => 1, PrintError => 0, LongReadLen => 1024},
    );
    later('CREATE TABLE t (x)');
    is [count_of()], [0], 'so it can be defined after the statement';
};

# The error from using DBIx::Squirrel::Sugar with the arguments given.
sub use_error ($args) {
    return eval "use DBIx::Squirrel::Sugar $args; 1" ? undef : $@;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
}

subtest 'mistakes' => sub {
    my $expected = 'Expected a database defined as unknown';
    my $line     = __LINE__ + 1;
    like dies { database('unknown') },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'a name not defined';
    my sub define ($name) {
        return database($name => 'dbi:SQLite:dbname=:memory:');
    }
    like dies { define('music') },
        qr( \A \QExpected a database defined once (music)\E )x,
        'a name defined twice';
    like dies { define('no good') },
        qr( \A \QExpected a name for a database (no good)\E )x,
        'a name no function can have';
    like dies { define('is') },
        qr( \A \QExpected no function of the name in main already (is)\E )x,
        'a function the package has';
    like use_error(q{'other'}),
        qr( \A \QExpected database or statement, not other\E )x,
        'on use, anything else';
    like use_error(q{database => {x => 'y'}}),
        qr( \A \QExpected the arguments to connect to x in an ARRAY\E )x,
        'or a definition not in an array';
    like use_error(q{statement => {x => 'y'}}),
        qr( \A \QExpected the statement x in an ARRAY\E )x, 'a statement too';

    like dies { statement('no good' => music => 'SELECT 1') },
        qr( \A \QExpected a name for a statement (no good)\E )x,
        'a statement named as no function can be';
    like dies { statement(lonely => 'music') },
        qr( \A Too\ few\ arguments )x, 'a statement without its SQL';
    like dies { statement(nowhere => undef, 'SELECT 1') },
        qr( \A \QExpected a database and a statement for nowhere\E )x,
        'a statement on no database';
    like dies { statement(odd => music => 'SELECT 1', 'x') },
        qr( \A \QExpected only code references or pipelines after the statement for odd\E )x,
        'anything but code references or pipelines after it';
    like dies { statement(music => music => 'SELECT 1') },
        qr( \A \QExpected no function of the name in main already (music)\E )x,
        'a name a database has';
};

done_testing;
