use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use Ref::Util qw(is_blessed_ref);

use DBIx::Squirrel;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Rows;

my $class = 'DBIx::Squirrel::Pipeline';

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
my $dbh = DBIx::Squirrel->connect(@source);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_) for qw(Abba Blur Cream);
my $all = 'SELECT id, name FROM artist ORDER BY id';

subtest 'what is exported' => sub {

    package Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Rows;
        ::ok __PACKAGE__->can($_), "$_ by default" for qw(pluck as_hash);
    }

    package None {        ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Rows ();
        ::ok !__PACKAGE__->can($_), "not $_ with ()" for qw(pluck as_hash);
    }
};

subtest 'pluck, from arrays' => sub {
    is [$dbh->iterate($all, pluck(1))->all], [qw(Abba Blur Cream)],
        'by position';
    is [$dbh->iterate($all, pluck('name'))->all], [qw(Abba Blur Cream)],
        'by name';
    is [$dbh->iterate($all, pluck('NAME'))->all], [qw(Abba Blur Cream)],
        'in any case';
    is [$class->new(pluck(0))->([1, 2], [3, 4])], [1, 3],
        'by position, with no iterator';
};

subtest 'pluck, from hashes' => sub {
    my @slice = ({ekorn_slice => {}});
    is [$dbh->iterate($all, @slice, pluck('name'))->all], [qw(Abba Blur Cream)],
        'by name';
    is [$dbh->iterate($all, @slice, pluck('Name'))->all], [qw(Abba Blur Cream)],
        'in any case';
    is [$dbh->iterate($all, @slice, pluck(1))->all], [qw(Abba Blur Cream)],
        'by position';
    is [$class->new(pluck('a'))->({a => 1}, {a => 2})], [1, 2],
        'by name, with no iterator';
};

subtest 'pluck, from row objects' => sub {
    is [$dbh->results($all, pluck('name'))->all], [qw(Abba Blur Cream)],
        'by name';
    is [$dbh->results($all, pluck(1))->all], [qw(Abba Blur Cream)],
        'by position';
};

subtest 'pluck finds the column afresh on each run' => sub {
    my $name = pluck('name');
    is [$dbh->iterate('SELECT id, name FROM artist WHERE id = 1', $name)->all],
        ['Abba'], 'one statement';
    is [$dbh->iterate('SELECT name, id FROM artist WHERE id = 1', $name)->all],
        ['Abba'], 'and another, its columns in another order';
};

# The rows plain DBI's fetchrow_hashref gives for a statement.
sub fetched_hashes ($statement) {
    my $sth = $dbh->prepare($statement);
    $sth->execute;
    my @rows;
    while (my $row = DBI::st::fetchrow_hashref($sth)) { push @rows, $row }
    return \@rows;
}

subtest 'as_hash' => sub {
    my $one      = "$all LIMIT 1";
    my $expected = fetched_hashes($one);
    is $expected, [{id => 1, name => 'Abba'}], '(what the DBI gives)';
    is [$dbh->iterate($one, as_hash)->all], $expected,
        'from arrays, as fetchrow_hashref gives them';
    is [$dbh->iterate($one, {ekorn_slice => {}}, as_hash)->all], $expected,
        'hashes as they are';
    my($hash) = $dbh->results($one, as_hash)->all;
    is $hash, $expected->[0], 'from row objects';
    ok !is_blessed_ref($hash), 'as plain hashes';
    is [$dbh->iterate($all, as_hash)->all], fetched_hashes($all),
        'every row';

    local $dbh->{FetchHashKeyName} = 'NAME_uc';
    my $two = 'SELECT name FROM artist WHERE id = 2';
    is fetched_hashes($two), [{NAME => 'Blur'}], '(what the DBI gives)';
    is [$dbh->iterate($two, as_hash)->all], fetched_hashes($two),
        'keyed as FetchHashKeyName says';
};

subtest 'mistakes' => sub {
    for my $bad (undef, '') {
        my $line = __LINE__ + 1;
        is dies { pluck($bad) },
            "Expected a column, by name or position at ${\ __FILE__ } line $line.\n",
            'pluck without a column';
    }

    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->iterate($all, pluck('age'))->all };
    like $err,
        qr( \A Pipeline\ stage\ \#1\ failed\ at\ \Q${\ __FILE__ }\E\ line\ $line: )x,
        'a column the row has not, reported at the line that asked';
    like $err, qr( \n\ {4}Expected\ a\ column\ of\ the\ row\ \(age\)\ at\ )x,
        'saying which';
    like dies { $dbh->iterate($all, pluck(2))->all },
        qr( Expected\ a\ column\ of\ the\ row\ \(2\) )x, 'or a position';
    like dies { $dbh->iterate($all, pluck("\x{0661}"))->all },
        qr( Expected\ a\ column\ of\ the\ row\ \(\x{0661}\) )x,
        'a digit of another script being a name, not a position';
    my @slice = ({ekorn_slice => {}});
    like dies { $dbh->iterate($all, @slice, pluck('age'))->all },
        qr( Expected\ a\ column\ of\ the\ row\ \(age\) )x, 'or in a hash';
    like dies { $dbh->iterate($all, @slice, pluck(2))->all },
        qr( Expected\ a\ column\ of\ the\ row\ \(2\) )x, 'by position';
    like dies { $class->new(pluck('a'))->([1]) },
        qr( Expected\ an\ iterator,\ for\ the\ column\ names )x,
        'a name, for an array, with no iterator';
    like dies { $class->new(as_hash)->([1]) },
        qr( Expected\ an\ iterator,\ for\ the\ column\ names )x,
        'as_hash, with no iterator';
    like dies { $class->new(pluck(0))->('x') },
        qr( Expected\ a\ row:\ an\ array,\ a\ hash\ or\ a\ row\ object )x,
        'pluck, given something else';
    like dies { $class->new(as_hash)->(\'x') },
        qr( Expected\ a\ row:\ an\ array,\ a\ hash\ or\ a\ row\ object )x,
        'as_hash, given something else';
};

done_testing;
