use v5.36;
use utf8;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Placeholders qw(
    expand_lists key_of place_values study_sql trim_sql values_for values_taken
);

subtest 'trim_sql' => sub {
    is trim_sql("  SELECT 1  "), 'SELECT 1', 'blank space around';
    is trim_sql("SELECT 1 -- one\nFROM t"), "SELECT 1 -- one\nFROM t",
        'keeps a comment';
    is trim_sql("\n  SELECT 1\n  FROM t\n"), "SELECT 1\n  FROM t",
        'keeps the blank space inside';
    is trim_sql(" \n\t "),   '',        'all blank';
    is trim_sql(' -- only'), '-- only', 'keeps a lone comment';
    is trim_sql(undef),      '',        'undef';
};

subtest 'study_sql, in each placeholder style' => sub {
    for my $p (qw(? ?1 :1 $1 :id)) {
        my($placeholders, $normalised, $trimmed)
            = study_sql("  SELECT * FROM t WHERE id = $p ");
        is $normalised, 'SELECT * FROM t WHERE id = ?',  "$p normalised";
        is $trimmed,    "SELECT * FROM t WHERE id = $p", "$p trimmed";
        is $placeholders, {1 => $p}, "$p mapped";
    }
};

subtest 'study_sql numbers placeholders by position' => sub {
    my($placeholders, $normalised) = study_sql('SELECT :a, :b, :a');
    is $normalised, 'SELECT ?, ?, ?', 'normalised';
    is $placeholders, {1 => ':a', 2 => ':b', 3 => ':a'},
        'every one, repeats included';

    ($placeholders, $normalised) = study_sql('SELECT $2, $1, $2');
    is $placeholders, {1 => '$2', 2 => '$1', 3 => '$2'},
        'numbered, in any order';

    ($placeholders, $normalised) = study_sql('SELECT ?, ?');
    is $placeholders, {1 => '?', 2 => '?'}, 'bare';
};

subtest 'study_sql croaks on mixed styles' => sub {
    my %mixed = (
        'SELECT ?, $1'        => '?, $1',
        'SELECT ?1, :1'       => '?1, :1',
        'SELECT :1, :name'    => ':1, :name',
        'SELECT $1, $name'    => '$1, $name',
        'SELECT :a, $2, ?1'   => ':name, $1, ?1',
        'SELECT ?, :a, ?, :b' => '?, :name',
    );
    for my $sql (sort keys %mixed) {
        my $line = __LINE__ + 1;
        my $err  = dies { study_sql($sql) };
        is $err,
            "Expected one placeholder style, not several ($mixed{$sql})"
            . " at ${\__FILE__} line $line.\n",
            $sql;
    }
};

subtest 'study_sql leaves alone what only looks like one' => sub {
    my @unchanged = (
        q{SELECT x::int},                      # a PostgreSQL cast
        q{SELECT * FROM v$session},            # an Oracle view
        q{SELECT '10:30', 'it''s :x'},         # strings
        q{SELECT "a:b", `c?`},                 # quoted identifiers
        qq{SELECT 1 -- :x\n},                  # a line comment
        q{SELECT 1 /* $1 ? :x */},             # a block comment
        q{SELECT $$ :x ? $$, $fn$ $1 $fn$},    # dollar-quoted bodies
    );
    for my $statement (@unchanged) {
        my($placeholders, $normalised) = study_sql($statement);
        is $normalised, trim_sql($statement), "unchanged: $statement";
        is $placeholders, {}, "none found: $statement";
    }
};

subtest 'study_sql finds placeholders beside them' => sub {
    my($placeholders, $normalised)
        = study_sql(
            q{SELECT x::int, '10:30' /* :y */ FROM t WHERE a = ? AND b = ?AND});
    is $normalised,
        q{SELECT x::int, '10:30' /* :y */ FROM t WHERE a = ? AND b = ?AND},
        'normalised';
    is $placeholders, {1 => '?', 2 => '?'},
        'a ? touching a keyword is a bare ?';
    ($placeholders, $normalised) = study_sql('SELECT :naïve');
    is $placeholders, {1 => ':naïve'}, 'a name is taken whole';
};

# Each case: the driver, the statement, the statement as normalised, and
# the placeholders found. ":no" is never a placeholder.
my @dialects = (
    [
        'standard rules: a backslash ends nothing',
        undef, q{SELECT 'C:\', :x}, q{SELECT 'C:\', ?}, {1 => ':x'},
    ],
    [
        'doubled quotes',
        'Pg', q{SELECT 'it''s :no', '''', ':no''', :x},
        q{SELECT 'it''s :no', '''', ':no''', ?}, {1 => ':x'},
    ],
    [
        'an E string takes backslashes and doubled quotes',
        'Pg', q{SELECT E'a''b\' :no', e'\\', :x},
        q{SELECT E'a''b\' :no', e'\\', ?}, {1 => ':x'},
    ],
    [
        'a backslash before a sigil, for DBD::Pg',
        'Pg', q{SELECT d \? 'k', d \?| a, d \?& a, \:no, \$1, :x},
        q{SELECT d \? 'k', d \?| a, d \?& a, \:no, \$1, ?}, {1 => ':x'},
    ],
    [
        '# is not a comment, but an operator',
        'Pg', q{SELECT a # :x}, q{SELECT a # ?}, {1 => ':x'},
    ],
    [
        'MySQL: a backslash escapes a quote',
        'mysql', q{SELECT 'it\'s :no', :x}, q{SELECT 'it\'s :no', ?},
        {1 => ':x'},
    ],
    [
        'MySQL: "..." is a string, taking backslashes',
        'mysql', q{SELECT "say \"hi :no\"", :x},
        q{SELECT "say \"hi :no\"", ?}, {1 => ':x'},
    ],
    [
        'MySQL: # starts a comment',
        'mysql', qq{SELECT :x # :no\n, :y}, qq{SELECT ? # :no\n, ?},
        {1 => ':x', 2 => ':y'},
    ],
    [
        'MariaDB: the same as MySQL',
        'MariaDB', q{SELECT 'it\'s :no', :x}, q{SELECT 'it\'s :no', ?},
        {1 => ':x'},
    ],
);

subtest 'study_sql in each dialect' => sub {
    for my $case (@dialects) {
        my($name, $driver, $statement, $want, $want_placeholders) = @$case;
        my($placeholders, $normalised)
            = study_sql($statement, {ekorn_dialect => $driver});
        is $normalised,   $want,              "$name: normalised";
        is $placeholders, $want_placeholders, "$name: placeholders";
    }
};

subtest "study_sql with DBD::Pg's placeholder options" => sub {
    my $sql = q{SELECT a ?# b, d[:2], :x, ?, $1, $1};

    my($placeholders, $normalised) = study_sql(
        $sql,
        {ekorn_dialect => 'Pg', pg_placeholder_dollaronly => 1},
    );
    is $normalised, $sql, 'dollar-only: the statement is left as it is';
    is $placeholders, {1 => '$1', 2 => '$1'}, 'dollar-only: only $1';

    ($placeholders, $normalised) = study_sql(
        q{SELECT a \?# b, d[:2], :x, $1, $1},
        {ekorn_dialect => 'Pg', pg_placeholder_nocolons => 1},
    );
    is $normalised, q{SELECT a \?# b, d[:2], :x, ?, ?},
        'no colons: $1 rewritten, :x and :2 left';
    is $placeholders, {1 => '$1', 2 => '$1'}, 'no colons: only $1';

    ($placeholders, $normalised) = study_sql(
        q{SELECT :x, :y},
        {ekorn_dialect => 'SQLite', pg_placeholder_dollaronly => 1},
    );
    is $normalised, 'SELECT ?, ?', "ignored for another driver";

    ($placeholders, $normalised) = study_sql(q{SELECT :x, :y});
    is $normalised, 'SELECT ?, ?', 'no options at all';
};

subtest 'study_sql of a blank statement' => sub {
    is [study_sql('  ')],  [], 'returns nothing';
    is [study_sql(undef)], [], 'nor for undef';
};

subtest 'study_sql finds list placeholders' => sub {
    for my $p (qw(? ?1 :1 $1 :ids $ids)) {
        is [study_sql("SELECT * FROM t WHERE id IN (...$p)")], [
            {1 => $p},
            'SELECT * FROM t WHERE id IN (?)',
            "SELECT * FROM t WHERE id IN (...$p)",
            {1 => 1},
            ['SELECT * FROM t WHERE id IN (', ')'],
            ],
            "...$p: the placeholder, a list, and the pieces around it";
    }
    my(undef, $normalised, undef, $lists, $pieces)
        = study_sql('SELECT :a, x IN (...:b), :a');
    is $normalised,      'SELECT ?, x IN (?), ?', 'among others';
    is $lists, {2 => 1}, 'only the one with "..." taking a list';
    is $pieces, ['SELECT ', ', x IN (', '), ', ''], 'pieces, empty at an end';

    is [study_sql(q{SELECT '...:a', "...:b", $$ ...:c $$ -- ...:d})],
        [
            {}, q{SELECT '...:a', "...:b", $$ ...:c $$ -- ...:d},
            q{SELECT '...:a', "...:b", $$ ...:c $$ -- ...:d},
        ],
        'none outside SQL, and only three values returned without lists';
    like dies { study_sql('SELECT ...?, :x') },
        qr( \A \QExpected one placeholder style, not several (?, :name)\E )x,
        'one style to a statement, "..." or not';
};

subtest "study_sql's list placeholders with DBD::Pg's options" => sub {
    my $message
        = 'Expected no list placeholder with pg_placeholder_dollaronly (...$1)';
    like dies {
        study_sql(
            'SELECT $2 WHERE 1 IN (...$1)',
            {ekorn_dialect => 'Pg', pg_placeholder_dollaronly => 1},
        )
    },
        qr( \A \Q$message\E )x, 'none with pg_placeholder_dollaronly';
    my(undef, $normalised, undef, $lists) = study_sql(
        'SELECT d[:2] WHERE 1 IN (...$1)',
        {ekorn_dialect => 'Pg', pg_placeholder_nocolons => 1},
    );
    is $normalised, 'SELECT d[:2] WHERE 1 IN (?)',
        'but with pg_placeholder_nocolons';
    is $lists, {1 => 1}, 'taking a list';
};

subtest 'key_of' => sub {
    is key_of(':id'),  'id',  'a name, without its sigil';
    is key_of('$id'),  'id',  'either sigil';
    is key_of('$02'),  2,     'a number, as a number';
    is key_of('?1'),   1,     'a ? and its number';
    is key_of('?', 3), 3,     'a bare ?, by its position';
    is key_of('ids'),  'ids', 'a name given without a sigil';
};

# A digit of another script, such as U+0663, ARABIC-INDIC DIGIT THREE,
# isn't a position: \d alone would take it as one, and read it as 0.
subtest 'a digit of another script is not a position' => sub {
    my $three = "\x{0663}";
    is key_of(":$three"), $three, 'a name, not a number';
    my($placeholders, $normalised) = study_sql("SELECT ?$three");
    is $placeholders, {1 => '?'}, 'after ?, a bare ?';
    is $normalised, "SELECT ?$three", 'with the digit left in the statement';
    ($placeholders) = study_sql("SELECT \$$three");
    is $placeholders, {1 => "\$$three"}, 'after $, a name';
    ($placeholders) = study_sql(
        "SELECT \$$three, \$1",
        {ekorn_dialect => 'Pg', pg_placeholder_dollaronly => 1},
    );
    is $placeholders, {1 => '$1'}, "not one, for DBD::Pg's dollar-only";
};

subtest 'values_for and values_taken' => sub {
    my $numbered = {1 => [1, 3], 2 => [2]};
    my $named    = {a => [1], b => [2, 3]};
    is { values_for($numbered, 'x', 'y') }, {1 => 'x', 2 => 'y'}, 'numbered';
    is { values_for($named,    b => 2, ':a' => 1) }, {a => 1, b => 2}, 'named';
    is { values_for($named,    {a => 1, b => 2}) },  {a => 1, b => 2},
        'named, in a hash reference';
    is values_taken($numbered), 2, 'taking the highest number';
    is values_taken($named),    0, 'or none in order';
    like dies { values_for($numbered, 'x') },
        qr( \A \QExpected 2 bind values, not 1\E )x, 'too few';
    like dies { values_for($named, a => 1) },
        qr( \A \QExpected a value for each placeholder (none for b)\E )x,
        'a name missing';
};

subtest 'expand_lists and place_values' => sub {
    my($placeholders, undef, undef, undef, $pieces)
        = study_sql('SELECT :a WHERE x IN (...:ids) OR y IN (...:ids)');
    my %state = (
        Placeholders => $placeholders,
        Pieces       => $pieces,
        Lists        => {ids => '...:ids'},
    );
    my($statement, $binds, $lengths)
        = expand_lists(\%state, {a => 1, ids => [1, 2, 3]});
    is $statement, 'SELECT ? WHERE x IN (?, ?, ?) OR y IN (?, ?, ?)',
        'a "?" for each value, at each use';
    is $binds,   {a   => [1], ids => [2 .. 7]}, 'the positions of each';
    is $lengths, {ids => 3},                    'the length of each list';

    my %expanded = (%state, Binds => $binds, Lengths => $lengths);
    is { place_values(\%expanded, a => 'x', ids => [7, 8, 9]) },
        {1 => 'x', 2 => 7, 3 => 8, 4 => 9, 5 => 7, 6 => 8, 7 => 9},
        'each value at a position of its own';
    like dies { place_values(\%expanded, ids => [7, 8]) },
        qr( \A \QExpected 3 values in a list, as prepared, not 2 (...:ids)\E )x,
        'as many as prepared';
    like dies { expand_lists(\%state, {a => 1, ids => []}) },
        qr( \A \QExpected at least one value in a list (...:ids)\E )x,
        'at least one';
};

done_testing;
