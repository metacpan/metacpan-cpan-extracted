use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Stop;
use DBIx::Squirrel::Sugar qw(database statement);
use Time::HiRes           qw(sleep);
use experimental          qw(builtin);
use builtin               qw(weaken);

# Against a real PostgreSQL server, named by a data source in the
# environment, such as "dbi:Pg:dbname=test;host=localhost;user=test".
# Skipped without one.
my $source = $ENV{DBIX_SQUIRREL_TEST_PG}
    or skip_all 'set DBIX_SQUIRREL_TEST_PG to a PostgreSQL data source';
eval { require DBD::Pg; 1 }
    or skip_all 'DBD::Pg is not installed';

my @attrs = (undef, undef, {RaiseError => 1, PrintError => 0});
my $dbh   = DBIx::Squirrel->connect($source, @attrs);
my $dbi   = DBI->connect($source, @attrs);

# The row a statement returns, prepared with the attributes given and
# executed with the values.
sub row ($statement, $attrs, @values) {
    my $sth = $dbh->prepare($statement, $attrs);
    $sth->execute(@values);
    return $sth->fetchrow_arrayref;
}

subtest 'placeholders' => sub {
    is row('SELECT $1::int + $1::int, $2::int', undef, 2, 3), [4, 3],
        'numbered, used twice';
    is row('SELECT :a::int, :b::int', undef, b => 2, a => 1), [1, 2], 'named';
    is row(q{SELECT '{"k": 1}'::jsonb \? 'k', :x::text}, undef, x => 'y'),
        [T(), 'y'], 'a backslash before ?, for the jsonb operator';
};

subtest "DBD::Pg's placeholder options" => sub {
    my $dollar = {pg_placeholder_dollaronly => 1};
    is row('SELECT $1::int + $1::int', $dollar, 2), [4],
        'pg_placeholder_dollaronly, with $1 used twice, for DBD::Pg to bind';
    is row(q{SELECT '{"k": 1}'::jsonb ? 'k', $1::text}, $dollar, 'y'),
        [T(), 'y'], 'and ? as an operator';

    my $colons = {pg_placeholder_nocolons => 1};
    is row('SELECT (ARRAY[1, 2, 3])[2:3], ?::int', $colons, 4),
        [[2, 3], 4], 'pg_placeholder_nocolons, with an array slice';

    my $other = DBIx::Squirrel->connect(
        $source, undef, undef,
        {%{ $attrs[2] }, pg_placeholder_dollaronly => 1},
    );
    my $sth = $other->prepare('SELECT $1::int + $1::int');
    $sth->execute(2);
    is $sth->fetchrow_arrayref, [4], 'read from the database handle';
};

subtest 'an array reference' => sub {
    is row('SELECT 2 = ANY(?::int[])', undef, [1, 2]), [T()],
        'is one PostgreSQL array, to a statement taking one value';
    is row('SELECT ?::int, ?::int', undef, [1, 2]), [1, 2],
        'and stands for its values, to one taking two';
    is row('SELECT 3 = ANY($1::int[])', undef, [[1, 2]]), [F()],
        'or inside another, to a numbered placeholder';
};

subtest 'a list placeholder' => sub {
    my $sql
        = 'SELECT g FROM generate_series(1, 5) g WHERE g IN (...:ids) ORDER BY g';
    is $dbh->selectcol_arrayref($sql, ids => [2, 4]), [2, 4], 'a list';
    is $dbh->selectcol_arrayref(
        'SELECT g FROM generate_series(1, 5) g WHERE g IN (...?) ORDER BY g',
        [1, 5],
        ),
        [1, 5], 'a single array reference, a list, not a PostgreSQL array';
    is $dbh->selectcol_arrayref(
              'SELECT g FROM generate_series(1, 5) g'
            . ' WHERE g IN (...:a) OR g = ANY(:b::int[]) ORDER BY g',
        a => [1], b => [3, 5],
        ),
        [1, 3, 5], 'beside a PostgreSQL array, bound as one';
    my $message
        = 'Expected no list placeholder with pg_placeholder_dollaronly (...$1)';
    like dies {
        $dbh->selectcol_arrayref(
            'SELECT 1 WHERE 1 IN (...$1)',
            {pg_placeholder_dollaronly => 1}, [1],
        )
    },
        qr( \A \Q$message\E )x, 'none with pg_placeholder_dollaronly';
};

subtest 'do' => sub {
    is $dbh->do('SELECT 2 = ANY(?::int[])', undef, [1, 2]),
        $dbi->do('SELECT 2 = ANY(?::int[])', undef, [1, 2]),
        'an array reference is one PostgreSQL array, as with the DBI';
    is $dbh->do('SELECT ?::int, ?::int', undef, [1, 2]), 1,
        'or stands for the values, to a statement taking two';
    my $dollar = {pg_placeholder_dollaronly => 1};
    is $dbh->do('SELECT 3 = ANY($1::int[])', $dollar, [1, 2]), 1,
        'and to one taking $1 alone, for DBD::Pg to read';
    is $dbh->do('SELECT 1; SELECT 2'), $dbi->do('SELECT 1; SELECT 2'),
        'several statements, as DBD::Pg allows';
};

subtest 'the same results as the DBI' => sub {
    my $sql = 'SELECT 2 = ANY(?::int[]), ?::int';
    is [$dbh->selectrow_array($sql, undef, [1, 2], 3)],
        [$dbi->selectrow_array($sql, undef, [1, 2], 3)], 'selectrow_array';
    is [$dbh->selectrow_array('SELECT 2 = ANY(?::int[])', undef, [1, 2])],
        [$dbi->selectrow_array('SELECT 2 = ANY(?::int[])', undef, [1, 2])],
        'with an array reference alone';
};

subtest "the DBI's messages" => sub {
    my sub message ($h) {
        my $error = dies { $h->do('SELEC 1') };
        return $error =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
    }
    is message($dbh), message($dbi), 'do';
};

subtest 'connect_cached' => sub {
    my @cached = (undef, undef, {RaiseError => 1, PrintError => 0});
    my $one    = DBIx::Squirrel->connect_cached($source, @cached);
    ref_is DBIx::Squirrel->connect_cached($source, @cached), $one,
        'the same handle, for the same attributes';
    my $other = DBIx::Squirrel->connect_cached(
        $source, undef, undef,
        {RaiseError => 1, PrintError => 0, ekorn_slice => {}},
    );
    ref_is_not $other, $one, 'another, for other ekorn_ attributes';
    $_->disconnect for $one, $other;
};

subtest "statements studied once, with DBD::Pg's options" => sub {
    my $sql = 'SELECT $1::int + $1::int';
    is $dbh->prepare($sql)->{Statement}, 'SELECT ?::int + ?::int',
        'rewritten';
    $dbh->{pg_placeholder_dollaronly} = 1;
    is $dbh->prepare($sql)->{Statement}, $sql,
        'left as written, once the handle has pg_placeholder_dollaronly';
    $dbh->{pg_placeholder_dollaronly} = 0;
    is $dbh->prepare($sql)->{Statement}, 'SELECT ?::int + ?::int',
        'and rewritten again, once it has not';
};

subtest 'prepare_cached and iterators' => sub {
    my $sql = 'SELECT n FROM generate_series(1, :last) AS n';
    my $sth = $dbh->prepare_cached($sql);
    my $it  = $sth->iterate(last => 250, sub ($row) { $row->[0] });
    is $it->next, 1, 'an iterator, part way through more than a batch';

    # An iterator is part way through it, so prepare_cached would make a
    # new handle, unless told to give this one as it is.
    ref_is $dbh->prepare_cached($sql, undef, 2), $sth,
        'the handle, from the cache';
    weaken(my $gone = $it);
    undef $it;
    ok !$gone, 'which lets the iterator go';
    is scalar($sth->iterate(last => 250)->all), 250, 'all of them, after';
    $it = $sth->iterate(
        last => 250,
        sub ($row) { Stop() if $row->[0] > 3; $row->[0] },
    );
    is [$it->all], [1, 2, 3], 'or a few, with a stop';
    ok !$sth->{Active}, 'which finishes the statement';
};

subtest 'results' => sub {
    my $row = $dbh->results('SELECT 1 AS id, :name::text AS Name', name => 'x')
        ->single;
    is [$row->id, $row->name], [1, 'x'], 'a method for each column';
};

# Run code until it returns true, for up to five seconds.
sub eventually ($code) {
    for (1 .. 50) {
        return 1 if $code->();
        sleep 0.1;
    }
    return 0;
}

subtest 'Sugar connects again after the server drops the connection' => sub {
    database(server => $source, @attrs);
    statement(
        twice => server => 'SELECT $1::int * 2',
        sub ($row) { $row->[0] },
    );
    is [twice(21)], [42], 'a statement on it';

    my $first = server();
    my($pid) = $first->selectrow_array('SELECT pg_backend_pid()');
    $dbi->do('SELECT pg_terminate_backend(?)', undef, $pid);
    ok eventually(sub {
        !$dbi->selectrow_array(
            'SELECT COUNT(*) FROM pg_stat_activity WHERE pid = ?',
            undef, $pid,
        );
        }),
        'the server drops it';
    ok dies { server('SELECT 1') },
        'so the call after fails, as with plain DBI';
    ref_is_not server(), $first, 'and the call after that connects again';
    is [twice(4)], [8], 'for its statements too';
};

done_testing;
