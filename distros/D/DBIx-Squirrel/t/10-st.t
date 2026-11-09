use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI qw(SQL_INTEGER);
use DBIx::Squirrel;

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

my $dbh = DBIx::Squirrel->connect(@source);

# The row a statement returns, executed with the values given.
sub row ($statement, @values) {
    my $sth = $dbh->prepare($statement);
    $sth->execute(@values);
    return $sth->fetchrow_arrayref;
}

subtest '? placeholders are bound as the DBI binds them' => sub {
    my $dbi = DBI->connect(@source);
    my $sql = 'SELECT ?, ? + 1';
    is row($sql, 1, 2), $dbi->selectrow_arrayref($sql, undef, 1, 2),
        'the same result as the DBI';
    is row($sql, [1, 2]), [1, 3], 'from an array reference';
    is $dbh->prepare($sql)->{private_ekorn}{Binds}, undef,
        'with no map of their own';
};

subtest 'numbered placeholders' => sub {
    is row('SELECT $1 + $1, $1', 2),     [4, 2],     'one value to each use of $1';
    is row('SELECT $2, $1', 'a', 'b'),   ['b', 'a'], 'in order of number';
    is row('SELECT ?2, ?1', 'a', 'b'),   ['b', 'a'], 'with ?';
    is row('SELECT :2, :1', 'a', 'b'),   ['b', 'a'], 'with :';
    is row('SELECT $2, $1', ['a', 'b']), ['b', 'a'], 'from an array reference';
    is $dbh->prepare('SELECT $2 + $1, $1')->{private_ekorn}{Binds},
        {1 => [2, 3], 2 => [1]}, 'mapped to their positions';

    my $sth = $dbh->prepare('SELECT $1, $2');
    like dies { $sth->execute(1) },
        qr( \A Expected\ 2\ bind\ values,\ not\ 1\ at\ \Q${\ __FILE__ }\E )x,
        'too few values, reported at the caller';
    like dies { $sth->execute(1, 2, 3) },
        qr( \A Expected\ 2\ bind\ values,\ not\ 3 )x,
        'too many';
    like dies { $dbh->prepare('SELECT $0') },
        qr( \A Expected\ placeholders\ numbered\ from\ 1\ \(\$0\) )x,
        'numbered from 1';
    is row("SELECT :\x{0660}", "\x{0660}" => 5), [5],
        'but a digit of another script, such as U+0660, is a name';
};

subtest 'named placeholders' => sub {
    my $sql = 'SELECT :a + :a, :b';
    is row($sql, a => 2, b => 3),            [4, 3], 'as pairs';
    is row($sql, {a => 2, b => 3}),          [4, 3], 'in a hash reference';
    is row($sql, ':a' => 2, ':b' => 3),      [4, 3], 'with their sigils';
    is row($sql, [a => 2, b => 3]),          [4, 3], 'from an array reference';
    is row('SELECT $a, $b', a => 1, b => 2), [1, 2], 'with $';
    is $dbh->prepare($sql)->{private_ekorn}{Binds}, {a => [1, 2], b => [3]},
        'mapped to their positions';

    my $sth  = $dbh->prepare($sql);
    my $each = qr( Expected\ a\ value\ for\ each\ placeholder )x;
    like dies { $sth->execute(a => 1) }, qr( \A $each \ \(none\ for\ b\) )x,
        'a name left out';
    like dies { $sth->execute(a => 1, b => 2, c => 3) },
        qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(c\) )x,
        'a name not used';
    like dies { $sth->execute(a => 1, 'b') },
        qr( \A Expected\ names\ and\ values\ in\ pairs )x,
        'an odd number of values';
};

subtest 'bind_param' => sub {
    my $sth = $dbh->prepare('SELECT :a + :a, :b');
    ok $sth->bind_param('a',  2), 'by name';
    ok $sth->bind_param(':b', 3), 'with the sigil';
    $sth->execute;
    is $sth->fetchrow_arrayref, [4, 3], 'binds every use of a name';
    ok $sth->bind_param(3, 5), 'by position, for a named statement';
    $sth->execute;
    is $sth->fetchrow_arrayref, [4, 5], 'binding that position';
    like dies { $sth->bind_param('c', 1) },
        qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(c\) )x,
        'a name not used';
    like dies { $sth->bind_param("\x{0661}", 1) },
        qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(\x{0661}\) )x,
        'nor a digit of another script, which is no position';

    $sth = $dbh->prepare('SELECT $2, $1 + $1');
    ok $sth->bind_param(1,    2), 'by number';
    ok $sth->bind_param('$2', 3), 'with the sigil';
    $sth->execute;
    is $sth->fetchrow_arrayref, [3, 4], 'binds every use of a number';
    like dies { $sth->bind_param(3, 1) },
        qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(3\) )x,
        'a number not used';

    $sth = $dbh->prepare('SELECT ?, ?');
    ok $sth->bind_param(2, 'b') && $sth->bind_param(1, 'a'),
        'by position, for ?, as the DBI binds';
    $sth->execute;
    is $sth->fetchrow_arrayref, [qw(a b)], 'binding those positions';
};

subtest 'bind' => sub {
    my $sth = $dbh->prepare('SELECT :a, :b');
    ref_is $sth->bind(a => 1, b => 2), $sth, 'returns the handle';
    $sth->execute;
    is $sth->fetchrow_arrayref, [1, 2], 'with the values bound';
    $sth = $dbh->prepare('SELECT ?, ?');
    $sth->bind([1, 2])->execute;
    is $sth->fetchrow_arrayref, [1, 2],
        'and ? placeholders from an array reference';
};

subtest 'values given to execute stay bound, as with the DBI' => sub {
    my $sth = $dbh->prepare('SELECT typeof($1), $1, $2');
    $sth->execute(7, 'x');
    $sth->execute;
    is $sth->fetchrow_arrayref, ['text', 7, 'x'],
        'for an execute without values';

    ok $sth->bind_param(1, 8, SQL_INTEGER), 'a type bound to a number';
    $sth->execute(9, 'y');
    is $sth->fetchrow_arrayref, ['integer', 9, 'y'],
        'is kept when values are given to execute';

    $sth = $dbh->prepare('SELECT typeof(:n), :n, :s');
    $sth->bind_param(':n', 1, SQL_INTEGER);
    $sth->execute(n => 2, s => 'z');
    is $sth->fetchrow_arrayref, ['integer', 2, 'z'], 'and to a name';
};

subtest 'executing without a value for each placeholder croaks' => sub {
    my $none
        = qr( \A Expected\ a\ value\ for\ each\ placeholder\ \(none\ for\ (.+?)\) )x;
    my $sth  = $dbh->prepare('SELECT :a + :a, :b');
    my $line = __LINE__ + 1;
    my $err  = dies { $sth->execute };
    like $err, $none, 'with no values given or bound';
    like $err, qr( at\ \Q${\ __FILE__ }\E\ line\ $line\. )x, 'at the caller';
    is [$err =~ $none], ['a, b'], 'naming each placeholder';

    $sth->bind_param(':a', 1);
    is [dies { $sth->execute } =~ $none], ['b'], 'or those bind_param left';
    $sth->bind_param(3, 2);
    ok lives { $sth->execute }, 'binding the last by position';
    is $sth->fetchrow_arrayref, [2, 2], 'with the values bound';

    $sth = $dbh->prepare('SELECT :a, :b, :a');
    $sth->bind_param(1, 1);
    is [dies { $sth->execute } =~ $none], ['a, b'],
        'a name bound at one of its positions only is still missing';

    $sth = $dbh->prepare('SELECT $1, $2');
    $sth->execute(1, 2);
    ok lives { $sth->execute }, 'values given to execute stay bound';
    $sth = $dbh->prepare('SELECT $1, $2');
    $sth->bind(1, 2);
    ok lives { $sth->execute }, 'as do those given to bind';

    $sth = $dbh->prepare('SELECT ?, ?');
    ok lives { $sth->execute },
        '? placeholders are left to the driver, as with the DBI';

    like dies { $dbh->do('SELECT :a') },           $none, 'do';
    like dies { $dbh->iterate('SELECT :a')->all }, $none, 'an iterator';
    like dies { $dbh->selectrow_array('SELECT $1') }, $none,
        'the select methods';
    $sth = $dbh->prepare('SELECT :a');
    $sth->bind(a => 1);
    is [$dbh->selectrow_array($sth)], [1],
        'but not with a statement handle whose values are bound';

    $sth = $dbh->prepare_cached('SELECT :cached');
    $sth->execute(cached => 1);
    $sth->finish;
    ok lives { $dbh->prepare_cached('SELECT :cached')->execute },
        'a cached handle keeps its values, as with the DBI';
};

subtest 'through the database handle' => sub {
    is $dbh->do('SELECT $1 + $1', undef, 2), '0E0', 'do';
    is [$dbh->selectrow_array('SELECT $1 + $1', undef, 2)], [4],
        'selectrow_array, numbered';
    is [$dbh->selectrow_array('SELECT :a + :a', undef, a => 2)], [4],
        'and named';
    is [$dbh->selectrow_array('SELECT ?, ?', undef, [1, 2])], [1, 2],
        'and ? from an array reference';

    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->selectrow_array('SELECT $1, $2', undef, 1) };
    like $err, qr( \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )x,
        'errors are reported at the caller, through the DBI';
    $line = __LINE__ + 1;
    $err  = dies { $dbh->do('SELECT :a', undef, b => 1) };
    like $err, qr( \ at\ \Q${\ __FILE__ }\E\ line\ $line\. $ )x,
        'and through do';
};

subtest 'the select methods give the same results as the DBI' => sub {
    my %h = (
        dbi      => DBI->connect(@source),
        squirrel => DBIx::Squirrel->connect(@source),
    );
    for my $h (values %h) {
        $h->do('CREATE TABLE t (id INTEGER, name TEXT)');
        $h->do('INSERT INTO t VALUES (1, ?), (2, ?)', undef, 'a', 'b');
    }
    my $dbi = 'SELECT id, name FROM t WHERE id >= ? ORDER BY id';
    my $sq  = 'SELECT id, name FROM t WHERE id >= :min ORDER BY id';
    for my $method (qw(
        selectrow_array    selectrow_arrayref selectrow_hashref
        selectall_arrayref selectcol_arrayref selectall_array))
    {
        is [$h{squirrel}->$method($sq, undef, min => 1)],
            [$h{dbi}->$method($dbi, undef, 1)], $method;
    }
    is $h{squirrel}->selectall_hashref($sq, 'id', undef, min => 1),
        $h{dbi}->selectall_hashref($dbi, 'id', undef, 1), 'selectall_hashref';
    is $h{squirrel}->selectall_arrayref($sq, {Slice => {}}, {min => 2}),
        $h{dbi}->selectall_arrayref($dbi, {Slice => {}}, 2),
        'with attributes, and values in a hash reference';
    my $sth = $h{squirrel}->prepare($sq);
    is $h{squirrel}->selectcol_arrayref($sth, undef, min => 2), [2],
        'given a statement handle';
};

subtest 'an array reference, with DBD::Pg' => sub {

    # No PostgreSQL server here, so a hash stands in for the statement
    # handle: _unwrap reads only its driver, and what prepare kept.
    my sub sth ($driver, $params, $binds = undef) {
        return {
            Database      => {Driver => {Name => $driver}},
            NUM_OF_PARAMS => $params,
            private_ekorn => {Binds => $binds},
        };
    }
    my $unwrap = \&DBIx::Squirrel::st::_unwrap;    ## no critic (Variables::ProtectPrivateVars)
    my $array  = [1, 2];
    is [$unwrap->(sth('Pg', 1), $array)], [$array],
        'is a value, to a statement taking one ?';
    is [$unwrap->(sth('Pg', 1, {1 => [1, 2]}), $array)], [$array],
        'or one number, used twice';
    is [$unwrap->(sth('Pg', 2), $array)], [1, 2],
        'stands for its values, to one taking two';
    is [$unwrap->(sth('Pg', 2, {a => [1], b => [2]}), [a => 1, b => 2])],
        [a => 1, b => 2], 'or named ones';
    is [$unwrap->(sth('ODBC', 1), $array)], [1, 2],
        'and through another driver, always';
    is [$unwrap->(sth('Pg', 2), 1, 2)], [1, 2], 'values not in one are left';
};

subtest "DBD::Pg's \$1 placeholders, with pg_placeholder_dollaronly" => sub {
    my $pg = {Driver => {Name => 'Pg'}, pg_placeholder_dollaronly => 1};
    my($normalised, $state)
        = DBIx::Squirrel::db::_study($pg, 'SELECT $1, $1', undef);    ## no critic (Subroutines::ProtectPrivateSubs)
    is $normalised,     'SELECT $1, $1', 'go to DBD::Pg as written';
    is $state->{Binds}, undef,           'for DBD::Pg to bind';
};

subtest 'ekorn_finish_active' => sub {
    $dbh->do('CREATE TABLE n (v INTEGER)');
    $dbh->do('INSERT INTO n VALUES (1), (2)');

    my $sth = $dbh->prepare('SELECT v FROM n ORDER BY v');
    $sth->execute;
    $sth->fetchrow_arrayref;
    ok $sth->{Active}, 'a statement left active';
    my $finished = 0;
    my $mock     = mock 'DBIx::Squirrel::st' =>
        (add => [finish => sub ($sth) { $finished++; $sth->DBI::st::finish }]);
    $sth->execute;
    is $finished, 0, "isn't finished before execute, as with the DBI";

    $sth
        = $dbh->prepare('SELECT v FROM n ORDER BY v', {ekorn_finish_active => 1});
    $sth->execute;
    $sth->fetchrow_arrayref;
    $sth->execute;
    is $finished,               1,   'is, with ekorn_finish_active on prepare';
    is $sth->fetchrow_arrayref, [1], 'and starts again';

    my $other = DBIx::Squirrel->connect(
        @source[0 .. 2],
        {%{ $source[3] }, ekorn_finish_active => 1},
    );
    $sth = $other->prepare('SELECT 1 UNION ALL SELECT 2');
    $sth->execute;
    $sth->fetchrow_arrayref;
    $sth->execute;
    is $finished, 2, 'or on connect';
};

done_testing;
