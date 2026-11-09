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

# Against a real MySQL server, named by a data source in the environment,
# such as "dbi:mysql:mysql_read_default_file=...;mysql_read_default_group=...",
# which can carry the user and password. Skipped without one.
my $source = $ENV{DBIX_SQUIRREL_TEST_MYSQL}
    or skip_all 'set DBIX_SQUIRREL_TEST_MYSQL to a MySQL data source';
eval { require DBD::mysql; 1 }
    or skip_all 'DBD::mysql is not installed';

my @attrs = (undef, undef, {RaiseError => 1, PrintError => 0});
my $dbh   = DBIx::Squirrel->connect($source, @attrs);
my $dbi   = DBI->connect($source, @attrs);

# The row a statement returns, executed with the values given.
sub row ($statement, @values) {
    my $sth = $dbh->prepare($statement);
    $sth->execute(@values);
    return $sth->fetchrow_arrayref;
}

subtest "a statement is read by MySQL's rules" => sub {
    is row(q{SELECT 'it\'s :no', :x}, x => 'y'), [q{it's :no}, 'y'],
        'a backslash escapes a quote';
    is row(q{SELECT "a :no", :x}, x => 'y'), ['a :no', 'y'],
        '"..." is a string';
    is row("SELECT :x # :no\n", x => 'y'), ['y'], '# starts a comment';
};

subtest 'column names, after the last row is fetched' => sub {
    my $it = $dbh->iterate('SELECT 1 AS a, 2 AS b');
    is [$it->all],          [[1, 2]],  'every row fetched';
    is [$it->column_names], [qw(a b)], 'the names, which MySQL no longer gives';

    require DBIx::Squirrel::Stages::Rows;
    my $as_hash = DBIx::Squirrel::Stages::Rows::as_hash();
    is [$dbh->iterate('SELECT 1 AS a, 2 AS b', $as_hash)->all],
        [{a => 1, b => 2}], 'so as_hash has them';
};

subtest 'placeholders' => sub {
    is row('SELECT $1 + $1, $2', 2, 3), [4, 3], 'numbered, used twice';
    is row('SELECT :a, :b', b => 2, a => 1), [1, 2], 'named';
    is row('SELECT ?, ?',   [1, 2]),         [1, 2], 'an array reference of values';
};

subtest 'a list placeholder' => sub {
    is $dbh->selectcol_arrayref(
        q{SELECT 'it\'s ...:x' FROM DUAL WHERE 2 IN (...:ids) # ...:y},
        ids => [1, 2, 3],
        ),
        [q{it's ...:x}], 'read by MySQL rules';
};

subtest 'the same results as the DBI' => sub {
    my $sql = q{SELECT 'it\'s', ?, ? + 1};
    is [$dbh->selectrow_array($sql, undef, 1, 2)],
        [$dbi->selectrow_array($sql, undef, 1, 2)], 'selectrow_array';
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

subtest 'statements studied once' => sub {
    my $sql = q{SELECT 'it\'s :no', :x};
    my $one = $dbh->prepare($sql);
    my $two = $dbh->prepare($sql);
    is $two->{Statement},     q{SELECT 'it\'s :no', ?}, "by MySQL's rules";
    is $two->{private_ekorn}, $one->{private_ekorn},    'each handle the same';
    ref_is_not $two->{private_ekorn}, $one->{private_ekorn}, 'but its own';
};

subtest 'prepare_cached and iterators' => sub {
    my $sql
        = 'WITH RECURSIVE s (n) AS'
        . ' (SELECT 1 UNION ALL SELECT n + 1 FROM s WHERE n < :last)'
        . ' SELECT n FROM s';
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
    my $row
        = $dbh->results('SELECT 1 AS id, :name AS Name', name => 'x')->single;
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
    statement(twice => server => 'SELECT $1 * 2', sub ($row) { $row->[0] });
    is [twice(21)], [42], 'a statement on it';

    my $first = server();
    my($id) = $first->selectrow_array('SELECT CONNECTION_ID()');
    $dbi->do(sprintf 'KILL %d', $id);
    ok eventually(sub {
        !$dbi->selectrow_array(
            'SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID = ?',
            undef, $id,
        );
        }),
        'the server drops it';
    ok dies { server('SELECT 1') },
        'so the call after fails, as with plain DBI';
    ref_is_not server(), $first, 'and the call after that connects again';
    is [twice(4)], [8], 'for its statements too';
};

done_testing;
